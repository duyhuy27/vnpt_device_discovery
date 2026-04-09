/// Represents the local network configuration for the discovery process.
class VNPTNetworkContext {
  /// The local IP address of the host device (e.g., '192.168.1.5').
  final String localIp;

  /// The subnet prefix (e.g., '192.168.1').
  final String subnet;

  /// The subnet mask (e.g., '255.255.255.0').
  final String subnetMask;

  /// Creates a [VNPTNetworkContext] with the provided network details.
  const VNPTNetworkContext({
    required this.localIp,
    required this.subnet,
    required this.subnetMask,
  });

  int get localHostSuffix =>
      int.tryParse(localIp.split('.').last.trim()) ?? 100;
}
