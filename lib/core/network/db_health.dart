import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// Verifica se o Supabase está de fato alcançável.
///
/// O `connectivity_plus` só diz se existe interface de rede (WiFi / dados
/// móveis). Isso não cobre captive portal, roteador sem internet, DNS
/// bloqueado, Supabase fora do ar, credenciais inválidas, etc. — tudo que
/// para o app é indistinguível de "offline". Este checker faz uma query
/// mínima de verdade, com timeout curto.
class DbHealthChecker {
  DbHealthChecker(this._client);

  final SupabaseClient _client;
  final _log = AppLogger('DbHealth');

  /// Tabela leve usada para o ping. É consultada com `limit(1)` — custo
  /// desprezível comparado a uma operação real do app.
  static const _pingTable = 'services';

  Future<bool> ping({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await _client
          .from(_pingTable)
          .select('id')
          .limit(1)
          .timeout(timeout);
      return true;
    } catch (e) {
      _log.info('ping falhou: $e');
      return false;
    }
  }
}
