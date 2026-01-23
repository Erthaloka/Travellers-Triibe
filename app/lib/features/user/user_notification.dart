import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/api_endpoints.dart';

// --- 1. THE SERVICE (Logic Layer) ---
class NotificationService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch real notifications from backend
  Future<void> fetchNotifications(dynamic apiClient) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiEndpoints.userNotifications);
      if (response.success && response.data != null) {
        _notifications.clear();
        _notifications.addAll(List<Map<String, dynamic>>.from(response.data));
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
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

    // ✅ FIXED: Using addPostFrameCallback ensures we fetch data
    // ONLY after the build phase is complete, preventing the setState error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      notificationService.fetchNotifications(authProvider.apiClient);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationService,
      builder: (context, _) {
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
          body: notificationService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () {
                    final authProvider = context.read<AuthProvider>();
                    return notificationService.fetchNotifications(
                      authProvider.apiClient,
                    );
                  },
                  child: list.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(list[index], index);
                          },
                        ),
                ),
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final bool isRead = item['isRead'] ?? false;

    return Material(
      color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          notificationService.markAsRead(index);
          context.push('/user/orders/${item['orderId']}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getIcon(item['category'] ?? 'OTHER', isRead),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Notification',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateTimeFormatter.formatRelative(
                        item['timestamp'] is String
                            ? DateTime.parse(item['timestamp'])
                            : item['timestamp'],
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
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
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text("We'll alert you when something happens!"),
            ],
          ),
        ),
      ),
    );
  }
}
