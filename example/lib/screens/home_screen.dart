import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart' as reverb;
import '../services/reverb_service.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/channel_demo_card.dart';
import 'public_channel_screen.dart';
import 'private_channel_screen.dart';
import 'presence_channel_screen.dart';
import 'encrypted_channel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _reverbService = ReverbService.instance;
  bool _isConnecting = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    if (!_reverbService.isInitialized) {
      await _reverbService.initialize();
    }
  }

  Future<void> _toggleConnection() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      final client = _reverbService.client;
      if (client != null) {
        // Check current state
        final isConnected = await _isClientConnected();

        if (isConnected) {
          _reverbService.disconnect();
        } else {
          await _reverbService.connect();
        }
      } else {
        await _reverbService.initialize();
        await _reverbService.connect();
      }
    } on reverb.ConnectionException catch (e) {
      setState(() {
        _connectionError = 'Connection failed: ${e.message}';
      });
    } on reverb.PusherException catch (e) {
      setState(() {
        _connectionError = 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _connectionError = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<bool> _isClientConnected() async {
    // Check if client has a socket ID (indicates connected)
    return _reverbService.client?.socketId != null;
  }

  void _navigateToDemo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pusher Reverb Flutter'), elevation: 0, centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeConnection();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_queue, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Real-time Communication',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect to Laravel Reverb server and explore '
                        'various channel types',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Connection Status
              if (_reverbService.client != null) ConnectionStatusWidget(client: _reverbService.client!),

              const SizedBox(height: 16),

              // Connection Error
              if (_connectionError != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_connectionError!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Connect/Disconnect Button
              ElevatedButton.icon(
                onPressed: _isConnecting ? null : _toggleConnection,
                icon: _isConnecting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.power_settings_new),
                label: Text(
                  _isConnecting
                      ? 'Connecting...'
                      : _reverbService.client?.socketId != null
                      ? 'Disconnect'
                      : 'Connect to Server',
                ),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),

              const SizedBox(height: 32),

              // Section Title
              Text('Channel Types', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),

              const SizedBox(height: 16),

              // Channel Demo Cards
              ChannelDemoCard(
                title: 'Public Channels',
                description:
                    'Open channels accessible to anyone. '
                    'Perfect for broadcasting public information.',
                icon: Icons.public,
                color: Colors.blue,
                onTap: () => _navigateToDemo(context, const PublicChannelScreen()),
              ),

              const SizedBox(height: 12),

              ChannelDemoCard(
                title: 'Private Channels',
                description:
                    'Secure channels requiring authentication. '
                    'Ideal for user-specific data.',
                icon: Icons.lock,
                color: Colors.orange,
                onTap: () => _navigateToDemo(context, const PrivateChannelScreen()),
              ),

              const SizedBox(height: 12),

              ChannelDemoCard(
                title: 'Presence Channels',
                description:
                    'Track who is subscribed to the channel. '
                    'Great for chat rooms and collaborative features.',
                icon: Icons.people,
                color: Colors.green,
                onTap: () => _navigateToDemo(context, const PresenceChannelScreen()),
              ),

              const SizedBox(height: 12),

              ChannelDemoCard(
                title: 'Encrypted Channels',
                description:
                    'End-to-end encrypted channels with AES-256. '
                    'Maximum security for sensitive data.',
                icon: Icons.enhanced_encryption,
                color: Colors.purple,
                onTap: () => _navigateToDemo(context, const EncryptedChannelScreen()),
              ),

              const SizedBox(height: 32),

              // Info Card
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Quick Tips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('1. Configure your server settings in the Settings tab', theme),
                      _buildTip('2. Connect to the server before exploring channels', theme),
                      _buildTip('3. Each demo shows both callback and stream-based APIs', theme),
                      _buildTip('4. Check the console logs for detailed events', theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Note: We don't disconnect here as the service is shared
    super.dispose();
  }
}
