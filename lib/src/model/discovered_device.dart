/// Represents a VNPT device discovered on the network.
class VNPTDiscoveredDevice {
  /// The IP address of the discovered device.
  final String ip;

  /// The port on which the device was discovered (typically 40029).
  final int port;

  /// The round-trip time in milliseconds for the discovery probe.
  final int? responseTimeMs;

  /// When the device was first seen during the current session.
  final DateTime firstSeen;

  /// When the device was last seen/verified.
  final DateTime lastSeen;

  /// Creates a [VNPTDiscoveredDevice] with the given information.
  const VNPTDiscoveredDevice({
    required this.ip,
    required this.port,
    this.responseTimeMs,
    required this.firstSeen,
    required this.lastSeen,
  });

  VNPTDiscoveredDevice copyWith({
    int? port,
    int? responseTimeMs,
    DateTime? firstSeen,
    DateTime? lastSeen,
  }) {
    return VNPTDiscoveredDevice(
      ip: ip,
      port: port ?? this.port,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VNPTDiscoveredDevice &&
        other.ip == ip &&
        other.port == port &&
        other.responseTimeMs == responseTimeMs &&
        other.firstSeen == firstSeen &&
        other.lastSeen == lastSeen;
  }

  @override
  int get hashCode =>
      Object.hash(ip, port, responseTimeMs, firstSeen, lastSeen);
}
