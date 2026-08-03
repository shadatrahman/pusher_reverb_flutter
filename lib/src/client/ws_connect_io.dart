import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Native (non-web) implementation: uses [IOWebSocketChannel] to preserve
/// support for connection-level [headers] (e.g. an apiKey Bearer token) and
/// [pingInterval] for protocol-level WebSocket keepalive frames.
WebSocketChannel createWebSocketChannel(
  Uri uri, {
  Map<String, dynamic>? headers,
  Duration? pingInterval,
}) {
  return IOWebSocketChannel.connect(
    uri,
    headers: headers,
    pingInterval: pingInterval,
  );
}
