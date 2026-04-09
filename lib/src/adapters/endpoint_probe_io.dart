import '../ports/endpoint_probe.dart';
import 'dart_socket_endpoint_probe.dart';

/// Factory for native platforms.
VNPTEndpointProbe getProbe() => const DartSocketEndpointProbe();
