import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../adapters/dart_socket_endpoint_probe.dart';
import '../adapters/noop_scan_logger.dart';
import '../adapters/vnpt_production_planner.dart';
import '../model/discovered_device.dart';
import '../model/discovery_api.dart';
import '../model/discovery_event.dart';
import '../model/discovery_failure_reason.dart';
import '../model/discovery_request.dart';
import '../model/discovery_result.dart';
import '../model/scan_plan.dart';
import '../model/scan_progress.dart';
import '../ports/endpoint_probe.dart';
import '../ports/scan_logger.dart';
import '../ports/scan_planner.dart';

class VNPTDiscoveryEngine implements VNPTDiscovery {
  final VNPTScanPlanner planner;
  final VNPTEndpointProbe endpointProbe;
  final VNPTScanLogger logger;

  const VNPTDiscoveryEngine({
    required this.planner,
    required this.endpointProbe,
    this.logger = const NoopScanLogger(),
  });

  factory VNPTDiscoveryEngine.standard() {
    return const VNPTDiscoveryEngine(
      planner: VNPTProductionPlanner(),
      endpointProbe: DartSocketEndpointProbe(),
      logger: NoopScanLogger(),
    );
  }

  @override
  VNPTDiscoverySession createSession({required VNPTDiscoveryRequest request}) {
    return _DefaultVNPTDiscoverySession(
      request: request,
      planner: planner,
      endpointProbe: endpointProbe,
      logger: logger,
    );
  }
}

class _DefaultVNPTDiscoverySession implements VNPTDiscoverySession {
  final VNPTDiscoveryRequest request;
  final VNPTScanPlanner planner;
  final VNPTEndpointProbe endpointProbe;
  final VNPTScanLogger logger;

  final StreamController<VNPTDiscoveryEvent> _eventsController =
      StreamController<VNPTDiscoveryEvent>.broadcast();
  final StreamController<VNPTScanProgress> _progressController =
      StreamController<VNPTScanProgress>.broadcast();
  final Map<String, VNPTDiscoveredDevice> _candidates =
      <String, VNPTDiscoveredDevice>{};

  late final DateTime _startedAt;
  late final Future<void> _runFuture;
  VNPTScanPlan? _plan;
  bool _cancelRequested = false;
  bool _isFinalized = false;
  bool _snapshotPending = false;
  int _probedTargets = 0;
  String _currentPhaseName = 'initializing';
  int _currentPhaseIndex = 0;
  int _lastEmittedTargets = -1;
  int _lastEmittedCandidates = -1;
  int _lastEmittedPhaseIndex = -1;
  String? _lastEmittedPhaseName;
  DateTime? _lastProgressEmitAt;

  _DefaultVNPTDiscoverySession({
    required this.request,
    required this.planner,
    required this.endpointProbe,
    required this.logger,
  }) {
    _runFuture = Future<void>.microtask(_run);
  }

  @override
  Stream<VNPTDiscoveryEvent> get events => _eventsController.stream;

