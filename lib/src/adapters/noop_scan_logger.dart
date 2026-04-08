import '../ports/scan_logger.dart';

class NoopScanLogger implements VNPTScanLogger {
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
