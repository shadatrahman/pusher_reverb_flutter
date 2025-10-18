import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import '../services/reverb_service.dart';
import '../widgets/event_list_item.dart';

class PublicChannelScreen extends StatefulWidget {
  const PublicChannelScreen({super.key});

  @override
  State<PublicChannelScreen> createState() => _PublicChannelScreenState();
}

class _PublicChannelScreenState extends State<PublicChannelScreen> {
  final _reverbService = ReverbService.instance;
  final _channelNameController = TextEditingController(text: 'notifications');
  final _eventNameController = TextEditingController(text: 'message');

  Channel? _channel;
  final List<ChannelEvent> _events = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  String? _error;

  // For the callback API demo
  final List<String> _callbackMessages = [];

  @override
  void dispose() {
    _channelNameController.dispose();
    _eventNameController.dispose();
    _unsubscribe();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (_reverbService.client == null) {
      setState(() {
        _error = 'Please connect to the server first from the Home screen';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _events.clear();
      _callbackMessages.clear();
    });

    try {
      final channelName = _channelNameController.text.trim();

      // Get or create the channel and subscribe
      _channel = _reverbService.client!.subscribeToChannel(channelName);

      // Listen to ALL events via the stream API
      _channel!.stream.listen((event) {
        setState(() {
          _events.insert(0, event);
          // Keep only the last 50 events
          if (_events.length > 50) {
            _events.removeLast();
          }
        });
      });

      // Also demonstrate the callback API for a specific event
      final eventName = _eventNameController.text.trim();
      if (eventName.isNotEmpty) {
        _channel!.bind(eventName, (event, data) {
          setState(() {
            _callbackMessages.insert(0, 'Callback received: $event - $data');
            if (_callbackMessages.length > 10) {
              _callbackMessages.removeLast();
            }
          });
        });
      }

      setState(() {
        _isSubscribed = true;
        _isLoading = false;
      });
    } on InvalidChannelNameException catch (e) {
      setState(() {
        _error = 'Invalid channel name: ${e.message}';
        _isLoading = false;
      });
    } on ChannelException catch (e) {
      setState(() {
        _error = 'Channel error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _unsubscribe() async {
    if (_channel != null) {
      try {
        await _channel!.unsubscribe();
        setState(() {
          _isSubscribed = false;
          _channel = null;
        });
      } catch (e) {
        setState(() {
          _error = 'Error unsubscribing: $e';
        });
      }
    }
  }

  void _clearEvents() {
    setState(() {
      _events.clear();
      _callbackMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Channels'),
        elevation: 0,
        actions: [if (_isSubscribed) IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear Events', onPressed: _clearEvents)],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.public, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Public Channels', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Open channels accessible to anyone', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Configuration Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _channelNameController,
                  decoration: const InputDecoration(labelText: 'Channel Name', hintText: 'notifications', prefixIcon: Icon(Icons.tag), helperText: 'Enter a public channel name'),
                  enabled: !_isSubscribed,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name (for callback demo)',
                    hintText: 'message',
                    prefixIcon: Icon(Icons.event),
                    helperText: 'Optional: specific event for callback API',
                  ),
                  enabled: !_isSubscribed,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _isSubscribed
                        ? _unsubscribe
                        : _subscribe,
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isSubscribed ? Icons.cancel : Icons.play_arrow),
                    label: Text(
                      _isLoading
                          ? 'Subscribing...'
                          : _isSubscribed
                          ? 'Unsubscribe'
                          : 'Subscribe',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Callback Messages Section
          if (_callbackMessages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 20),
                  const SizedBox(width: 8),
                  Text('Callback API Events', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${_callbackMessages.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _callbackMessages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(_callbackMessages[index], style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                    );
                  },
                ),
              ),
            ),
          ],

          // Events List Header
          if (_isSubscribed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.stream, size: 20),
                  const SizedBox(width: 8),
                  Text('Stream API Events', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${_events.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Events List
          Expanded(
            child: _isSubscribed
                ? _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text('Waiting for events...', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              const SizedBox(height: 8),
                              Text('Events will appear here when received', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            return EventListItem(event: _events[index]);
                          },
                        )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('Subscribe to start receiving events', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
