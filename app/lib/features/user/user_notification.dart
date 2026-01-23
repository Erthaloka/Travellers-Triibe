import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// --- 1. THE SERVICE (Logic Layer) ---
class NotificationService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  /// Helper to add a notification from anywhere in the app
  void addNotification({
    required String title,
    required String body,
    required String orderId,
    required String category,
  }) {
    _notifications.insert(0, {
      'id': DateTime.now().toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now(),
      'orderId': orderId,
      'category': category,
      'isRead': false,
    });
    notifyListeners();
  }

  void markAsRead(int index) {
    _notifications[index]['isRead'] = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }
}

// Global instance
final notificationService = NotificationService();

// --- 2. THE PAGE (UI Layer) ---
class UserNotificationsPage extends StatefulWidget {
  const UserNotificationsPage({super.key});

  @override
  State<UserNotificationsPage> createState() => _UserNotificationsPageState();
}

class _UserNotificationsPageState extends State<UserNotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Rebuild UI when the service updates
    notificationService.addListener(_refresh);

    // MOCK DATA GENERATOR: Remove this if you don't want sample data on load
    if (notificationService.notifications.isEmpty) {
      _addMockData();
    }
  }

  @override
  void dispose() {
    notificationService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addMockData() {
    notificationService.addNotification(
      title: 'Payment Successful',
      body: 'You saved ₹60 at Spice Garden Restaurant.',
      orderId: 'ORD001',
      category: 'FOOD',
    );
    notificationService.addNotification(
      title: 'Stay Confirmed',
      body: 'Your booking at Hotel Sunrise is confirmed.',
      orderId: 'ORD002',
      category: 'STAY',
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = notificationService.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (list.any((n) => !n['isRead']))
            TextButton(
              onPressed: () => notificationService.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: list.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final item = list[index];
                return _buildNotificationCard(item, index);
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final bool isRead = item['isRead'];

    return Material(
      color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          notificationService.markAsRead(index);
          // Standard GoRouter navigation
          context.push('/user/orders/${item['orderId']}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getIcon(item['category'], isRead),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateTimeFormatter.formatRelative(item['timestamp']),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIcon(String category, bool isRead) {
    IconData iconData;
    Color iconColor;

    switch (category.toUpperCase()) {
      case 'FOOD':
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'STAY':
        iconData = Icons.hotel;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surfaceVariant : iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isRead ? AppColors.textHint : iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("We'll alert you when something happens!"),
        ],
      ),
    );
  }
}
