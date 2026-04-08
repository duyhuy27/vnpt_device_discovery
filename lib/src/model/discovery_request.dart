import 'network_context.dart';

enum VNPTScanProfile { production, test, diagnostic }

class VNPTDiscoveryRequest {
  final VNPTNetworkContext network;
  final VNPTScanProfile profile;
  final Duration? portTimeoutOverride;
  final int? concurrencyOverride;

  const VNPTDiscoveryRequest({
    required this.network,
    required this.profile,
    this.portTimeoutOverride,
    this.concurrencyOverride,
  });

  factory VNPTDiscoveryRequest.production(
    VNPTNetworkContext network, {
    Duration? portTimeout,
    int? concurrency,
  }) {
    return VNPTDiscoveryRequest(
      network: network,
      profile: VNPTScanProfile.production,
      portTimeoutOverride: portTimeout,
      concurrencyOverride: concurrency,
    );
  }

  factory VNPTDiscoveryRequest.test(
    VNPTNetworkContext network, {
    Duration? portTimeout,
    int? concurrency,
  }) {
    return VNPTDiscoveryRequest(
      network: network,
      profile: VNPTScanProfile.test,
      portTimeoutOverride: portTimeout,
      concurrencyOverride: concurrency,
    );
  }

  factory VNPTDiscoveryRequest.diagnostic(
    VNPTNetworkContext network, {
    Duration? portTimeout,
    int? concurrency,
  }) {
    return VNPTDiscoveryRequest(
      network: network,
      profile: VNPTScanProfile.diagnostic,
      portTimeoutOverride: portTimeout,
      concurrencyOverride: concurrency,
    );
  }
}
