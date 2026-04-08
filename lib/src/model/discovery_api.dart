import 'discovery_event.dart';
import 'discovery_request.dart';
import 'scan_progress.dart';

abstract class VNPTDiscovery {
  VNPTDiscoverySession createSession({required VNPTDiscoveryRequest request});
}

abstract class VNPTDiscoverySession {
  Stream<VNPTDiscoveryEvent> get events;
  Stream<VNPTScanProgress> get progress;

  /// Cancels the scan and guarantees that completion is emitted after at most
  /// one configured `portTimeout`, once the last in-flight probe finishes.
  Future<void> cancel();
}
