import '../ports/scan_logger.dart';

/// A [VNPTScanLogger] implementation that discards all log messages.
class NoopScanLogger implements VNPTScanLogger {
  /// Creates a [NoopScanLogger].
  const NoopScanLogger();

  @override
  void debug(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}
}
