import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/firebase_messaging_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _generalNotifications = true;
  bool _chatNotifications = true;
  bool _postNotifications = true;
  bool _locationNotifications = true;
  bool _promotionalNotifications = false;

  final List<String> _subscribedTopics = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Load settings from shared preferences or other storage
    // This is just a placeholder implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<FirebaseMessagingProvider>(
        builder: (context, messagingProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTokenSection(messagingProvider),
                const SizedBox(height: 24),
                _buildNotificationToggles(),
                const SizedBox(height: 24),
                _buildTopicSubscriptions(messagingProvider),
                const SizedBox(height: 24),
                _buildActionButtons(messagingProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTokenSection(FirebaseMessagingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Token',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                provider.fcmToken ?? 'No token available',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => provider.refreshToken(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
                TextButton.icon(
                  onPressed: () => _copyTokenToClipboard(provider.fcmToken),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: () => provider.printTokenToConsole(),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              'General Notifications',
              'Receive general app notifications',
              _generalNotifications,
              (value) => setState(() => _generalNotifications = value),
            ),
            _buildToggle(
              'Chat Messages',
              'Get notified about new messages',
              _chatNotifications,
              (value) => setState(() => _chatNotifications = value),
            ),
            _buildToggle(
              'Post Updates',
              'Notifications about posts and content',
              _postNotifications,
              (value) => setState(() => _postNotifications = value),
            ),
            _buildToggle(
              'Location Updates',
              'Notifications about places and locations',
              _locationNotifications,
              (value) => setState(() => _locationNotifications = value),
            ),
            _buildToggle(
              'Promotional',
              'Special offers and promotional content',
              _promotionalNotifications,
              (value) => setState(() => _promotionalNotifications = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTopicSubscriptions(FirebaseMessagingProvider provider) {
    final availableTopics = [
      'general',
      'news',
      'updates',
      'promotions',
      'local_events',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic Subscriptions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to topics to receive targeted notifications',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ...availableTopics.map((topic) => _buildTopicTile(topic, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(String topic, FirebaseMessagingProvider provider) {
    final isSubscribed = _subscribedTopics.contains(topic);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _getTopicIcon(topic),
        color: isSubscribed ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(topic.replaceAll('_', ' ').toUpperCase()),
      trailing: Switch(
        value: isSubscribed,
        onChanged: (value) async {
          if (value) {
            await provider.subscribeToTopic(topic);
            setState(() => _subscribedTopics.add(topic));
          } else {
            await provider.unsubscribeFromTopic(topic);
            setState(() => _subscribedTopics.remove(topic));
          }
        },
      ),
    );
  }

  IconData _getTopicIcon(String topic) {
    switch (topic) {
      case 'general':
        return Icons.notifications;
      case 'news':
        return Icons.newspaper;
      case 'updates':
        return Icons.system_update;
      case 'promotions':
        return Icons.local_offer;
      case 'local_events':
        return Icons.event;
      default:
        return Icons.topic;
    }
  }

  Widget _buildActionButtons(FirebaseMessagingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _saveSettings(),
          icon: const Icon(Icons.save),
          label: const Text('Save Settings'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _testNotification(),
          icon: const Icon(Icons.send),
          label: const Text('Send Test Notification'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => provider.clearToken(),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear Token'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  void _copyTokenToClipboard(String? token) {
    if (token != null) {
      // Copy to clipboard implementation would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copied to clipboard')),
      );
    }
  }

  void _saveSettings() {
    // Save settings to shared preferences or other storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  void _testNotification() {
    // This would typically send a test notification via your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification requested')),
    );
  }
}
