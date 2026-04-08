enum VNPTScanPhaseKind { targeted, nearbyExpanded, genericFallback }

class VNPTScanPhase {
  final VNPTScanPhaseKind kind;
  final List<int> hostSuffixes;

  const VNPTScanPhase({required this.kind, required this.hostSuffixes});

  String get name => switch (kind) {
    VNPTScanPhaseKind.targeted => 'targeted',
    VNPTScanPhaseKind.nearbyExpanded => 'nearbyExpanded',
    VNPTScanPhaseKind.genericFallback => 'genericFallback',
  };

  int get targetCount => hostSuffixes.length;
}

class VNPTScanPlan {
  final List<VNPTScanPhase> phases;
  final int port;
  final Duration portTimeout;
  final int concurrency;
  final int totalTargets;

  const VNPTScanPlan({
    required this.phases,
    required this.port,
    required this.portTimeout,
    required this.concurrency,
    required this.totalTargets,
  });
}
