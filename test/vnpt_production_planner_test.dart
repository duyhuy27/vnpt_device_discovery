import 'package:flutter_test/flutter_test.dart';
import 'package:vnpt_device_discovery/vnpt_device_discovery.dart';

void main() {
  const planner = VNPTProductionPlanner();

  test('targeted phase is exactly [133, 132, 134] after sanitize', () {
    final plan = planner.buildPlan(
      VNPTDiscoveryRequest.production(
        const VNPTNetworkContext(
          localIp: '192.168.88.140',
          subnet: '192.168.88',
          subnetMask: '255.255.255.0',
        ),
      ),
    );

    expect(plan.phases, hasLength(3));
    expect(plan.phases[0].kind, VNPTScanPhaseKind.targeted);
    expect(plan.phases[0].hostSuffixes, const [133, 132, 134]);
  });

  test('nearbyExpanded subtracts all suffixes already present in targeted', () {
    final plan = planner.buildPlan(
      VNPTDiscoveryRequest.production(
        const VNPTNetworkContext(
          localIp: '192.168.88.140',
          subnet: '192.168.88',
          subnetMask: '255.255.255.0',
        ),
      ),
    );

    expect(plan.phases[1].kind, VNPTScanPhaseKind.nearbyExpanded);
    expect(plan.phases[1].hostSuffixes, const [140, 139, 141, 100, 101, 102]);
  });

  test('genericFallback is 1..254 minus all earlier phases', () {
    final plan = planner.buildPlan(
      VNPTDiscoveryRequest.production(
        const VNPTNetworkContext(
          localIp: '192.168.88.140',
          subnet: '192.168.88',
          subnetMask: '255.255.255.0',
        ),
      ),
    );

    final excluded = {
      ...plan.phases[0].hostSuffixes,
      ...plan.phases[1].hostSuffixes,
    };
    final expected = <int>[
      for (var suffix = 1; suffix <= 254; suffix++)
        if (!excluded.contains(suffix)) suffix,
    ];

    expect(plan.phases[2].kind, VNPTScanPhaseKind.genericFallback);
    expect(plan.phases[2].hostSuffixes, expected);
  });

  test('fixed port is always 40029 and totalTargets is computed once', () {
    final plan = planner.buildPlan(
      VNPTDiscoveryRequest.diagnostic(
        const VNPTNetworkContext(
          localIp: '192.168.88.140',
          subnet: '192.168.88',
          subnetMask: '255.255.255.0',
        ),
        portTimeout: const Duration(milliseconds: 900),
        concurrency: 3,
      ),
    );

    expect(plan.port, 40029);
    expect(plan.portTimeout, const Duration(milliseconds: 900));
    expect(plan.concurrency, 3);
    expect(plan.totalTargets, 254);
  });

  test('localIp .133 nearbyExpanded subtracts 133, 132, and 134 exactly', () {
    final plan = planner.buildPlan(
      VNPTDiscoveryRequest.production(
        const VNPTNetworkContext(
          localIp: '192.168.88.133',
          subnet: '192.168.88',
          subnetMask: '255.255.255.0',
        ),
      ),
    );

    expect(plan.phases[1].hostSuffixes, const [100, 101, 102]);
  });
}
