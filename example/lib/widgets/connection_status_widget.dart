import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart' as reverb;

class ConnectionStatusWidget extends StatelessWidget {
  final reverb.ReverbClient client;

  const ConnectionStatusWidget({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<reverb.ConnectionState>(
      stream: client.onConnectionStateChange,
      initialData: reverb.ConnectionState.disconnected,
      builder: (context, snapshot) {
        final state = snapshot.data ?? reverb.ConnectionState.disconnected;

        Color statusColor;
        IconData statusIcon;
        String statusText;
        String statusDescription;

        switch (state) {
          case reverb.ConnectionState.connecting:
            statusColor = Colors.orange;
            statusIcon = Icons.sync;
            statusText = 'Connecting';
            statusDescription = 'Establishing connection to server...';
            break;
          case reverb.ConnectionState.connected:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Connected';
            final socketId = client.socketId ?? "N/A";
            final clusterInfo = client.isUsingCluster ? ' (Cluster: ${client.cluster})' : '';
            statusDescription = 'Socket ID: $socketId$clusterInfo';
            break;
          case reverb.ConnectionState.reconnecting:
            statusColor = Colors.amber;
            statusIcon = Icons.refresh;
            statusText = 'Reconnecting';
            statusDescription = 'Attempting to restore connection...';
            break;
          case reverb.ConnectionState.disconnected:
            statusColor = Colors.grey;
            statusIcon = Icons.cloud_off;
            statusText = 'Disconnected';
            statusDescription = 'Not connected to server';
            break;
          case reverb.ConnectionState.error:
            statusColor = Colors.red;
            statusIcon = Icons.error;
            statusText = 'Error';
            statusDescription = 'Connection error occurred';
            break;
        }

        return Card(
          color: statusColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Icon(statusIcon, color: statusColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Connection Status', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: statusColor),
                          ),
                          const SizedBox(height: 2),
                          Text(statusDescription, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
