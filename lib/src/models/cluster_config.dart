/// Configuration for a cluster.
///
/// This class defines the configuration parameters for a specific cluster,
/// including host, port, TLS settings, and optional additional headers.
///
/// Example:
/// ```dart
/// const config = ClusterConfig(
///   host: 'reverb-us-east-1.pusher.com',
///   port: 443,
///   useTLS: true,
///   region: 'us-east-1',
/// );
/// ```
class ClusterConfig {
  /// The host address for this cluster.
  final String host;

  /// The port number for this cluster.
  final int port;

  /// Whether to use TLS/SSL for secure connections.
  final bool useTLS;

  /// The region identifier for this cluster (optional).
  final String? region;

  /// Additional headers to include in requests (optional).
  final Map<String, String>? additionalHeaders;

  /// Creates a new ClusterConfig.
  const ClusterConfig({required this.host, required this.port, required this.useTLS, this.region, this.additionalHeaders});

  @override
  String toString() {
    return 'ClusterConfig(host: $host, port: $port, useTLS: $useTLS, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClusterConfig && other.host == host && other.port == port && other.useTLS == useTLS && other.region == region;
  }

  @override
  int get hashCode {
    return Object.hash(host, port, useTLS, region);
  }
}

/// Resolved configuration after applying cluster settings.
///
/// This internal class holds the final configuration values after
/// cluster resolution and parameter priority application.
class ResolvedConfig {
  /// The final host address.
  final String host;

  /// The final port number.
  final int port;

  /// The final TLS setting.
  final bool useTLS;

  /// Additional headers from cluster configuration.
  final Map<String, String> additionalHeaders;

  /// Creates a new ResolvedConfig.
  const ResolvedConfig({required this.host, required this.port, required this.useTLS, required this.additionalHeaders});

  @override
  String toString() {
    return 'ResolvedConfig(host: $host, port: $port, useTLS: $useTLS)';
  }
}
