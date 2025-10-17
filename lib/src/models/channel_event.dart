/// Represents an event received on a channel.
///
/// This immutable class encapsulates all information about a channel event,
/// including the channel name, event name, and associated data payload.
class ChannelEvent {
  /// The name of the channel where the event was received.
  final String channelName;

  /// The name of the event.
  final String eventName;

  /// The data payload associated with the event.
  final dynamic data;

  /// Creates a new ChannelEvent instance.
  ///
  /// All parameters are required and the instance is immutable.
  ///
  /// Example:
  /// ```dart
  /// final event = ChannelEvent(
  ///   channelName: 'my-channel',
  ///   eventName: 'message-received',
  ///   data: {'text': 'Hello, World!'},
  /// );
  /// ```
  const ChannelEvent({required this.channelName, required this.eventName, required this.data});

  @override
  String toString() {
    return 'ChannelEvent(channelName: $channelName, eventName: $eventName, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelEvent && other.channelName == channelName && other.eventName == eventName && other.data == data;
  }

  @override
  int get hashCode {
    return Object.hash(channelName, eventName, data);
  }
}
