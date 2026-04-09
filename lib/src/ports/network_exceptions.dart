/// Base class for all VNPT network-related exceptions.
abstract class VNPTNetworkException implements Exception {
  /// The message describing the error.
  final String message;

  /// Creates a [VNPTNetworkException] with the given [message].
  const VNPTNetworkException(this.message);

  @override
  String toString() => 'VNPTNetworkException: $message';
}

/// Thrown when the local network is unavailable or unreachable.
class VNPTNetworkUnavailableException extends VNPTNetworkException {
  /// Creates a [VNPTNetworkUnavailableException].
  const VNPTNetworkUnavailableException([super.message = 'Network unavailable']);
}
