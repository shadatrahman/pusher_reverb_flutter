import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import '../services/reverb_service.dart';
import '../widgets/event_list_item.dart';

class PresenceChannelScreen extends StatefulWidget {
  const PresenceChannelScreen({super.key});

  @override
  State<PresenceChannelScreen> createState() => _PresenceChannelScreenState();
}

class _PresenceChannelScreenState extends State<PresenceChannelScreen> {
  final _reverbService = ReverbService.instance;
  final _channelNameController = TextEditingController(text: 'presence-chat-room');

  PresenceChannel? _channel;
  final List<ChannelEvent> _events = [];
  List<PresenceMember> _members = [];
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
      _members = [];
    });

    try {
      final channelName = _channelNameController.text.trim();

      // Validate that it starts with "presence-"
      if (!channelName.startsWith('presence-')) {
        setState(() {
          _error = 'Presence channel names must start with "presence-"';
          _isLoading = false;
        });
        return;
      }

      // Get or create the presence channel and subscribe (this will trigger authentication)
      _channel = _reverbService.client!.subscribeToPresenceChannel(channelName);

      // Get initial member list
      setState(() {
        _members = List.from(_channel!.members);
      });

      // Listen to all events via the stream API
      _channel!.stream.listen((event) {
        setState(() {
          _events.insert(0, event);

          // Update member list when members join/leave
          if (event.eventName == 'pusher:member_added' || event.eventName == 'pusher:member_removed') {
            _members = List.from(_channel!.members);
          }

          // Keep only the last 50 events
          if (_events.length > 50) {
            _events.removeLast();
          }
        });
      });

      // Also listen for specific presence events with callbacks
      _channel!.bind('pusher:member_added', (event, data) {
        print('Member added: $data');
      });

      _channel!.bind('pusher:member_removed', (event, data) {
        print('Member removed: $data');
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
          _members = [];
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
        title: const Text('Presence Channels'),
        elevation: 0,
        actions: [if (_isSubscribed) IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear Events', onPressed: _clearEvents)],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.people, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Presence Channels', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Track who is subscribed to the channel', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
                        Text('About Presence Channels', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Channel names must start with "presence-"\n'
                      '• Requires authentication like private channels\n'
                      '• Track all subscribed members in real-time\n'
                      '• Get member_added and member_removed events\n'
                      '• Perfect for chat rooms and collaborative features',
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
                  decoration: const InputDecoration(labelText: 'Presence Channel Name', hintText: 'presence-chat-room', prefixIcon: Icon(Icons.tag), helperText: 'Must start with "presence-"'),
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

          // Members List
          if (_isSubscribed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  Text('Online Members', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${_members.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: _members.isEmpty
                    ? const Center(child: Text('No members online'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(member.id.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text('User ${member.id}'),
                            subtitle: Text(member.info.toString(), style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Events List Header
          if (_isSubscribed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.stream, size: 20),
                  const SizedBox(width: 8),
                  Text('Presence Events', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
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
                              Text('Waiting for presence events...', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              const SizedBox(height: 8),
                              Text('Events will appear when members join/leave', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4))),
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
                        Icon(Icons.people_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('Subscribe to see online members', style: theme.textTheme.titleMedium),
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
