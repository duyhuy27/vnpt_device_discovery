import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnpt_device_discovery/vnpt_device_discovery.dart';

void main() {
  const network = VNPTNetworkContext(
    localIp: '192.168.88.140',
    subnet: '192.168.88',
    subnetMask: '255.255.255.0',
  );

  test('finds 2 AIBox devices in the winning targeted phase', () async {
    await expectWinningPhaseFindsAllDevices(
      openIps: const ['192.168.88.133', '192.168.88.132'],
      expectedPhaseStopsBeforeGenericFallback: true,
    );
  });

  test('finds 3 AIBox devices in the winning targeted phase', () async {
    await expectWinningPhaseFindsAllDevices(
      openIps: const ['192.168.88.133', '192.168.88.132', '192.168.88.134'],
      expectedPhaseStopsBeforeGenericFallback: true,
    );
  });

  test('finds 4 AIBox devices in the winning nearbyExpanded phase', () async {
    await expectWinningPhaseFindsAllDevices(
      openIps: const [
        '192.168.88.140',
        '192.168.88.139',
        '192.168.88.141',
        '192.168.88.100',
      ],
      expectedPhaseStopsBeforeGenericFallback: true,
    );
  });

  test('if targeted finds a candidate, no later phase runs', () async {
    final probe = FakeEndpointProbe(
      behaviors: <String, ProbeBehavior>{
        '192.168.88.133:40029': const ProbeBehavior(
          isOpen: true,
          delay: Duration(milliseconds: 1),
          responseTimeMs: 1,
        ),
      },
    );
    final session =
        VNPTDiscoveryEngine(
          planner: const VNPTProductionPlanner(),
          endpointProbe: probe,
          logger: const NoopScanLogger(),
        ).createSession(
          request: VNPTDiscoveryRequest.test(network, concurrency: 1),
        );

    final events = await collectEvents(session);
    final completed = events.whereType<VNPTDiscoveryCompleted>().single;

    expect(events.whereType<VNPTCandidateFound>().map((it) => it.device.ip), [
      '192.168.88.133',
    ]);
    expect(
      events.whereType<VNPTCandidateListUpdated>().single.devices.map(
        (it) => it.ip,
      ),
      ['192.168.88.133'],
    );
    expect(completed.result.devices.map((it) => it.ip), ['192.168.88.133']);
    expect(
      probe.timeline.any(
        (entry) =>
            entry.startsWith('192.168.88.140:') ||
            entry.startsWith('192.168.88.1:'),
      ),
      isFalse,
    );
  });

  test(
    'if targeted finds none and nearbyExpanded finds one, genericFallback does not run',
    () async {
      final probe = FakeEndpointProbe(
        behaviors: <String, ProbeBehavior>{
          '192.168.88.140:40029': const ProbeBehavior(
            isOpen: true,
            delay: Duration(milliseconds: 1),
            responseTimeMs: 1,
          ),
        },
      );
      final session =
          VNPTDiscoveryEngine(
            planner: const VNPTProductionPlanner(),
            endpointProbe: probe,
            logger: const NoopScanLogger(),
          ).createSession(
            request: VNPTDiscoveryRequest.test(network, concurrency: 1),
          );

      final events = await collectEvents(session);

      expect(
        events.whereType<VNPTCandidateFound>().single.device.ip,
        '192.168.88.140',
      );
      expect(
        events.whereType<VNPTCandidateListUpdated>().single.devices.map(
          (it) => it.ip,
        ),
        ['192.168.88.140'],
      );
      expect(
        probe.timeline.any((entry) => entry.startsWith('192.168.88.1:')),
        isFalse,
      );
    },
  );

  test('if both early phases find none, genericFallback runs', () async {
    final probe = FakeEndpointProbe(
      behaviors: <String, ProbeBehavior>{
        '192.168.88.5:40029': const ProbeBehavior(
          isOpen: true,
          delay: Duration(milliseconds: 1),
          responseTimeMs: 1,
        ),
      },
    );
    final session =
        VNPTDiscoveryEngine(
          planner: const VNPTProductionPlanner(),
          endpointProbe: probe,
          logger: const NoopScanLogger(),
        ).createSession(
          request: VNPTDiscoveryRequest.test(network, concurrency: 1),
        );

    final events = await collectEvents(session);

    expect(
      events.whereType<VNPTCandidateFound>().single.device.ip,
      '192.168.88.5',
    );
    expect(
      events.whereType<VNPTCandidateListUpdated>().single.devices.map(
        (it) => it.ip,
      ),
      ['192.168.88.5'],
    );
    expect(probe.timeline, contains('192.168.88.1:40029'));
    expect(probe.timeline, contains('192.168.88.5:40029'));
  });

  test(
    'candidate list updates are phase-boundary milestones, not per probe',
    () async {
      final probe = FakeEndpointProbe(
        behaviors: <String, ProbeBehavior>{
          '192.168.88.133:40029': const ProbeBehavior(isOpen: true),
          '192.168.88.132:40029': const ProbeBehavior(isOpen: true),
        },
      );
      final session =
          VNPTDiscoveryEngine(
            planner: const VNPTProductionPlanner(),
            endpointProbe: probe,
            logger: const NoopScanLogger(),
          ).createSession(
            request: VNPTDiscoveryRequest.test(network, concurrency: 1),
          );

      final events = await collectEvents(session);
      final milestone = events.whereType<VNPTCandidateListUpdated>().single;

      expect(events.whereType<VNPTCandidateFound>().map((it) => it.device.ip), [
        '192.168.88.133',
        '192.168.88.132',
      ]);
      expect(events.whereType<VNPTCandidateListUpdated>(), hasLength(1));
      expect(milestone.devices.map((it) => it.ip), [
        '192.168.88.133',
        '192.168.88.132',
      ]);
    },
  );

  test('completed result contains only candidates', () async {
    final probe = FakeEndpointProbe(
      behaviors: <String, ProbeBehavior>{
        '192.168.88.133:40029': const ProbeBehavior(isOpen: true),
      },
    );
    final session =
        VNPTDiscoveryEngine(
          planner: const VNPTProductionPlanner(),
          endpointProbe: probe,
          logger: const NoopScanLogger(),
        ).createSession(
          request: VNPTDiscoveryRequest.test(network, concurrency: 1),
        );

    final events = await collectEvents(session);
    final completed = events.whereType<VNPTDiscoveryCompleted>().single;

    expect(completed.result.devices, hasLength(1));
    expect(completed.result.devices.single.ip, '192.168.88.133');
  });

  test(
    'cancel during a phase does not start another phase and flushes pending snapshot before completion',
    () async {
      final gate = Completer<void>();
      final probe = CancelAwareProbe(gate);
      final session =
          VNPTDiscoveryEngine(
            planner: const VNPTProductionPlanner(),
            endpointProbe: probe,
            logger: const NoopScanLogger(),
          ).createSession(
            request: const VNPTDiscoveryRequest(
              network: network,
              profile: VNPTScanProfile.test,
              portTimeoutOverride: Duration(milliseconds: 40),
              concurrencyOverride: 1,
            ),
          );

      final events = <VNPTDiscoveryEvent>[];
      final completed = Completer<VNPTDiscoveryCompleted>();
      final candidateFound = Completer<void>();

      session.events.listen((event) {
        events.add(event);
        if (event is VNPTCandidateFound && !candidateFound.isCompleted) {
          candidateFound.complete();
        }
        if (event is VNPTDiscoveryCompleted && !completed.isCompleted) {
          completed.complete(event);
        }
      });

      await candidateFound.future.timeout(const Duration(seconds: 1));
      final cancelFuture = session.cancel();
      gate.complete();

      await cancelFuture;
      final result = await completed.future.timeout(const Duration(seconds: 1));
      final listUpdatedIndex = events.indexWhere(
        (event) => event is VNPTCandidateListUpdated,
      );
      final completedIndex = events.indexWhere(
        (event) => event is VNPTDiscoveryCompleted,
      );

      expect(result.result.cancelled, isTrue);
      expect(listUpdatedIndex, greaterThan(-1));
      expect(listUpdatedIndex, lessThan(completedIndex));
      expect(
        probe.timeline.any(
          (entry) =>
              entry.startsWith('192.168.88.140:') ||
              entry.startsWith('192.168.88.1:'),
        ),
        isFalse,
      );
    },
  );

  test(
    'completion after cancel still respects the configured portTimeout bound',
    () async {
      final probe = TimeoutBoundProbe();
      final session =
          VNPTDiscoveryEngine(
            planner: const VNPTProductionPlanner(),
            endpointProbe: probe,
            logger: const NoopScanLogger(),
          ).createSession(
            request: VNPTDiscoveryRequest.test(
              network,
              portTimeout: const Duration(milliseconds: 40),
              concurrency: 2,
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 5));
      final watch = Stopwatch()..start();
      await session.cancel();
      watch.stop();

      expect(
        watch.elapsed,
        lessThanOrEqualTo(const Duration(milliseconds: 80)),
      );
    },
  );

  test('progress remains throttled and uses target counts', () async {
    final probe = FakeEndpointProbe();
    final session =
        VNPTDiscoveryEngine(
          planner: const VNPTProductionPlanner(),
          endpointProbe: probe,
          logger: const NoopScanLogger(),
        ).createSession(
          request: VNPTDiscoveryRequest.test(network, concurrency: 1),
        );

    final progress = <VNPTScanProgress>[];
    final done = Completer<void>();
    session.progress.listen(progress.add, onDone: () => done.complete());

    await done.future.timeout(const Duration(seconds: 2));

    expect(progress, isNotEmpty);
    expect(progress.every((item) => item.totalTargets == 254), isTrue);
    expect(progress.last.probedTargets, 254);
    expect(progress.length, lessThan(90));
  });

  test(
    'no mDNS, hostname, vendor, classifier, or port override path remains',
    () async {
      final libDir = Directory('lib');
      final files = await libDir
          .list(recursive: true)
          .where((entry) => entry is File && entry.path.endsWith('.dart'))
          .cast<File>()
          .toList();
      final fileNames = files
          .map((file) => file.path.split(Platform.pathSeparator).last)
          .toList();
      final source = StringBuffer();

      for (final file in files) {
        source.writeln(await file.readAsString());
      }

      final joinedSource = source.toString();
      expect(fileNames, isNot(contains('candidate_reason.dart')));
      expect(fileNames, isNot(contains('device_classifier.dart')));
      expect(fileNames, isNot(contains('mdns_enricher.dart')));
      expect(joinedSource.contains('Mdns'), isFalse);
      expect(joinedSource.contains('hostname'), isFalse);
      expect(joinedSource.contains('vendor'), isFalse);
      expect(joinedSource.contains('Classifier'), isFalse);
      expect(joinedSource.contains('portsOverride'), isFalse);
    },
  );

  test('unexpected probe errors fail the session with a typed error', () async {
    final probe = FakeEndpointProbe(
      behaviors: <String, ProbeBehavior>{
        '192.168.88.133:40029': ProbeBehavior.error(UnsupportedError('boom')),
      },
    );
    final session =
        VNPTDiscoveryEngine(
          planner: const VNPTProductionPlanner(),
          endpointProbe: probe,
          logger: const NoopScanLogger(),
        ).createSession(
          request: VNPTDiscoveryRequest.test(network, concurrency: 1),
        );

    final events = <VNPTDiscoveryEvent>[];
    final done = Completer<void>();
    session.events.listen(events.add, onDone: () => done.complete());

    await done.future.timeout(const Duration(seconds: 1));

    expect(events.first, isA<VNPTDiscoveryStarted>());
    expect(events.whereType<VNPTDiscoveryCompleted>(), isEmpty);
    expect(
      events.whereType<VNPTDiscoveryFailed>().single.reason,
      VNPTDiscoveryFailureReason.unknown,
    );
  });
}

