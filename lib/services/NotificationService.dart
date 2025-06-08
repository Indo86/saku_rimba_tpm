import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../models/notification.dart' as app_notification;

class NotificationService {
  static const String _notificationsBox = 'notifications';
  static const int _maxNotifications = 500;

  /// Initialize notification service
  static Future<void> init() async {
    try {
      print('🔔 Initializing NotificationService...');
      
      // Create some sample notifications for demo
      await _createSampleNotifications();
      
      print('✅ NotificationService initialized');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  /// Create a new notification
  static Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final notification = app_notification.Notification(
        id: id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      // Get existing notifications
      final notifications = await getAllNotifications();
      
      // Add new notification at the beginning
      notifications.insert(0, notification);
      
      // Limit the number of notifications
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }
      
      // Save notifications
      await _saveNotifications(notifications);
      
      print('✅ Notification created: $title');
      return id;
    } catch (e) {
      print('❌ Error creating notification: $e');
      return null;
    }
  }

  /// Get all notifications for current user
static Future<List<app_notification.Notification>> getAllNotifications() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return [];

      final List<dynamic> notificationsData =
          await HiveService.getSetting<List<dynamic>>(_notificationsBox) ?? [];

      final List<app_notification.Notification> notifications = [];
      for (var raw in notificationsData) {
        final map = Map<String, dynamic>.from(raw as Map);
        final notif = app_notification.Notification.fromMap(map);
        if (notif.userId == userId) {
          notifications.add(notif);
        }
      }

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getAllNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final allNotifications = await _getAllNotificationsFromStorage();
      
      final index = allNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        allNotifications[index] = allNotifications[index].copyWith(isRead: true);
        await _saveNotifications(allNotifications);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for current user
  static Future<bool> markAllAsRead() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return false;
      
      final allNotifications = await _getAllNotificationsFromStorage();
      
