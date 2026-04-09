import 'dart:async';
import '../ports/endpoint_probe.dart';

/// Web-specific implementation of [VNPTEndpointProbe].
///
/// Raw TCP sockets are not supported in web browsers.
class WebEndpointProbe implements VNPTEndpointProbe {
  /// Creates a [WebEndpointProbe].
  const WebEndpointProbe();

  @override
  Future<VNPTEndpointProbeResult> probe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    // Sockets are not supported on Web.
    return VNPTEndpointProbeResult(
      ip: ip,
      port: port,
      isOpen: false,
      responseTimeMs: null,
    );
  }
}

/// Factory for Web platforms.
VNPTEndpointProbe getProbe() => const WebEndpointProbe();
