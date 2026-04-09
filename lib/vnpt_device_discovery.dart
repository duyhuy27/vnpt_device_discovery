/// A specialized Flutter package for targeted VNPT device discovery.
///
/// This package provides a controlled scanning mechanism to find VNPT devices
/// (typically AIBox or similar) on a local network by probing specific ports
/// and using a phase-based search strategy.
library vnpt_device_discovery;

export 'src/model/discovered_device.dart';
export 'src/model/discovery_api.dart';
export 'src/model/discovery_event.dart';
export 'src/model/discovery_failure_reason.dart';
export 'src/model/discovery_request.dart';
export 'src/model/discovery_result.dart';
export 'src/model/network_context.dart';
export 'src/model/scan_plan.dart';
export 'src/model/scan_progress.dart';

export 'src/ports/endpoint_probe.dart';
export 'src/ports/scan_logger.dart';
export 'src/ports/scan_planner.dart';

export 'src/engine/vnpt_discovery_engine.dart';

export 'src/adapters/dart_socket_endpoint_probe.dart';
export 'src/adapters/noop_scan_logger.dart';
export 'src/adapters/vnpt_production_planner.dart';
