import 'package:flutter/foundation.dart';

/// Logger central do app. Em debug, imprime no console com tag + contexto.
/// Em release, vira no-op — trocar por Sentry/Crashlytics se/quando precisar.
///
/// Motivo: antes todos os erros eram engolidos em `catch (_)`. Sem logging
/// fica impossível diagnosticar qualquer coisa em produção ou em dispositivo
/// do cliente.
class AppLogger {
  AppLogger(this.tag);

  final String tag;

  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] $message');
    }
  }

  void warn(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint(
          '[WARN][$tag] $message${error != null ? ' — $error' : ''}');
    }
  }

  void error(String message, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $message — $error');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
  }
}
