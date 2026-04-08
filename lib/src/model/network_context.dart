class VNPTNetworkContext {
  final String localIp;
  final String subnet;
  final String subnetMask;

  const VNPTNetworkContext({
    required this.localIp,
    required this.subnet,
    required this.subnetMask,
  });

  int get localHostSuffix =>
      int.tryParse(localIp.split('.').last.trim()) ?? 100;
}
