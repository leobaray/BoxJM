import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/db_health.dart';
import '../../data/datasources/budget_remote_datasource.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/datasources/local_storage_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/sync_service.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/catalog_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPrefsProvider must be overridden in main.dart');
});

final localStorageProvider = Provider<LocalStorageDataSource>((ref) {
  return LocalStorageDataSource(ref.watch(sharedPrefsProvider));
});

final budgetRemoteProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSource(ref.watch(supabaseProvider));
});

final catalogRemoteProvider = Provider<CatalogRemoteDataSource>((ref) {
  return CatalogRemoteDataSource(ref.watch(supabaseProvider));
});

final dbHealthProvider = Provider<DbHealthChecker>((ref) {
  return DbHealthChecker(ref.watch(supabaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    ref.watch(budgetRemoteProvider),
    ref.watch(localStorageProvider),
    onRemoteSuccess: () =>
        ref.read(connectivityProvider.notifier).reportRemoteSuccess(),
    onRemoteFailure: () =>
        ref.read(connectivityProvider.notifier).reportRemoteFailure(),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    ref.watch(catalogRemoteProvider),
    ref.watch(localStorageProvider),
    onRemoteSuccess: () =>
        ref.read(connectivityProvider.notifier).reportRemoteSuccess(),
    onRemoteFailure: () =>
        ref.read(connectivityProvider.notifier).reportRemoteFailure(),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    local: ref.watch(localStorageProvider),
    budgetRemote: ref.watch(budgetRemoteProvider),
    catalogRemote: ref.watch(catalogRemoteProvider),
  );
});

// ── Network ───────────────────────────────────────────────────────────────
// O estado "online" do app reflete a alcançabilidade do Supabase, não a
// presença de interface de rede. connectivity_plus só participa como
// trigger rápido: quando a rede some, marcamos offline na hora; quando
// volta, disparamos um ping real. Além disso, polling periódico e sinais
// das operações dos repositórios mantêm o estado acurado.
class ConnectivityController extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  Timer? _pollTimer;
  Timer? _syncDebounce;
  Timer? _failureDebounce;
  bool _hasNetwork = true;
  bool _currentlyOnline = false;
  bool _hasFirstResult = false;
  bool _checking = false;

  static const _pollInterval = Duration(seconds: 25);
  static const _syncDebounceDelay = Duration(seconds: 3);
  static const _failureRecheckDelay = Duration(milliseconds: 400);

  @override
  Future<bool> build() async {
    ref.onDispose(() {
      _netSub?.cancel();
      _pollTimer?.cancel();
      _syncDebounce?.cancel();
      _failureDebounce?.cancel();
    });

    _netSub = Connectivity().onConnectivityChanged.listen(_onNetworkChanged);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _ping());

    final initialNet = await Connectivity().checkConnectivity();
    _hasNetwork = initialNet.any((r) => r != ConnectivityResult.none);
    if (!_hasNetwork) {
      _hasFirstResult = true;
      _currentlyOnline = false;
      return false;
    }
    final alive = await _runPing();
    _hasFirstResult = true;
    _currentlyOnline = alive;
    return alive;
  }

  void _onNetworkChanged(List<ConnectivityResult> results) {
    final hasNet = results.any((r) => r != ConnectivityResult.none);
    _hasNetwork = hasNet;
    if (!hasNet) {
      _setOnline(false);
    } else {
      _ping();
    }
  }

  Future<void> _ping() async {
    if (_checking) return;
    if (!_hasNetwork) {
      _setOnline(false);
      return;
    }
    _checking = true;
    try {
      final alive = await _runPing();
      _setOnline(alive);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _runPing() {
    return ref.read(dbHealthProvider).ping();
  }

  void _setOnline(bool now) {
    final wasOffline = !_currentlyOnline;
    _currentlyOnline = now;
    state = AsyncData(now);
    if (now && wasOffline && _hasFirstResult) {
      _syncDebounce?.cancel();
      _syncDebounce = Timer(_syncDebounceDelay, () {
        ref.read(syncServiceProvider).syncAll().then((_) {
          ref.invalidate(budgetListProvider);
          ref.invalidate(catalogListProvider);
        });
      });
    }
    _hasFirstResult = true;
  }

  /// Chamado por repositórios quando uma operação remota foi bem-sucedida
  /// — evidência direta de que o BD está alcançável.
  void reportRemoteSuccess() {
    if (!_currentlyOnline) {
      _setOnline(true);
    }
  }

  /// Chamado quando uma operação remota falhou. Não marcamos offline no ato
  /// (pode ser erro pontual), mas disparamos um recheck rápido para
  /// confirmar. Se o recheck também falhar, aí sim cai para offline.
  void reportRemoteFailure() {
    _failureDebounce?.cancel();
    _failureDebounce = Timer(_failureRecheckDelay, _ping);
  }

  /// Força uma verificação imediata (usável por UI, ex: pull-to-refresh).
  Future<void> recheck() => _ping();
}

final connectivityProvider =
    AsyncNotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);

// ── Budgets ───────────────────────────────────────────────────────────────
class BudgetListController extends AsyncNotifier<List<Budget>> {
  bool _mutating = false;

  @override
  Future<List<Budget>> build() async {
    // 1. show cache instantly
    final cached = ref.read(localStorageProvider).getBudgets();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }
    // 2. fetch fresh
    return ref.read(budgetRepositoryProvider).getAll();
  }

  Future<Budget> create(Budget budget) async {
    while (_mutating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _mutating = true;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      final saved = await repo.create(budget);
      state = AsyncData(ref.read(localStorageProvider).getBudgets());
      return saved;
    } finally {
      _mutating = false;
    }
  }

  Future<Budget> editBudget(String id, BudgetUpdate updates) async {
    while (_mutating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _mutating = true;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      final saved = await repo.update(id, updates);
      state = AsyncData(ref.read(localStorageProvider).getBudgets());
      return saved;
    } finally {
      _mutating = false;
    }
  }

  Future<void> delete(String id) async {
    while (_mutating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _mutating = true;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.delete(id);
      state = AsyncData(ref.read(localStorageProvider).getBudgets());
    } finally {
      _mutating = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final list = await ref.read(budgetRepositoryProvider).getAll();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final budgetListProvider =
    AsyncNotifierProvider<BudgetListController, List<Budget>>(
  BudgetListController.new,
);

// ── Catalog ───────────────────────────────────────────────────────────────
class CatalogListController extends AsyncNotifier<List<ServiceItem>> {
  @override
  Future<List<ServiceItem>> build() async {
    final cached = ref.read(localStorageProvider).getServices();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }
    return ref.read(catalogRepositoryProvider).getAll();
  }

  Future<void> save(ServiceItem service) async {
    await ref.read(catalogRepositoryProvider).save(service);
    state = AsyncData(await ref.read(catalogRepositoryProvider).getAll());
  }

  Future<void> delete(String id) async {
    await ref.read(catalogRepositoryProvider).delete(id);
    state = AsyncData(await ref.read(catalogRepositoryProvider).getAll());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final list = await ref.read(catalogRepositoryProvider).getAll();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final catalogListProvider =
    AsyncNotifierProvider<CatalogListController, List<ServiceItem>>(
  CatalogListController.new,
);
