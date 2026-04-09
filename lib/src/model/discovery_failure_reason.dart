/// Defines the high-level reasons why a discovery session might fail.
enum VNPTDiscoveryFailureReason {
  /// The local network is not available or unreachable.
  networkUnavailable,

  /// The application lacks the necessary system permissions to perform a scan.
  permissionDenied,

  /// The discovery session timed out globally.
  timeout,

  /// The provided discovery request is invalid or malformed.
  invalidRequest,

  /// An unknown or unexpected error occurred.
  unknown,
}
