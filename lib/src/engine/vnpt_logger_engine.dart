import 'dart:developer' as developer;

/// Signature for custom logging functions.
///
/// Implement this to integrate with external logging systems (Firebase, Sentry, etc).
typedef LoggerFunction = void Function(String message, {String? name});

class LoggerEngine {
  static final LoggerEngine _instance = LoggerEngine._private();
  late LoggerFunction _logFunction;

  LoggerEngine._private() {
    // Default: use Dart's developer.log
    _logFunction = (String message, {String? name}) {
      developer.log(message, name: name ?? 'vnpt_logger');
    };
  }

  /// Gets the singleton instance of the logger.
  static LoggerEngine get instance => _instance;

  /// Initializes the logger with a custom logging function.
  static void initialize(LoggerFunction logFunction) {
    _instance._logFunction = logFunction;
  }

  /// Logs a message using the configured logging function.
  ///
  /// - [message]: The message to log
  /// - [name]: Optional category name (e.g., 'Discovery', 'OnvifClient')
  void log(String message, {String? name}) {
    _logFunction(message, name: name);
  }
}
