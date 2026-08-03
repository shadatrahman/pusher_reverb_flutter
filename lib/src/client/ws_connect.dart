/// Platform-adaptive WebSocket factory.
///
/// On Flutter web, `dart:io` is unavailable, so `IOWebSocketChannel` cannot be
/// used — it throws "Unsupported operation: Platform._version" at runtime.
/// This conditional export resolves to `ws_connect_web.dart` on web and
/// `ws_connect_io.dart` on all other platforms, preserving full native
/// behaviour (headers, pingInterval) while adding web support.
library;

export 'ws_connect_web.dart' if (dart.library.io) 'ws_connect_io.dart';