      bool hasChanges = false;
      for (int i = 0; i < allNotifications.length; i++) {
        if (allNotifications[i].userId == userId && !allNotifications[i].isRead) {
          allNotifications[i] = allNotifications[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await _saveNotifications(allNotifications);
      }
      
      return hasChanges;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final allNotifications = await _getAllNotificationsFromStorage();
      
      final initialLength = allNotifications.length;
      allNotifications.removeWhere((n) => n.id == notificationId);
      
      if (allNotifications.length < initialLength) {
        await _saveNotifications(allNotifications);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications for current user
  static Future<bool> deleteAllNotifications() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return false;
      
      final allNotifications = await _getAllNotificationsFromStorage();
      
      final initialLength = allNotifications.length;
      allNotifications.removeWhere((n) => n.userId == userId);
      
      if (allNotifications.length < initialLength) {
        await _saveNotifications(allNotifications);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      return false;
    }
  }

  /// Cleanup old notifications (keep only recent ones)
  static Future<void> cleanupOldNotifications() async {
    try {
      final allNotifications = await _getAllNotificationsFromStorage();
      
      if (allNotifications.length > _maxNotifications) {
        // Sort by creation date and keep only the most recent
        allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentNotifications = allNotifications.take(_maxNotifications).toList();
        
        await _saveNotifications(recentNotifications);
        
        final removedCount = allNotifications.length - recentNotifications.length;
        print('🧹 Cleaned up $removedCount old notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }

  /// Cancel all notifications (for app shutdown)
  static Future<void> cancelAllNotifications() async {
    try {
      // In a real app, this would cancel scheduled notifications
      print('🔕 All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// Get notifications by type
  static Future<List<app_notification.Notification>> getNotificationsByType(String type) async {
    try {
      final notifications = await getAllNotifications();
      return notifications.where((n) => n.type == type).toList();
    } catch (e) {
      print('❌ Error getting notifications by type: $e');
      return [];
    }
  }

  /// Private helper methods
  
  /// Get all notifications from storage (for all users)
  /// Get all notifications from storage (for all users)
  static Future<List<app_notification.Notification>> _getAllNotificationsFromStorage() async {
    try {
      final List<dynamic> notificationsData =
          await HiveService.getSetting<List<dynamic>>(_notificationsBox) ?? [];

      final List<app_notification.Notification> notifications = [];
      for (var raw in notificationsData) {
        final map = Map<String, dynamic>.from(raw as Map);
        notifications.add(app_notification.Notification.fromMap(map));
      }
      return notifications;
    } catch (e) {
      print('❌ Error getting all notifications from storage: $e');
      return [];
    }
  }

  /// Save notifications to storage
  static Future<void> _saveNotifications(
      List<app_notification.Notification> notifications) async {
    try {
      final List<Map<String, dynamic>> notificationsData =
          notifications.map((n) => n.toMap()).toList();
      await HiveService.saveSetting(_notificationsBox, notificationsData);
    } catch (e) {
      print('❌ Error saving notifications: $e');
    }
  }


  /// Create sample notifications for demonstration
  static Future<void> _createSampleNotifications() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return;
      
      final existingNotifications = await getAllNotifications();
      if (existingNotifications.isNotEmpty) return; // Don't create if already exists
      
      final sampleNotifications = [
        {
          'title': 'Selamat Datang di SakuRimba!',
          'message': 'Terima kasih telah bergabung dengan SakuRimba. Mulai jelajahi peralatan camping terbaik untuk petualangan Anda.',
          'type': 'system',
        },
        {
          'title': 'Promo Spesial Weekend',
          'message': 'Dapatkan diskon 20% untuk semua peralatan camping di akhir pekan ini. Gunakan kode: WEEKEND20',
          'type': 'promotion',
        },
        {
          'title': 'Tips Camping',
          'message': 'Pastikan untuk selalu membawa perlengkapan P3K dan memeriksa cuaca sebelum berangkat camping.',
          'type': 'system',
        },
      ];
      
      for (final notif in sampleNotifications) {
        await createNotification(
          userId: userId,
          title: notif['title']!,
          message: notif['message']!,
          type: notif['type']!,
        );
      }
      
      print('📱 Sample notifications created');
    } catch (e) {
      print('❌ Error creating sample notifications: $e');
    }
  }

  /// Send rental notification
  static Future<void> sendRentalNotification({
    required String userId,
    required String rentalId,
    required String peralatanNama,
    required String type, // created, confirmed, active, completed, cancelled
  }) async {
    String title;
    String message;
    
    switch (type) {
      case 'created':
        title = 'Sewa Berhasil Dibuat';
        message = 'Sewa untuk $peralatanNama telah berhasil dibuat. ID: $rentalId';
        break;
      case 'confirmed':
        title = 'Sewa Dikonfirmasi';
        message = 'Sewa untuk $peralatanNama telah dikonfirmasi dan siap diambil.';
        break;
      case 'active':
        title = 'Sewa Aktif';
        message = 'Sewa untuk $peralatanNama sedang berjalan. Selamat menikmati petualangan!';
        break;
      case 'completed':
        title = 'Sewa Selesai';
        message = 'Sewa untuk $peralatanNama telah selesai. Terima kasih telah menggunakan SakuRimba!';
        break;
      case 'cancelled':
        title = 'Sewa Dibatalkan';
        message = 'Sewa untuk $peralatanNama telah dibatalkan. Refund akan diproses dalam 3-5 hari kerja.';
        break;
      default:
        title = 'Update Sewa';
        message = 'Status sewa untuk $peralatanNama telah diperbarui.';
    }
    
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'rental',
      data: {
        'rental_id': rentalId,
        'peralatan_nama': peralatanNama,
        'rental_type': type,
      },
    );
  }
  

  /// Send payment notification
  static Future<void> sendPaymentNotification({
    required String userId,
    required String rentalId,
    required double amount,
    required String type, // success, failed, refund
  }) async {
    String title;
    String message;
    
    switch (type) {
      case 'success':
        title = 'Pembayaran Berhasil';
        message = 'Pembayaran sebesar Rp ${amount.toStringAsFixed(0)} telah berhasil diproses.';
        break;
      case 'failed':
        title = 'Pembayaran Gagal';
        message = 'Pembayaran sebesar Rp ${amount.toStringAsFixed(0)} gagal diproses. Silakan coba lagi.';
        break;
      case 'refund':
        title = 'Refund Diproses';
        message = 'Refund sebesar Rp ${amount.toStringAsFixed(0)} sedang diproses.';
        break;
      default:
        title = 'Update Pembayaran';
        message = 'Status pembayaran telah diperbarui.';
    }
    
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'payment',
      data: {
        'rental_id': rentalId,
        'amount': amount,
        'payment_type': type,
      },
    );
  }

  /// Send reminder notification
  static Future<void> sendReminderNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'reminder',
      data: data,
    );
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final notifications = await getAllNotifications();
      
      if (notifications.isEmpty) {
        return {
          'total': 0,
          'unread': 0,
          'by_type': {},
          'recent_count': 0,
        };
      }
      
      final unreadCount = notifications.where((n) => !n.isRead).length;
      final recentCount = notifications.where((n) {
        final daysDiff = DateTime.now().difference(n.createdAt).inDays;
        return daysDiff <= 7;
      }).length;
      
      // Count by type
      final byType = <String, int>{};
      for (final notification in notifications) {
        byType[notification.type] = (byType[notification.type] ?? 0) + 1;
      }
      
      return {
        'total': notifications.length,
        'unread': unreadCount,
        'by_type': byType,
        'recent_count': recentCount,
        'read_rate': notifications.isNotEmpty 
            ? ((notifications.length - unreadCount) / notifications.length * 100).round() 
            : 0,
      };
    } catch (e) {
      print('❌ Error getting notification stats: $e');
      return {};
    }
  }

  /// Debug method
  static Future<void> printNotificationDebug() async {
    try {
      print('🔔 === NOTIFICATION SERVICE DEBUG ===');
      
      final stats = await getNotificationStats();
      print('🔔 Notification Stats: $stats');
      
      final notifications = await getAllNotifications();
      print('🔔 Total Notifications: ${notifications.length}');
      
      if (notifications.isNotEmpty) {
        final recent = notifications.first;
        print('🔔 Recent Notification: ${recent.title} (${recent.type})');
      }
      
      final unreadCount = await getUnreadCount();
      print('🔔 Unread Count: $unreadCount');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in notification debug: $e');
    }
  }
}