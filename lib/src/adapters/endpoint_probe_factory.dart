import '../ports/endpoint_probe.dart';
import 'endpoint_probe_io.dart'
    if (dart.library.html) 'endpoint_probe_web.dart'
    if (dart.library.js_util) 'endpoint_probe_web.dart';

/// Creates the default [VNPTEndpointProbe] for the current platform.
VNPTEndpointProbe createDefaultProbe() => getProbe();
