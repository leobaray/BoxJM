import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_shadows.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';
import 'presentation/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const BoxJmApp(),
    ),
  );
}

class BoxJmApp extends ConsumerWidget {
  const BoxJmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'BOX JM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      scaffoldMessengerKey: _rootMessengerKey,
      builder: (context, child) {
        return _RootBackHandler(router: router, child: child ?? const SizedBox.shrink());
      },
    );
  }
}

final GlobalKey<ScaffoldMessengerState> _rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class _RootBackHandler extends StatefulWidget {
  const _RootBackHandler({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<_RootBackHandler> createState() => _RootBackHandlerState();
}

class _RootBackHandlerState extends State<_RootBackHandler>
    with WidgetsBindingObserver {
  DateTime? _lastBackPress;
  static const _exitWindow = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (widget.router.canPop()) {
      widget.router.pop();
      return true;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > _exitWindow) {
      _lastBackPress = now;
      HapticFeedback.lightImpact();
      final messenger = _rootMessengerKey.currentState;
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        const SnackBar(
          content: _ExitToast(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          duration: _exitWindow,
          margin: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.navReserved - 8,
          ),
        ),
      );
      return true;
    }
    HapticFeedback.mediumImpact();
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ExitToast extends StatelessWidget {
  const _ExitToast();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C26), Color(0xFF14141C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.chromeEdgeStrong, width: 1),
        boxShadow: AppShadows.lg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.halo(AppColors.ignition, alpha: 0.35),
            ),
            child: const Center(
              child: Icon(
                Icons.logout_rounded,
                size: 15,
                color: AppColors.ignition,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Toque novamente para sair',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
