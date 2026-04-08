class VNPTDiscoveredDevice {
  final String ip;
  final int port;
  final int? responseTimeMs;
  final DateTime firstSeen;
  final DateTime lastSeen;

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
