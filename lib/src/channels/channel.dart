import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import '../models/channel_event.dart';

/// Represents a channel state for subscription management.
enum ChannelState {
  /// Channel is not subscribed.
  unsubscribed,

  /// Channel subscription is in progress.
  subscribing,

  /// Channel is successfully subscribed.
  subscribed,

  /// Channel unsubscription is in progress.
  unsubscribing,
}

/// A callback function for handling channel events.
typedef ChannelEventListener = void Function(String eventName, dynamic data);

/// A callback function for handling channel state changes.
typedef ChannelStateListener = void Function(ChannelState state);

/// A public channel for subscribing to real-time events.
class Channel {
  /// The name of the channel.
  final String name;

  /// The current state of the channel.
  ChannelState _state = ChannelState.unsubscribed;

  /// The current state of the channel.
  ChannelState get state => _state;

  /// Callback for sending WebSocket messages.
  final void Function(String message) _sendMessage;

  /// Map of event listeners registered for this channel.
  final Map<String, List<ChannelEventListener>> _eventListeners = {};

  /// List of state change listeners.
  final List<ChannelStateListener> _stateListeners = [];

  /// Stream controller for channel events.
  final StreamController<ChannelEvent> _eventStreamController = StreamController<ChannelEvent>.broadcast();

  /// Creates a new Channel instance.
  Channel({required this.name, required void Function(String message) sendMessage}) : _sendMessage = sendMessage {
    _validateChannelName();
  }

  /// Validates the channel name according to Pusher conventions.
  void _validateChannelName() {
    if (name.isEmpty) {
      throw ArgumentError('Channel name cannot be empty');
    }

    if (name.length > 200) {
      throw ArgumentError('Channel name cannot exceed 200 characters');
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
    if (invalidChars.hasMatch(name)) {
      throw ArgumentError(
        'Channel name contains invalid characters. Only alphanumeric characters, '
        'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed.',
      );
    }
  }

  /// Subscribes to the channel.
  Future<void> subscribe() async {
    if (_state == ChannelState.subscribed || _state == ChannelState.subscribing) {
      return;
    }

    _setState(ChannelState.subscribing);

    final message = {
      'event': 'pusher:subscribe',
      'data': {'channel': name},
    };

    _sendMessage(_encodeMessage(message));
  }

  /// Unsubscribes from the channel.
  Future<void> unsubscribe() async {
    if (_state == ChannelState.unsubscribed || _state == ChannelState.unsubscribing) {
      return;
    }

    _setState(ChannelState.unsubscribing);

    final message = {
      'event': 'pusher:unsubscribe',
      'data': {'channel': name},
    };

    _sendMessage(_encodeMessage(message));
  }

  /// A stream that emits all events received on this channel.
  ///
  /// Use this stream to reactively listen to all events on the channel.
  ///
  /// Example:
  /// ```dart
  /// channel.stream.listen((event) {
  ///   print('Event: ${event.eventName}, Data: ${event.data}');
  /// });
  /// ```
  Stream<ChannelEvent> get stream => _eventStreamController.stream;

  /// Returns a stream filtered by the specified event name.
  ///
  /// This method allows you to listen to specific events on the channel
  /// without having to filter them manually.
  ///
  /// Example:
  /// ```dart
  /// channel.on('message-received').listen((event) {
  ///   print('Message: ${event.data}');
  /// });
  /// ```
  ///
  /// [eventName] The name of the event to filter by.
  ///
  /// Returns a stream that only emits events matching the specified event name.
  Stream<ChannelEvent> on(String eventName) {
    if (eventName.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }
    return stream.where((event) => event.eventName == eventName);
  }

  /// Binds a listener to a specific event on this channel.
  ///
  /// This is the callback-based API for backward compatibility.
  /// For a more idiomatic Dart approach, consider using the [on] method
  /// which returns a Stream.
  ///
  /// Example:
  /// ```dart
  /// channel.bind('message-received', (eventName, data) {
  ///   print('Message: $data');
  /// });
  /// ```
  void bind(String eventName, ChannelEventListener listener) {
    if (eventName.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }

    _eventListeners.putIfAbsent(eventName, () => []).add(listener);
  }

  /// Unbinds a listener from a specific event on this channel.
  void unbind(String eventName, [ChannelEventListener? listener]) {
    if (eventName.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }

    final listeners = _eventListeners[eventName];
    if (listeners == null) return;

    if (listener != null) {
      // Safe removal: check if listener exists before removing
      if (listeners.contains(listener)) {
        listeners.remove(listener);
        if (listeners.isEmpty) {
          _eventListeners.remove(eventName);
        }
      }
    } else {
      _eventListeners.remove(eventName);
    }
  }

  /// Adds a listener for channel state changes.
  void addStateListener(ChannelStateListener listener) {
    _stateListeners.add(listener);
  }

  /// Removes a listener for channel state changes.
  void removeStateListener(ChannelStateListener listener) {
    // Safe removal: check if listener exists before removing
    if (_stateListeners.contains(listener)) {
      _stateListeners.remove(listener);
    }
  }

  /// Handles incoming events for this channel.
  void handleEvent(String eventName, dynamic data) {
    // Emit event to stream
    final channelEvent = ChannelEvent(channelName: name, eventName: eventName, data: data);
    _eventStreamController.add(channelEvent);

    // Also call callback-based listeners for backward compatibility
    final listeners = _eventListeners[eventName];
    if (listeners != null) {
      // Safe iteration: create a copy to avoid concurrent modification
      final listenersCopy = List<ChannelEventListener>.from(listeners);
      for (final listener in listenersCopy) {
        listener(eventName, data);
      }
    }
  }

  /// Handles subscription success confirmation.
  void handleSubscriptionSucceeded() {
    _setState(ChannelState.subscribed);
  }

  /// Handles unsubscription confirmation.
  void handleUnsubscriptionSucceeded() {
    _setState(ChannelState.unsubscribed);
    _clearEventListeners();
  }

  /// Clears all event listeners and closes the event stream controller.
  void _clearEventListeners() {
    _eventListeners.clear();
  }

  /// Closes the event stream controller.
  ///
  /// This method should be called when the channel is being disposed
  /// to prevent memory leaks.
  void dispose() {
    _eventStreamController.close();
  }

  /// Sets the channel state and notifies listeners.
  void _setState(ChannelState newState) {
    if (_state != newState) {
      _state = newState;
      // Safe iteration: create a copy to avoid concurrent modification
      final stateListenersCopy = List<ChannelStateListener>.from(_stateListeners);
      for (final listener in stateListenersCopy) {
        listener(newState);
      }
    }
  }

  /// Encodes a message to JSON string.
  String _encodeMessage(Map<String, dynamic> message) {
    return jsonEncode(message);
  }

  /// Sends a message through the WebSocket channel.
  /// This is a protected method that can be used by subclasses.
  @protected
  void sendMessage(String message) {
    _sendMessage(message);
  }

  /// Sets the channel state and notifies listeners.
  /// This is a protected method that can be used by subclasses.
  @protected
  void setState(ChannelState newState) {
    _setState(newState);
  }
}
