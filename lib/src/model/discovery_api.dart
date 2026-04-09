import 'discovery_event.dart';
import 'discovery_request.dart';
import 'scan_progress.dart';

/// Interface for VNPT device discovery service.
abstract class VNPTDiscovery {
  /// Creates a new discovery session with the given [request].
  VNPTDiscoverySession createSession({required VNPTDiscoveryRequest request});
}

/// Represents an active discovery session.
abstract class VNPTDiscoverySession {
  /// A stream of [VNPTDiscoveryEvent]s occurring during the session.
  Stream<VNPTDiscoveryEvent> get events;

  /// A stream of [VNPTScanProgress] updates.
  Stream<VNPTScanProgress> get progress;

  /// Cancels the scan and guarantees that completion is emitted after at most
  /// one configured `portTimeout`, once the last in-flight probe finishes.
  Future<void> cancel();
}
