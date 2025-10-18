/// Represents the current connection status of the ReverbClient.
enum ConnectionState {
  /// The client is attempting to connect to the server.
  connecting,

  /// The client is successfully connected to the server.
  connected,

  /// The client is disconnected from the server.
  disconnected,

  /// The client is attempting to reconnect after losing connection.
  reconnecting,

  /// An error occurred during connection or communication.
  error,
}
