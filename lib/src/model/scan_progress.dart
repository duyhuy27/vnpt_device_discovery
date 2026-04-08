class VNPTScanProgress {
  final String phaseName;
  final int phaseIndex;
  final int totalPhases;
  final int probedTargets;
  final int totalTargets;
  final int candidatesFound;
  final bool isComplete;

  const VNPTScanProgress({
    required this.phaseName,
    required this.phaseIndex,
    required this.totalPhases,
    required this.probedTargets,
    required this.totalTargets,
    required this.candidatesFound,
    required this.isComplete,
  });
}