Future<void> expectWinningPhaseFindsAllDevices({
  required List<String> openIps,
  required bool expectedPhaseStopsBeforeGenericFallback,
}) async {
  const network = VNPTNetworkContext(
    localIp: '192.168.88.140',
    subnet: '192.168.88',
    subnetMask: '255.255.255.0',
  );

  final behaviors = <String, ProbeBehavior>{
    for (final ip in openIps) '$ip:40029': const ProbeBehavior(isOpen: true),
  };
  final probe = FakeEndpointProbe(behaviors: behaviors);
  final session = VNPTDiscoveryEngine(
    planner: const VNPTProductionPlanner(),
    endpointProbe: probe,
    logger: const NoopScanLogger(),
  ).createSession(request: VNPTDiscoveryRequest.test(network, concurrency: 1));

  final events = await collectEvents(session);
  final foundIps = events
      .whereType<VNPTCandidateFound>()
      .map((event) => event.device.ip)
      .toList(growable: false);
  final snapshots = events.whereType<VNPTCandidateListUpdated>().toList();
  final completed = events.whereType<VNPTDiscoveryCompleted>().single;

  expect(foundIps, openIps);
  expect(snapshots, hasLength(1));
  expect(
    snapshots.single.devices.map((device) => device.ip).toList(growable: false),
    openIps,
  );
  expect(
    completed.result.devices.map((device) => device.ip).toList(growable: false),
    openIps,
  );

  if (expectedPhaseStopsBeforeGenericFallback) {
    expect(
      probe.timeline.any((entry) => entry.startsWith('192.168.88.1:')),
      isFalse,
    );
  }
}