  @override
  Stream<VNPTScanProgress> get progress => _progressController.stream;

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    await _runFuture;
  }

  Future<void> _run() async {
    _startedAt = DateTime.now();
    try {
      _validateRequest();
      final plan = planner.buildPlan(request);
      _validatePlan(plan);
      _plan = plan;
      _eventsController.add(VNPTDiscoveryStarted(plan));
      _emitProgress(force: true);

      for (var index = 0; index < plan.phases.length; index++) {
        if (_cancelRequested) {
          break;
        }

        final phase = plan.phases[index];
        _currentPhaseIndex = index + 1;
        _currentPhaseName = phase.name;
        _emitProgress(force: true);

        final phaseFoundCandidate = await _runPhase(phase);
        if (phaseFoundCandidate) {
          _emitCandidateListUpdated();
          break;
        }
      }

      if (_snapshotPending) {
        _emitCandidateListUpdated();
      }

      await _complete(cancelled: _cancelRequested);
    } catch (error, stackTrace) {
      await _fail(error, stackTrace);
    }
  }

  void _validateRequest() {
    if (request.network.localIp.trim().isEmpty) {
      throw ArgumentError.value(
        request.network.localIp,
        'localIp',
        'localIp is required',
      );
    }
    if (request.network.subnet.trim().isEmpty) {
      throw ArgumentError.value(
        request.network.subnet,
        'subnet',
        'subnet is required',
      );
    }
    if (request.network.subnetMask.trim().isEmpty) {
      throw ArgumentError.value(
        request.network.subnetMask,
        'subnetMask',
        'subnetMask is required',
      );
    }
  }

  void _validatePlan(VNPTScanPlan plan) {
    if (plan.phases.isEmpty) {
      throw StateError('Scan plan must include at least one phase.');
    }
    if (plan.port < 1 || plan.port > 65535) {
      throw StateError('Scan plan port must be between 1 and 65535.');
    }
    if (plan.totalTargets <= 0) {
      throw StateError('Scan plan must include at least one target.');
    }
    if (plan.concurrency <= 0) {
      throw StateError('Scan plan concurrency must be greater than zero.');
    }
    if (plan.portTimeout <= Duration.zero) {
      throw StateError('Scan plan portTimeout must be greater than zero.');
    }
  }

  Future<bool> _runPhase(VNPTScanPhase phase) async {
    final targets = <_TargetIp>[
      for (final suffix in phase.hostSuffixes)
        _TargetIp(ip: '${request.network.subnet}.$suffix', port: _plan!.port),
    ];

    if (targets.isEmpty) {
      return false;
    }

    var nextIndex = 0;
    var phaseFoundCandidate = false;
    final workerCount = min(_plan!.concurrency, targets.length);

    Future<void> worker() async {
      while (true) {
        if (_cancelRequested) {
          return;
        }

        final targetIndex = nextIndex++;
        if (targetIndex >= targets.length) {
          return;
        }

        final foundCandidate = await _probeTarget(targets[targetIndex]);
        if (foundCandidate) {
          phaseFoundCandidate = true;
        }
      }
    }

    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
    return phaseFoundCandidate;
  }

  Future<bool> _probeTarget(_TargetIp target) async {
    final result = await endpointProbe.probe(
      target.ip,
      target.port,
      _plan!.portTimeout,
    );

    _probedTargets += 1;

    var foundCandidate = false;
    if (result.isOpen) {
      foundCandidate = _recordCandidate(result);
    }

    _emitProgress();
    return foundCandidate;
  }

  bool _recordCandidate(VNPTEndpointProbeResult result) {
    final now = DateTime.now();
    final previous = _candidates[result.ip];
    final next = VNPTDiscoveredDevice(
      ip: result.ip,
      port: result.port,
      responseTimeMs: _pickBestResponseTime(
        previous?.responseTimeMs,
        result.responseTimeMs,
      ),
      firstSeen: previous?.firstSeen ?? now,
      lastSeen: now,
    );

    _candidates[result.ip] = next;
    _snapshotPending = true;

    if (previous == null) {
      _eventsController.add(VNPTCandidateFound(next));
      _emitProgress(force: true);
      return true;
    }

    return false;
  }

  int? _pickBestResponseTime(int? previous, int? current) {
    if (previous == null) {
      return current;
    }
    if (current == null) {
      return previous;
    }
    return min(previous, current);
  }

  void _emitCandidateListUpdated() {
    if (!_snapshotPending) {
      return;
    }

    _snapshotPending = false;
    _eventsController.add(
      VNPTCandidateListUpdated(_candidates.values.toList(growable: false)),
    );
  }

  Future<void> _complete({required bool cancelled}) async {
    if (_isFinalized) {
      return;
    }
    _isFinalized = true;

    _emitProgress(
      force: true,
      isComplete: true,
      phaseName: cancelled ? 'cancelled' : 'completed',
      phaseIndex: cancelled ? _currentPhaseIndex : _currentPhaseIndex,
    );

    final result = VNPTDiscoveryResult(
      devices: _candidates.values.toList(growable: false),
      cancelled: cancelled,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
    );
    _eventsController.add(VNPTDiscoveryCompleted(result));

    await _eventsController.close();
    await _progressController.close();
  }

  Future<void> _fail(Object error, StackTrace stackTrace) async {
    if (_isFinalized) {
      return;
    }
    _isFinalized = true;
    logger.error('Discovery session failed.', error, stackTrace);
    _eventsController.add(
      VNPTDiscoveryFailed(_mapFailureReason(error), stackTrace, cause: error),
    );
    await _eventsController.close();
    await _progressController.close();
  }

  VNPTDiscoveryFailureReason _mapFailureReason(Object error) {
    if (error is TimeoutException) {
      return VNPTDiscoveryFailureReason.timeout;
    }
    if (error is SocketException) {
      return VNPTDiscoveryFailureReason.networkUnavailable;
    }
    if (error is ArgumentError ||
        error is FormatException ||
        error is StateError) {
      return VNPTDiscoveryFailureReason.invalidRequest;
    }
    return VNPTDiscoveryFailureReason.unknown;
  }

  void _emitProgress({
    bool force = false,
    bool isComplete = false,
    String? phaseName,
    int? phaseIndex,
  }) {
    final plan = _plan;
    if (plan == null) {
      return;
    }

    final nextPhaseName = phaseName ?? _currentPhaseName;
    final nextPhaseIndex = phaseIndex ?? _currentPhaseIndex;
    final now = DateTime.now();
    final phaseChanged =
        nextPhaseIndex != _lastEmittedPhaseIndex ||
        nextPhaseName != _lastEmittedPhaseName;
    final candidateChanged = _candidates.length != _lastEmittedCandidates;
    final targetDelta = _lastEmittedTargets < 0
        ? _probedTargets
        : _probedTargets - _lastEmittedTargets;
    final timeExceeded =
        _lastProgressEmitAt == null ||
        now.difference(_lastProgressEmitAt!) >=
            const Duration(milliseconds: 100);

    if (!force &&
        !phaseChanged &&
        !candidateChanged &&
        !isComplete &&
        targetDelta < 4 &&
        !timeExceeded) {
      return;
    }

    _lastEmittedTargets = _probedTargets;
    _lastEmittedCandidates = _candidates.length;
    _lastEmittedPhaseIndex = nextPhaseIndex;
    _lastEmittedPhaseName = nextPhaseName;
    _lastProgressEmitAt = now;

    _progressController.add(
      VNPTScanProgress(
        phaseName: nextPhaseName,
        phaseIndex: nextPhaseIndex,
        totalPhases: plan.phases.length,
        probedTargets: _probedTargets,
        totalTargets: plan.totalTargets,
        candidatesFound: _candidates.length,
        isComplete: isComplete,
      ),
    );
  }
}

class _TargetIp {
  final String ip;
  final int port;

  const _TargetIp({required this.ip, required this.port});
}
