import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import '../services/reverb_service.dart';
import '../widgets/event_list_item.dart';

class PrivateChannelScreen extends StatefulWidget {
  const PrivateChannelScreen({super.key});

  @override
  State<PrivateChannelScreen> createState() => _PrivateChannelScreenState();
}

class _PrivateChannelScreenState extends State<PrivateChannelScreen> {
  final _reverbService = ReverbService.instance;
  final _channelNameController = TextEditingController(text: 'private-user-123');

  PrivateChannel? _channel;
  final List<ChannelEvent> _events = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _channelNameController.dispose();
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
    });

    try {
      final channelName = _channelNameController.text.trim();

      // Validate that it starts with "private-"
      if (!channelName.startsWith('private-')) {
        setState(() {
          _error = 'Private channel names must start with "private-"';
          _isLoading = false;
        });
        return;
      }

      // Get or create the private channel and subscribe (this will trigger authentication)
      _channel = _reverbService.client!.subscribeToPrivateChannel(channelName);

      // Listen to all events via the stream API
      _channel!.stream.listen((event) {
        setState(() {
          _events.insert(0, event);
          // Keep only the last 50 events
          if (_events.length > 50) {
            _events.removeLast();
          }
        });
      });

      setState(() {
        _isSubscribed = true;
        _isLoading = false;
      });
    } on AuthenticationException catch (e) {
      setState(() {
        _error =
            'Authentication failed: ${e.message}\n'
            'Status: ${e.statusCode}\n'
            'Make sure your auth token is configured in Settings';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Channels'),
        elevation: 0,
        actions: [if (_isSubscribed) IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear Events', onPressed: _clearEvents)],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.lock, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Private Channels', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Secure channels requiring authentication', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text('About Private Channels', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Channel names must start with "private-"\n'
                      '• Requires authentication with your Laravel backend\n'
                      '• Configure auth token in Settings\n'
                      '• Backend must authorize the subscription',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Configuration Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _channelNameController,
                  decoration: const InputDecoration(labelText: 'Private Channel Name', hintText: 'private-user-123', prefixIcon: Icon(Icons.tag), helperText: 'Must start with "private-"'),
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
                          ? 'Authenticating...'
                          : _isSubscribed
                          ? 'Unsubscribe'
                          : 'Subscribe',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

          // Events List Header
          if (_isSubscribed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.stream, size: 20),
                  const SizedBox(width: 8),
                  Text('Private Events', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
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
                              Text('Waiting for private events...', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              const SizedBox(height: 8),
                              Text('Private events will appear here when received', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
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
                        Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('Subscribe to start receiving events', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Ensure authentication is configured', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
