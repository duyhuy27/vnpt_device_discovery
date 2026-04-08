import 'discovered_device.dart';
import 'discovery_failure_reason.dart';
import 'discovery_result.dart';
import 'scan_plan.dart';

sealed class VNPTDiscoveryEvent {
  const VNPTDiscoveryEvent();
}

class VNPTDiscoveryStarted extends VNPTDiscoveryEvent {
  final VNPTScanPlan plan;

  const VNPTDiscoveryStarted(this.plan);
}

class VNPTCandidateFound extends VNPTDiscoveryEvent {
  final VNPTDiscoveredDevice device;

  const VNPTCandidateFound(this.device);
}

class VNPTCandidateListUpdated extends VNPTDiscoveryEvent {
  final List<VNPTDiscoveredDevice> devices;

  const VNPTCandidateListUpdated(this.devices);
}

class VNPTDiscoveryCompleted extends VNPTDiscoveryEvent {
  final VNPTDiscoveryResult result;

  const VNPTDiscoveryCompleted(this.result);
}

class VNPTDiscoveryFailed extends VNPTDiscoveryEvent {
  final VNPTDiscoveryFailureReason reason;
  final Object? cause;
  final StackTrace stackTrace;

  const VNPTDiscoveryFailed(this.reason, this.stackTrace, {this.cause});
}
