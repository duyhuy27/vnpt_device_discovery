import 'dart:async';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:vnpt_device_discovery/vnpt_device_discovery.dart';

void main() {
  runApp(const VNPTDiscoveryExampleApp());
}

class VNPTDiscoveryExampleApp extends StatelessWidget {
  const VNPTDiscoveryExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VNPT Discovery Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057B8)),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final info = NetworkInfo();

  final _localIpController = TextEditingController(text: '192.168.88.140');
  final _subnetController = TextEditingController(text: '192.168.88');
  final _maskController = TextEditingController(text: '255.255.255.0');

  final List<String> _logs = <String>[];
  final Map<String, VNPTDiscoveredDevice> _devices = {};

  VNPTScanProgress? _progress;
  VNPTDiscoverySession? _session;
  StreamSubscription<VNPTDiscoveryEvent>? _eventSubscription;
  StreamSubscription<VNPTScanProgress>? _progressSubscription;
  bool _scanning = false;

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _progressSubscription?.cancel();
    _session?.cancel();
    _localIpController.dispose();
    _subnetController.dispose();
    _maskController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    await _eventSubscription?.cancel();
    await _progressSubscription?.cancel();
    await _session?.cancel();

    _devices.clear();
    _logs.clear();
    setState(() {
      _scanning = true;
      _progress = null;
    });
    final wifiIP = await info.getWifiIP(); // 192.168.1.43
    if (wifiIP == null) {
      setState(() {
        _scanning = false;
        _progress = null;
      });
      return;
    }
    final parts = wifiIP.split('.');
    if (parts.length != 4) {
      return;
    }
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    const subnetMask = '255.255.255.0';
    final request = VNPTDiscoveryRequest.production(
      VNPTNetworkContext(
        localIp: wifiIP,
        subnet: subnet,
        subnetMask: subnetMask,
      ),
    );

    final session = VNPTDiscoveryEngine.standard().createSession(
      request: request,
    );
    _session = session;

    _eventSubscription = session.events.listen((event) {
      switch (event) {
        case VNPTDiscoveryStarted(:final plan):
          _logs.add('started totalTargets=${plan.totalTargets}');
        case VNPTCandidateFound(:final device):
          _devices[device.ip] = device;
          _logs.add('candidate ${device.ip}:${device.port}');
        case VNPTCandidateListUpdated(:final devices):
          for (final device in devices) {
            _devices[device.ip] = device;
          }
          _logs.add('snapshot candidates=${devices.length}');
        case VNPTDiscoveryCompleted(:final result):
          _logs.add(
            'completed cancelled=${result.cancelled} candidates=${result.devices.length}',
          );
          _scanning = false;
        case VNPTDiscoveryFailed(:final reason):
          _logs.add('failed reason=$reason');
          _scanning = false;
      }
      if (mounted) {
        setState(() {});
      }
    });

    _progressSubscription = session.progress.listen((progress) {
      _progress = progress;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _cancelScan() async {
    await _session?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressText = _progress == null
        ? 'idle'
        : '${_progress!.phaseName} ${_progress!.probedTargets}/${_progress!.totalTargets}';

    return Scaffold(
      appBar: AppBar(title: const Text('VNPT Discovery Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _localIpController,
                    decoration: const InputDecoration(
                      labelText: 'Local IP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _subnetController,
                    decoration: const InputDecoration(
                      labelText: 'Subnet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _maskController,
                    decoration: const InputDecoration(
                      labelText: 'Subnet mask',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: _scanning ? null : _startScan,
                  child: const Text('Start discovery'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _scanning ? _cancelScan : null,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                Text(progressText),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: _devices.values
                            .map(
                              (device) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(device.ip),
                                subtitle: Text(
                                  'port=${device.port} '
                                  'response=${device.responseTimeMs ?? '-'}ms',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: _logs
                            .map(
                              (log) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(log),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
