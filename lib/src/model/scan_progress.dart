/// Tracks the progress of an active scanning session.
class VNPTScanProgress {
  /// The name of the current scanning phase.
  final String phaseName;

  /// The index of the current phase (0-based).
  final int phaseIndex;

  /// The total number of phases in the plan.
  final int totalPhases;

  /// The number of targets already probed in the session.
  final int probedTargets;

  /// The total number of targets to be probed in the session.
  final int totalTargets;

  /// The number of device candidates found so far.
  final int candidatesFound;

  /// Whether the scanning process has finished.
  final bool isComplete;

  /// Creates a [VNPTScanProgress] snapshot.
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
