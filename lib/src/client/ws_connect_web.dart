import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Set to `true` once the web header/keepalive warning has been emitted, so a
/// reconnect loop does not spam the console.
bool _warnedAboutUnsupportedOptions = false;

/// Resets the one-shot warning latch. Test-only.
@visibleForTesting
void debugResetWebConnectWarnings() {
  _warnedAboutUnsupportedOptions = false;
}

/// Web implementation: uses the platform-agnostic [WebSocketChannel.connect].
///
/// The browser's WebSocket API exposes no way to set handshake headers or to
/// send protocol-level ping frames, so [headers] (including the `apiKey`
/// `Authorization` header) and [pingInterval] cannot be honoured here. Both are
/// dropped, and a warning is logged once in debug builds so the difference is
/// not silent.
///
/// Channel-level auth (private/presence/encrypted) is unaffected — it goes
/// through the `Authorizer` callback over HTTP, not the connection headers.
/// Keepalive still works at the application level: Reverb sends `pusher:ping`
/// on an idle connection and the client replies with `pusher:pong`.
WebSocketChannel createWebSocketChannel(
  Uri uri, {
  Map<String, dynamic>? headers,
  Duration? pingInterval,
}) {
  if (!_warnedAboutUnsupportedOptions &&
      (headers != null || pingInterval != null)) {
    _warnedAboutUnsupportedOptions = true;
    final dropped = [
      if (headers != null) 'connection headers (apiKey/additionalHeaders)',
      if (pingInterval != null) 'pingInterval',
    ].join(' and ');
    debugPrint(
      'pusher_reverb_flutter: running on web — $dropped ignored. '
      'The browser WebSocket API supports neither handshake headers nor '
      'protocol-level ping frames. If your server requires the '
      'Authorization header to accept the connection, it will reject this '
      'handshake; authenticate per-channel via the authorizer instead. '
      'Idle connections stay alive via pusher:ping/pusher:pong.',
    );
  }
  return WebSocketChannel.connect(uri);
}
