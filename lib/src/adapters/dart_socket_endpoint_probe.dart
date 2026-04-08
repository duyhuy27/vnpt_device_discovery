import 'dart:async';
import 'dart:io';

import '../ports/endpoint_probe.dart';

class DartSocketEndpointProbe implements VNPTEndpointProbe {
  const DartSocketEndpointProbe();

  @override
  Future<VNPTEndpointProbeResult> probe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    Socket? socket;
    final stopwatch = Stopwatch()..start();

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      stopwatch.stop();
      return VNPTEndpointProbeResult(
        ip: ip,
        port: port,
        isOpen: true,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException {
      stopwatch.stop();
      return VNPTEndpointProbeResult(
        ip: ip,
        port: port,
        isOpen: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException {
      stopwatch.stop();
      return VNPTEndpointProbeResult(
        ip: ip,
        port: port,
        isOpen: false,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      socket?.destroy();
    }
  }
}
