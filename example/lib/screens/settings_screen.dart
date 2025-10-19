import 'package:flutter/material.dart';
import '../services/reverb_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reverbService = ReverbService.instance;

  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _appKeyController;
  late TextEditingController _authEndpointController;
  late TextEditingController _wsPathController;
  late TextEditingController _authTokenController;

  // NEW: API key and cluster controllers
  late TextEditingController _apiKeyController;
  late TextEditingController _clusterController;

  bool _isSaving = false;
  bool _showAuthToken = false;
  bool _showApiKey = false;
  bool _useTLS = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final config = _reverbService.configuration;
    _hostController = TextEditingController(text: config['host']);
    _portController = TextEditingController(text: config['port'].toString());
    _appKeyController = TextEditingController(text: config['appKey']);
    _authEndpointController = TextEditingController(text: config['authEndpoint']);
    _wsPathController = TextEditingController(text: config['wsPath']);
    _authTokenController = TextEditingController(text: config['authToken']);

    // NEW: Load API key and cluster
    _apiKeyController = TextEditingController(text: config['apiKey'] ?? '');
    _clusterController = TextEditingController(text: config['cluster'] ?? '');

    _useTLS = config['useTLS'] ?? false;
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _reverbService.saveConfiguration(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        appKey: _appKeyController.text.trim(),
        authEndpoint: _authEndpointController.text.trim(),
        wsPath: _wsPathController.text.trim(),
        authToken: _authTokenController.text.trim(),
        useTLS: _useTLS,
        apiKey: _apiKeyController.text.trim().isNotEmpty ? _apiKeyController.text.trim() : null, // NEW
        cluster: _clusterController.text.trim().isNotEmpty ? _clusterController.text.trim() : null, // NEW
      );

      // Reinitialize the client with new configuration
      await _reverbService.reinitialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _hostController.text = 'localhost';
                _portController.text = '8080';
                _appKeyController.text = 'your-app-key';
                _authEndpointController.text = 'http://localhost:8000/broadcasting/auth';
                _wsPathController.text = '/';
                _authTokenController.text = '';
                _apiKeyController.text = ''; // NEW
                _clusterController.text = ''; // NEW
                _useTLS = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset to Defaults', onPressed: _resetToDefaults)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Server Configuration', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Configure your Laravel Reverb server connection', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Connection Settings Section
            Text('Connection Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(labelText: 'Host', hintText: 'localhost', prefixIcon: Icon(Icons.dns), helperText: 'Reverb server hostname or IP address'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Host is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(labelText: 'Port', hintText: '8080', prefixIcon: Icon(Icons.settings_ethernet), helperText: 'Reverb server port number'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Port is required';
                        }
                        final port = int.tryParse(value.trim());
                        if (port == null || port < 1 || port > 65535) {
                          return 'Invalid port number (1-65535)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _appKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Application Key',
                        hintText: 'your-app-key',
                        prefixIcon: Icon(Icons.key),
                        helperText: 'Application key from your Reverb configuration',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Application key is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wsPathController,
                      decoration: const InputDecoration(labelText: 'WebSocket Path', hintText: '/', prefixIcon: Icon(Icons.route), helperText: 'Custom WebSocket path (usually "/")'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'WebSocket path is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Use TLS/SSL (wss://)'),
                      subtitle: Text(_useTLS ? 'Secure WebSocket connection (wss://)' : 'Standard WebSocket connection (ws://)'),
                      value: _useTLS,
                      onChanged: (value) {
                        setState(() {
                          _useTLS = value;
                        });
                      },
                      secondary: Icon(_useTLS ? Icons.lock : Icons.lock_open),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key (Optional)',
                        hintText: 'your-api-key',
                        prefixIcon: const Icon(Icons.vpn_key),
                        helperText: 'Optional: API key for authentication',
                        suffixIcon: IconButton(
                          icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showApiKey = !_showApiKey;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showApiKey,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clusterController,
                      decoration: const InputDecoration(
                        labelText: 'Cluster (Optional)',
                        hintText: 'us-east-1',
                        prefixIcon: Icon(Icons.cloud),
                        helperText: 'Optional: Predefined cluster configuration (us-east-1, eu-west-1, local, etc.)',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Authentication Settings Section
            Text('Authentication Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _authEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'Auth Endpoint',
                        hintText: 'http://localhost:8000/broadcasting/auth',
                        prefixIcon: Icon(Icons.verified_user),
                        helperText: 'Laravel broadcasting authentication endpoint',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Auth endpoint is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authTokenController,
                      decoration: InputDecoration(
                        labelText: 'Auth Token (Optional)',
                        hintText: 'Bearer token for authentication',
                        prefixIcon: const Icon(Icons.token),
                        helperText: 'Optional: Bearer token for private channels',
                        suffixIcon: IconButton(
                          icon: Icon(_showAuthToken ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showAuthToken = !_showAuthToken;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showAuthToken,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Setup Guide', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Install Laravel Reverb in your Laravel app:\n'
                      '   php artisan install:broadcasting\n\n'
                      '2. Start Reverb server:\n'
                      '   php artisan reverb:start\n\n'
                      '3. Update the host and port above to match your setup\n\n'
                      '4. For authentication, provide a valid Bearer token\n\n'
                      '5. NEW: Use API Key for enhanced authentication\n\n'
                      '6. NEW: Use Cluster for predefined configurations\n'
                      '   Available: us-east-1, eu-west-1, local, staging',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfiguration,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _appKeyController.dispose();
    _authEndpointController.dispose();
    _wsPathController.dispose();
    _authTokenController.dispose();
    _apiKeyController.dispose(); // NEW
    _clusterController.dispose(); // NEW
    super.dispose();
  }
}
