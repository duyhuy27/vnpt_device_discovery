import '../model/discovery_request.dart';
import '../model/scan_plan.dart';

/// Interface for building a scanning plan based on a discovery request.
abstract class VNPTScanPlanner {
  /// Builds a [VNPTScanPlan] based on the provided [request].
  VNPTScanPlan buildPlan(VNPTDiscoveryRequest request);
}
