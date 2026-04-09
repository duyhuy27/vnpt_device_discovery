/// Defines the different types of scanning phases.
enum VNPTScanPhaseKind {
  /// Probes specific, high-probability host suffixes.
  targeted,

  /// Probes host suffixes near the local host IP.
  nearbyExpanded,

  /// Probes all potential host suffixes (1-254) in the subnet.
  genericFallback,
}

/// Represents a specific phase of the scanning process.
class VNPTScanPhase {
  /// The type of this scanning phase.
  final VNPTScanPhaseKind kind;

  /// The list of host suffixes (last octet of IP) to probe in this phase.
  final List<int> hostSuffixes;

  /// Creates a [VNPTScanPhase] with the given [kind] and [hostSuffixes].
  const VNPTScanPhase({required this.kind, required this.hostSuffixes});

  /// The human-readable name of the phase.
  String get name => switch (kind) {
        VNPTScanPhaseKind.targeted => 'targeted',
        VNPTScanPhaseKind.nearbyExpanded => 'nearbyExpanded',
        VNPTScanPhaseKind.genericFallback => 'genericFallback',
      };

  /// The number of targets in this phase.
  int get targetCount => hostSuffixes.length;
}

/// The complete execution plan for a discovery session.
class VNPTScanPlan {
  /// The collection of phases to be executed sequentially.
  final List<VNPTScanPhase> phases;

  /// The port being probed (typically 40029).
  final int port;

  /// The timeout for each individual port probe.
  final Duration portTimeout;

  /// The maximum number of concurrent probes.
  final int concurrency;

  /// The total number of unique targets across all phases.
  final int totalTargets;

  /// Creates a [VNPTScanPlan] with the provided parameters.
  const VNPTScanPlan({
    required this.phases,
    required this.port,
    required this.portTimeout,
    required this.concurrency,
    required this.totalTargets,
  });
}
