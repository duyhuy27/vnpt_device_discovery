import 'discovered_device.dart';
import 'discovery_failure_reason.dart';
import 'discovery_result.dart';
import 'scan_plan.dart';

/// Base class for all discovery events.
sealed class VNPTDiscoveryEvent {
  const VNPTDiscoveryEvent();
}

/// Event emitted when a discovery session starts.
class VNPTDiscoveryStarted extends VNPTDiscoveryEvent {
  /// The scanning plan for this session.
  final VNPTScanPlan plan;

  const VNPTDiscoveryStarted(this.plan);
}

/// Event emitted when a single potential candidate is found.
class VNPTCandidateFound extends VNPTDiscoveryEvent {
  /// The discovered device candidate.
  final VNPTDiscoveredDevice device;

  const VNPTCandidateFound(this.device);
}

/// Event emitted when the list of candidates is updated (e.g., at phase end).
class VNPTCandidateListUpdated extends VNPTDiscoveryEvent {
  /// The current list of all discovered devices in this session.
  final List<VNPTDiscoveredDevice> devices;

  const VNPTCandidateListUpdated(this.devices);
}

/// Event emitted when a discovery session completes successfully or is cancelled.
class VNPTDiscoveryCompleted extends VNPTDiscoveryEvent {
  /// The result of the discovery session.
  final VNPTDiscoveryResult result;

  const VNPTDiscoveryCompleted(this.result);
}

/// Event emitted when a discovery session fails due to an error.
class VNPTDiscoveryFailed extends VNPTDiscoveryEvent {
  /// The high-level reason for the failure.
  final VNPTDiscoveryFailureReason reason;

  /// The underlying technical cause of the failure, if any.
  final Object? cause;

  /// The stack trace associated with the failure.
  final StackTrace stackTrace;

  const VNPTDiscoveryFailed(this.reason, this.stackTrace, {this.cause});
}
