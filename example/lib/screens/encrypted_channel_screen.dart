import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import '../services/reverb_service.dart';
import '../widgets/event_list_item.dart';

class EncryptedChannelScreen extends StatefulWidget {
  const EncryptedChannelScreen({super.key});

  @override
  State<EncryptedChannelScreen> createState() => _EncryptedChannelScreenState();
}

class _EncryptedChannelScreenState extends State<EncryptedChannelScreen> {
  final _reverbService = ReverbService.instance;
  final _channelNameController = TextEditingController(text: 'private-encrypted-messages');
  final _encryptionKeyController = TextEditingController(text: 'your-32-byte-base64-encoded-key');

  EncryptedChannel? _channel;
  final List<ChannelEvent> _events = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  bool _showEncryptionKey = false;
  String? _error;
  int _decryptionErrors = 0;

  @override
  void dispose() {
    _channelNameController.dispose();
    _encryptionKeyController.dispose();
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
      _decryptionErrors = 0;
    });

    try {
      final channelName = _channelNameController.text.trim();
      final encryptionKey = _encryptionKeyController.text.trim();

      // Validate that it starts with "private-encrypted-"
      if (!channelName.startsWith('private-encrypted-')) {
        setState(() {
          _error = 'Encrypted channel names must start with "private-encrypted-"';
          _isLoading = false;
        });
        return;
      }

      if (encryptionKey.isEmpty) {
        setState(() {
          _error = 'Encryption key is required';
          _isLoading = false;
        });
        return;
      }

      // Get or create the encrypted channel
      _channel = _reverbService.client!.encryptedChannel(channelName, encryptionMasterKey: encryptionKey);

      // Subscribe to the channel (this will trigger authentication)
      await _channel!.subscribe();

      // Listen to all events via the stream API
      _channel!.stream.listen((event) {
        setState(() {
          _events.insert(0, event);

          // Track decryption errors
          if (event.eventName == 'pusher:decryption_error') {
            _decryptionErrors++;
          }

          // Keep only the last 50 events
          if (_events.length > 50) {
            _events.removeLast();
          }
        });
      });

      // Listen for decryption errors specifically
      _channel!.bind('pusher:decryption_error', (event, data) {
        debugPrint('Decryption error: $data');
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
      _decryptionErrors = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Channels'),
        elevation: 0,
        actions: [if (_isSubscribed) IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear Events', onPressed: _clearEvents)],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.enhanced_encryption, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Encrypted Channels', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('End-to-end encrypted with AES-256', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Security Warning
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.amber.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Text('Security Best Practices', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Never hardcode encryption keys in production\n'
                              '• Fetch keys from your secure backend API\n'
                              '• Use Flutter Secure Storage for persistence\n'
                              '• Always use HTTPS when fetching keys\n'
                              '• Rotate keys regularly',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
                                const SizedBox(width: 8),
                                Text('About Encrypted Channels', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Channel names must start with "private-encrypted-"\n'
                              '• Requires authentication and encryption key\n'
                              '• Uses AES-256-CBC encryption\n'
                              '• Events are automatically decrypted\n'
                              '• Decryption errors emit pusher:decryption_error',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Configuration Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _channelNameController,
                          decoration: const InputDecoration(
                            labelText: 'Encrypted Channel Name',
                            hintText: 'private-encrypted-messages',
                            prefixIcon: Icon(Icons.tag),
                            helperText: 'Must start with "private-encrypted-"',
                          ),
                          enabled: !_isSubscribed,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _encryptionKeyController,
                          decoration: InputDecoration(
                            labelText: 'Encryption Master Key',
                            hintText: 'your-32-byte-base64-encoded-key',
                            prefixIcon: const Icon(Icons.vpn_key),
                            helperText: 'Base64-encoded 32-byte encryption key',
                            suffixIcon: IconButton(
                              icon: Icon(_showEncryptionKey ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _showEncryptionKey = !_showEncryptionKey;
                                });
                              },
                            ),
                          ),
                          obscureText: !_showEncryptionKey,
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

                  // Decryption Status
                  if (_isSubscribed && _decryptionErrors > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: Colors.orange.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Decryption errors: $_decryptionErrors\n'
                                  'Check that your encryption key matches the server',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Events List Header
                  if (_isSubscribed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.stream, size: 20),
                          const SizedBox(width: 8),
                          Text('Encrypted Events', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              '${_events.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Events List
                  if (_isSubscribed)
                    _events.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text('Waiting for encrypted events...', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                Text(
                                  'Encrypted events will be automatically decrypted',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: _events.map((event) => EventListItem(event: event)).toList()),
                          )
                  else
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.enhanced_encryption, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Subscribe to receive encrypted events', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(
                            'Events are automatically decrypted using your key',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
