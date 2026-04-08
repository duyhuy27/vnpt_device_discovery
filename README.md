# vnpt_device_discovery

`vnpt_device_discovery` is a Flutter package for one job only: probe likely VNPT target IPs on port `40029`, emit candidates immediately, and stop after the first successful phase finishes.

## Scope

This package does:
- accept a `VNPTNetworkContext` from the host app
- build a fixed three-phase scan plan
- probe candidate `ip:40029` targets directly
- emit event and progress streams

This package does not:
- do mDNS, hostname, MAC, vendor, or service-hint enrichment
- do host ping scans or generic network classification
- persist discovery state or caches
- ship UI widgets or app state

## Default scan strategy

Every plan uses the same phases and fixed port:
- `targeted`: `[133, 132, 134]`
- `nearbyExpanded`: `[133, 132, 134, local, local - 1, local + 1, 100, 101, 102]` minus anything already in `targeted`
- `genericFallback`: `1..254` minus everything already covered by earlier phases

Runtime behavior is fixed:
- run `targeted`
- if it finds at least one candidate, finish that phase, emit `VNPTCandidateListUpdated`, and stop
- otherwise run `nearbyExpanded`
- if it still finds none, run `genericFallback`

`totalTargets` is computed once at `VNPTDiscoveryStarted` and remains fixed for the full session.

## Cancellation guarantee

Calling `cancel()` stops scheduling new probes and waits only for in-flight probes to finish.
If candidates were found in the current phase but no phase-boundary snapshot has been emitted yet, cancellation emits one final `VNPTCandidateListUpdated` before `VNPTDiscoveryCompleted`.

## Usage

```dart
final network = VNPTNetworkContext(
  localIp: '192.168.88.140',
  subnet: '192.168.88',
  subnetMask: '255.255.255.0',
);

final discovery = VNPTDiscoveryEngine.standard();
final session = discovery.createSession(
  request: VNPTDiscoveryRequest.production(network),
);

session.progress.listen((progress) {
  debugPrint(
    'phase=${progress.phaseName} '
    'probed=${progress.probedTargets}/${progress.totalTargets}',
  );
});

session.events.listen((event) {
  switch (event) {
    case VNPTCandidateFound(:final device):
      debugPrint('candidate: ${device.ip}:${device.port}');
    case VNPTCandidateListUpdated(:final devices):
      debugPrint('snapshot candidates=${devices.length}');
    case VNPTDiscoveryCompleted(:final result):
      debugPrint('completed candidates=${result.devices.length}');
    case VNPTDiscoveryFailed(:final reason):
      debugPrint('failed: $reason');
    default:
      break;
  }
});
```

## Example

A minimal Flutter example lives under [`example_test/`](example).
The example expects the caller to provide `localIp`, `subnet`, and `subnetMask` manually so the package stays independent from app-specific network initialization.
