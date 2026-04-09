import 'network_context.dart';

/// Defines the characteristics of the scanning session.
enum VNPTScanProfile {
  /// Optimized for real-world application usage.
  production,

  /// Optimized for fast execution during automated tests.
  test,

  /// Optimized for deep troubleshooting with more verbose timing.
  diagnostic,
}

/// A request to start a VNPT device discovery session.
class VNPTDiscoveryRequest {
  /// The network environment information (local IP, subnet, etc.).
  final VNPTNetworkContext network;

  /// The scanning profile to use for timing and concurrency.
  final VNPTScanProfile profile;

  /// Optional override for the per-port probe timeout.
  final Duration? portTimeoutOverride;

  /// Optional override for the number of concurrent probes.
  final int? concurrencyOverride;

  /// Creates a [VNPTDiscoveryRequest] with the given settings.
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
