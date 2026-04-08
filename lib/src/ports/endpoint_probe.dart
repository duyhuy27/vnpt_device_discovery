class VNPTEndpointProbeResult {
  final String ip;
  final int port;
  final bool isOpen;
  final int? responseTimeMs;

  const VNPTEndpointProbeResult({
    required this.ip,
    required this.port,
    required this.isOpen,
    this.responseTimeMs,
  });
}

abstract class VNPTEndpointProbe {
  Future<VNPTEndpointProbeResult> probe(String ip, int port, Duration timeout);
}
