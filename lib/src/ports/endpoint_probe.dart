/// The result of a single endpoint probe attempt.
class VNPTEndpointProbeResult {
  /// The IP address that was probed.
  final String ip;

  /// The port that was probed.
  final int port;

  /// Whether the port was successfully opened.
  final bool isOpen;

  /// The response time in milliseconds, if the port was open.
  final int? responseTimeMs;

  /// Creates a [VNPTEndpointProbeResult] with the provided details.
  const VNPTEndpointProbeResult({
    required this.ip,
    required this.port,
    required this.isOpen,
    this.responseTimeMs,
  });
}

/// Interface for probing a network endpoint (IP and port).
abstract class VNPTEndpointProbe {
  /// Probes the given [ip] and [port] with a specific [timeout].
  Future<VNPTEndpointProbeResult> probe(String ip, int port, Duration timeout);
}
