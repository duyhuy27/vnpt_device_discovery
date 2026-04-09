import 'discovered_device.dart';

/// The final outcome of a discovery session.
class VNPTDiscoveryResult {
  /// The list of devices found during the session.
  final List<VNPTDiscoveredDevice> devices;

  /// Whether the session was explicitly cancelled by the user.
  final bool cancelled;

  /// The timestamp when the session started.
  final DateTime startedAt;

  /// The timestamp when the session ended.
  final DateTime endedAt;

  /// Creates a [VNPTDiscoveryResult] with the given data.
  const VNPTDiscoveryResult({
    required this.devices,
    required this.cancelled,
    required this.startedAt,
    required this.endedAt,
  });

  List<VNPTDiscoveredDevice> get candidates => devices;
}
