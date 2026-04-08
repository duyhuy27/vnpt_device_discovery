import 'discovered_device.dart';

class VNPTDiscoveryResult {
  final List<VNPTDiscoveredDevice> devices;
  final bool cancelled;
  final DateTime startedAt;
  final DateTime endedAt;

  const VNPTDiscoveryResult({
    required this.devices,
    required this.cancelled,
    required this.startedAt,
    required this.endedAt,
  });

  List<VNPTDiscoveredDevice> get candidates => devices;
}
