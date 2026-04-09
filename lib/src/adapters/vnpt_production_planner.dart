import '../model/discovery_request.dart';
import '../model/scan_plan.dart';
import '../ports/scan_planner.dart';

/// Production-ready implementation of [VNPTScanPlanner].
///
/// This planner uses a multi-phase strategy to find VNPT devices:
/// 1. **Targeted**: Probes suffixes known to be common (132, 133, 134).
/// 2. **Nearby Expanded**: Probes suffixes around the local network host and some defaults.
/// 3. **Generic Fallback**: Probes the remaining addresses in the 1-254 range.
class VNPTProductionPlanner implements VNPTScanPlanner {
  /// The fixed port used for VNPT device discovery.
  static const int fixedPort = 40029;

  /// Creates a [VNPTProductionPlanner].
  const VNPTProductionPlanner();

  @override
  VNPTScanPlan buildPlan(VNPTDiscoveryRequest request) {
    final targeted = _sanitizeSuffixes(const [133, 132, 134]);
    final nearbyExpanded = _sanitizeSuffixes([
      133,
      132,
      134,
      request.network.localHostSuffix,
      request.network.localHostSuffix - 1,
      request.network.localHostSuffix + 1,
      100,
      101,
      102,
    ], excluded: targeted.toSet());
    final genericFallback = _buildGenericFallback(
      excluded: {...targeted, ...nearbyExpanded},
    );

    final phases = <VNPTScanPhase>[
      VNPTScanPhase(kind: VNPTScanPhaseKind.targeted, hostSuffixes: targeted),
      VNPTScanPhase(
        kind: VNPTScanPhaseKind.nearbyExpanded,
        hostSuffixes: nearbyExpanded,
      ),
      VNPTScanPhase(
        kind: VNPTScanPhaseKind.genericFallback,
        hostSuffixes: genericFallback,
      ),
    ];

    final totalTargets = phases.fold<int>(
      0,
      (sum, phase) => sum + phase.targetCount,
    );

    return VNPTScanPlan(
      phases: phases,
      port: fixedPort,
      portTimeout:
          request.portTimeoutOverride ?? _defaultPortTimeout(request.profile),
      concurrency:
          request.concurrencyOverride ?? _defaultConcurrency(request.profile),
      totalTargets: totalTargets,
    );
  }

  Duration _defaultPortTimeout(VNPTScanProfile profile) {
    return switch (profile) {
      VNPTScanProfile.production => const Duration(milliseconds: 500),
      VNPTScanProfile.test => const Duration(milliseconds: 75),
      VNPTScanProfile.diagnostic => const Duration(milliseconds: 1200),
    };
  }

  int _defaultConcurrency(VNPTScanProfile profile) {
    return switch (profile) {
      VNPTScanProfile.production => 12,
      VNPTScanProfile.test => 2,
      VNPTScanProfile.diagnostic => 4,
    };
  }

  List<int> _buildGenericFallback({required Set<int> excluded}) {
    return [
      for (var suffix = 1; suffix <= 254; suffix++)
        if (!excluded.contains(suffix)) suffix,
    ];
  }

  List<int> _sanitizeSuffixes(
    List<int> rawSuffixes, {
    Set<int> excluded = const <int>{},
  }) {
    final seen = <int>{...excluded};
    final result = <int>[];
    for (final suffix in rawSuffixes) {
      if (suffix >= 1 && suffix <= 254 && seen.add(suffix)) {
        result.add(suffix);
      }
    }
    return result;
  }
}
