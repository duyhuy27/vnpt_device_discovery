import '../model/discovery_request.dart';
import '../model/scan_plan.dart';

abstract class VNPTScanPlanner {
  VNPTScanPlan buildPlan(VNPTDiscoveryRequest request);
}
