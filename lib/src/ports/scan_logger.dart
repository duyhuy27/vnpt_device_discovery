/// Interface for logging discovery events and internal diagnostics.
abstract class VNPTScanLogger {
  /// Logs an informational message.
  void info(String message);

  /// Logs a warning message.
  void warning(String message);

  /// Logs an error message with optional [error] and [stackTrace].
  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// Logs a debug-level message.
  void debug(String message);
}
