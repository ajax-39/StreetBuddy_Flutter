import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PushNotificationDetailScreen extends StatefulWidget {
  final String? notificationData;

  const PushNotificationDetailScreen({
    super.key,
    this.notificationData,
  });

  @override
  State<PushNotificationDetailScreen> createState() =>
      _PushNotificationDetailScreenState();
}

class _PushNotificationDetailScreenState
    extends State<PushNotificationDetailScreen> {
  Map<String, dynamic>? _parsedData;

  @override
  void initState() {
    super.initState();
    _parseNotificationData();
  }

  void _parseNotificationData() {
    if (widget.notificationData != null) {
      try {
        _parsedData = jsonDecode(widget.notificationData!);
      } catch (e) {
        debugPrint('Error parsing notification data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildNotificationContent(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Push Notification',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Received: ${DateTime.now().toString().split('.')[0]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    if (_parsedData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('No notification data available.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._parsedData!.entries
                .map((entry) => _buildDataRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_parsedData == null) return const SizedBox.shrink();

    final type = _parsedData!['type'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(type),
      ],
    );
  }

  Widget _buildActionButton(String? type) {
    switch (type) {
      case 'chat':
        return ElevatedButton.icon(
          onPressed: () => _navigateToChat(),
          icon: const Icon(Icons.chat),
          label: const Text('Open Chat'),
        );
      case 'post':
        return ElevatedButton.icon(
          onPressed: () => _navigateToPost(),
          icon: const Icon(Icons.article),
          label: const Text('View Post'),
        );
      case 'location':
        return ElevatedButton.icon(
          onPressed: () => _navigateToLocation(),
          icon: const Icon(Icons.location_on),
          label: const Text('View Location'),
        );
      default:
        return ElevatedButton.icon(
          onPressed: () => _navigateToNotifications(),
          icon: const Icon(Icons.notifications),
          label: const Text('View All Notifications'),
        );
    }
  }

  void _navigateToChat() {
    final chatId = _parsedData?['chatId'];
    if (chatId != null) {
      // Navigate to chat screen
      context.go('/messages'); // Adjust route as needed
    }
  }

  void _navigateToPost() {
    final postId = _parsedData?['postId'];
    if (postId != null) {
      // Navigate to post detail screen
      context.go('/post-detail/$postId'); // Adjust route as needed
    }
  }

  void _navigateToLocation() {
    final locationId = _parsedData?['locationId'];
    if (locationId != null) {
      // Navigate to location detail screen
      context.go('/location-detail/$locationId'); // Adjust route as needed
    }
  }

  void _navigateToNotifications() {
    context.go('/notif');
  }
}
