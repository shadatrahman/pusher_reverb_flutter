import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'dart:convert';

class EventListItem extends StatelessWidget {
  final ChannelEvent event;

  const EventListItem({super.key, required this.event});

  Color _getEventColor(String eventName) {
    if (eventName.startsWith('pusher:')) {
      return Colors.blue;
    } else if (eventName.contains('error')) {
      return Colors.red;
    } else if (eventName.contains('member')) {
      return Colors.green;
    } else {
      return Colors.purple;
    }
  }

  IconData _getEventIcon(String eventName) {
    if (eventName == 'pusher:subscription_succeeded') {
      return Icons.check_circle;
    } else if (eventName == 'pusher:member_added') {
      return Icons.person_add;
    } else if (eventName == 'pusher:member_removed') {
      return Icons.person_remove;
    } else if (eventName.contains('error') || eventName.contains('decryption_error')) {
      return Icons.error;
    } else if (eventName.startsWith('pusher:')) {
      return Icons.info;
    } else {
      return Icons.message;
    }
  }

  String _formatData(dynamic data) {
    try {
      if (data is String) {
        // Try to parse as JSON for pretty printing
        try {
          final decoded = jsonDecode(data);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return data;
        }
      } else if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      } else {
        return data.toString();
      }
    } catch (e) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventColor = _getEventColor(event.eventName);
    final eventIcon = _getEventIcon(event.eventName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: eventColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(eventIcon, color: eventColor, size: 20),
        ),
        title: Text(event.eventName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('Channel: ${event.channelName}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Data:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: SelectableText(_formatData(event.data), style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