Future<List<VNPTDiscoveryEvent>> collectEvents(
  VNPTDiscoverySession session,
) async {
  final events = <VNPTDiscoveryEvent>[];
  final done = Completer<void>();
  session.events.listen(events.add, onDone: () => done.complete());
  await done.future.timeout(const Duration(seconds: 2));
  return events;
}

class FakeEndpointProbe implements VNPTEndpointProbe {
  final Map<String, ProbeBehavior> behaviors;
  final List<String> timeline = <String>[];

  FakeEndpointProbe({this.behaviors = const <String, ProbeBehavior>{}});

  @override
  Future<VNPTEndpointProbeResult> probe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    final key = '$ip:$port';
    timeline.add(key);
    final behavior = behaviors[key] ?? const ProbeBehavior();
    await Future<void>.delayed(behavior.delay);
    if (behavior.error != null) {
      throw behavior.error!;
    }
    return VNPTEndpointProbeResult(
      ip: ip,
      port: port,
      isOpen: behavior.isOpen,
      responseTimeMs: behavior.responseTimeMs,
    );
  }
}

class CancelAwareProbe implements VNPTEndpointProbe {
  final Completer<void> gate;
  final List<String> timeline = <String>[];

  CancelAwareProbe(this.gate);

  @override
  Future<VNPTEndpointProbeResult> probe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    final key = '$ip:$port';
    timeline.add(key);
    if (ip == '192.168.88.133') {
      return const VNPTEndpointProbeResult(
        ip: '192.168.88.133',
        port: 40029,
        isOpen: true,
        responseTimeMs: 1,
      );
    }
    await gate.future.timeout(timeout, onTimeout: () => null);
    return VNPTEndpointProbeResult(
      ip: ip,
      port: port,
      isOpen: false,
      responseTimeMs: timeout.inMilliseconds,
    );
  }
}

class TimeoutBoundProbe implements VNPTEndpointProbe {
  @override
  Future<VNPTEndpointProbeResult> probe(
    String ip,
    int port,
    Duration timeout,
  ) async {
    await Future<void>.delayed(timeout);
    return VNPTEndpointProbeResult(
      ip: ip,
      port: port,
      isOpen: false,
      responseTimeMs: timeout.inMilliseconds,
    );
  }
}

class ProbeBehavior {
  final bool isOpen;
  final Duration delay;
  final int? responseTimeMs;
  final Object? error;

  const ProbeBehavior({
    this.isOpen = false,
    this.delay = Duration.zero,
    this.responseTimeMs,
    this.error,
  });

  const ProbeBehavior.error(Object this.error)
    : isOpen = false,
      delay = Duration.zero,
      responseTimeMs = null;
}
