// services/NotificationService.dart (SakuRimba)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../models/Notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  // Initialize notification service
  static Future<void> init() async {
    try {
      if (_isInitialized) return;

      print('🔔 Initializing NotificationService...');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for iOS
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      print('🔔 Notification tapped: ${response.payload}');
      
      if (response.payload != null) {
        final parts = response.payload!.split('|');
        if (parts.length >= 2) {
          final type = parts[0];
          final id = parts[1];
          
          // Handle different notification types
          switch (type) {
            case 'rental':
              // Navigate to rental details
              print('📱 Navigate to rental: $id');
              break;
            case 'payment':
              // Navigate to payment screen
              print('📱 Navigate to payment: $id');
              break;
            case 'reminder':
              // Navigate to reminder details
              print('📱 Navigate to reminder: $id');
              break;
          }
        }
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  // ============================================================================
  // NOTIFICATION CREATION
  // ============================================================================

  /// Create rental-related notification
  static Future<void> createRentalNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    String? rentalId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationId = HiveService.generateNotificationId();
      
      final notification = Notification.createRentalNotification(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        priority: priority,
        data: extraData,
        actionType: rentalId != null ? 'view_rental' : null,
        actionData: rentalId,
      );

      // Save to Hive
      await HiveService.saveNotification(notification);

      // Show local notification
      await _showLocalNotification(
        notification: notification,
        payload: 'rental|${rentalId ?? ''}',
      );

      print('✅ Rental notification created: $notificationId');
    } catch (e) {
      print('❌ Error creating rental notification: $e');
    }
  }

  /// Create payment-related notification
  static Future<void> createPaymentNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'high',
    String? rentalId,
    double? amount,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationId = HiveService.generateNotificationId();
      
      Map<String, dynamic> data = extraData ?? {};
      if (amount != null) {
        data['amount'] = amount;
      }
      
      final notification = Notification.createPaymentNotification(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        priority: priority,
        data: data,
        actionType: rentalId != null ? 'make_payment' : null,
        actionData: rentalId,
      );

      // Save to Hive
      await HiveService.saveNotification(notification);

      // Show local notification
      await _showLocalNotification(
        notification: notification,
        payload: 'payment|${rentalId ?? ''}',
      );

      print('✅ Payment notification created: $notificationId');
    } catch (e) {
      print('❌ Error creating payment notification: $e');
    }
  }

  /// Create reminder notification
  static Future<void> createReminderNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    String? rentalId,
    DateTime? reminderTime,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationId = HiveService.generateNotificationId();
      
      Map<String, dynamic> data = extraData ?? {};
      if (reminderTime != null) {
        data['reminderTime'] = reminderTime.toIso8601String();
      }
      
      final notification = Notification.createReminderNotification(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        priority: priority,
        data: data,
        actionType: rentalId != null ? 'view_rental' : null,
        actionData: rentalId,
      );

      // Save to Hive
      await HiveService.saveNotification(notification);

      // Show local notification
      await _showLocalNotification(
        notification: notification,
        payload: 'reminder|${rentalId ?? ''}',
      );

      print('✅ Reminder notification created: $notificationId');
    } catch (e) {
      print('❌ Error creating reminder notification: $e');
    }
  }

  /// Create system notification
  static Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'low',
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationId = HiveService.generateNotificationId();
      
      final notification = Notification.createSystemNotification(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        priority: priority,
        data: extraData,
      );

      // Save to Hive
      await HiveService.saveNotification(notification);

      // Show local notification
      await _showLocalNotification(
        notification: notification,
        payload: 'system|',
      );

      print('✅ System notification created: $notificationId');
    } catch (e) {
      print('❌ Error creating system notification: $e');
    }
  }

  /// Create promotion notification
  static Future<void> createPromotionNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final notificationId = HiveService.generateNotificationId();
      
      final notification = Notification(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        type: 'promotion',
        priority: priority,
        createdAt: DateTime.now(),
        data: extraData,
      );

      // Save to Hive
      await HiveService.saveNotification(notification);

      // Show local notification
      await _showLocalNotification(
        notification: notification,
        payload: 'promotion|',
      );

      print('✅ Promotion notification created: $notificationId');
    } catch (e) {
      print('❌ Error creating promotion notification: $e');
    }
  }

  // ============================================================================
  // NOTIFICATION MANAGEMENT
  // ============================================================================

  /// Get all notifications for current user
  static Future<List<Notification>> getUserNotifications() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      return await HiveService.getNotificationsByUser(userId);
    } catch (e) {
      print('❌ Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notifications for current user
  static Future<List<Notification>> getUnreadNotifications() async {
    try {
      final notifications = await getUserNotifications();
      return notifications.where((notif) => !notif.isRead).toList();
    } catch (e) {
      print('❌ Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get notifications by type
  static Future<List<Notification>> getNotificationsByType(String type) async {
    try {
      final notifications = await getUserNotifications();
      return notifications.where((notif) => notif.type == type).toList();
    } catch (e) {
      print('❌ Error getting notifications by type: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await HiveService.markNotificationAsRead(notificationId);
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = await getUnreadNotifications();
      
      for (var notification in unreadNotifications) {
        await markAsRead(notification.id);
      }
      
      print('✅ All notifications marked as read (${unreadNotifications.length})');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final unreadNotifications = await getUnreadNotifications();
      return unreadNotifications.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final box = await HiveService.getNotificationBox();
      await box.delete(notificationId);
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications for current user
  static Future<void> clearAllNotifications() async {
    try {
      final notifications = await getUserNotifications();
      final box = await HiveService.getNotificationBox();
      
      for (var notification in notifications) {
        await box.delete(notification.id);
      }
      
      print('✅ All notifications cleared (${notifications.length})');
    } catch (e) {
      print('❌ Error clearing all notifications: $e');
    }
  }

  // ============================================================================
  // LOCAL NOTIFICATION MANAGEMENT
  // ============================================================================

  /// Show local notification
  static Future<void> _showLocalNotification({
    required Notification notification,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      // Determine importance based on priority
      Importance importance;
      Priority priority;
      
      switch (notification.priority) {
        case 'urgent':
          importance = Importance.max;
          priority = Priority.max;
          break;
        case 'high':
          importance = Importance.high;
          priority = Priority.high;
          break;
        case 'medium':
          importance = Importance.defaultImportance;
          priority = Priority.defaultPriority;
          break;
        case 'low':
          importance = Importance.low;
          priority = Priority.low;
          break;
        default:
          importance = Importance.defaultImportance;
          priority = Priority.defaultPriority;
      }

      // Android notification details
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'sakurimba_channel',
        'SakuRimba Notifications',
        channelDescription: 'Notifications for SakuRimba camping equipment rental',
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: _getNotificationColor(notification.type),
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Generate unique ID for local notification
      final int notificationLocalId = notification.hashCode;

      await _flutterLocalNotificationsPlugin.show(
        notificationLocalId,
        notification.title,
        notification.message,
        notificationDetails,
        payload: payload,
      );

      print('✅ Local notification shown: ${notification.title}');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Schedule local notification
  static Future<void> scheduleNotification({
    required Notification notification,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'sakurimba_scheduled_channel',
        'SakuRimba Scheduled Notifications',
        channelDescription: 'Scheduled notifications for SakuRimba',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails();

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final int notificationLocalId = notification.hashCode;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationLocalId,
        notification.title,
        notification.message,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('✅ Notification scheduled for: $scheduledTime');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel scheduled notification
  static Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      print('✅ Scheduled notification cancelled: $notificationId');
    } catch (e) {
      print('❌ Error cancelling scheduled notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  static Color? _getNotificationColor(String type) {
    switch (type) {
      case 'rental':
        return const Color(0xFF4CAF50); // Green
      case 'payment':
        return const Color(0xFF2196F3); // Blue
      case 'reminder':
        return const Color(0xFFFF9800); // Orange
      case 'promotion':
        return const Color(0xFF9C27B0); // Purple
      case 'system':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return null;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final notifications = await getUserNotifications();
      final unreadCount = await getUnreadCount();
      
      // Count by type
      Map<String, int> typeCount = {};
      Map<String, int> priorityCount = {};
      
      for (var notification in notifications) {
        typeCount[notification.type] = (typeCount[notification.type] ?? 0) + 1;
        priorityCount[notification.priority] = (priorityCount[notification.priority] ?? 0) + 1;
      }
      
      // Recent notifications (last 24 hours)
      final recentNotifications = notifications.where((notif) => notif.isRecent).length;
      
      return {
        'total': notifications.length,
        'unread': unreadCount,
        'read': notifications.length - unreadCount,
        'recent': recentNotifications,
        'typeBreakdown': typeCount,
        'priorityBreakdown': priorityCount,
        'lastNotification': notifications.isNotEmpty ? notifications.first.createdAt : null,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting notification stats: $e');
      return {};
    }
  }

  /// Search notifications
  static Future<List<Notification>> searchNotifications(String query) async {
    try {
      final notifications = await getUserNotifications();
      
      if (query.isEmpty) return notifications;
      
      final searchLower = query.toLowerCase();
      return notifications.where((notification) {
        return notification.title.toLowerCase().contains(searchLower) ||
               notification.message.toLowerCase().contains(searchLower) ||
               notification.type.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      print('❌ Error searching notifications: $e');
      return [];
    }
  }

  /// Clean up old notifications (keep only last 500)
  static Future<void> cleanupOldNotifications() async {
    try {
      final notifications = await getUserNotifications();
      
      if (notifications.length > 500) {
        // Sort by creation date, keep only latest 500
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        final box = await HiveService.getNotificationBox();
        
        // Delete old ones (beyond 500)
        for (int i = 500; i < notifications.length; i++) {
          try {
            await box.delete(notifications[i].id);
          } catch (e) {
            print('⚠️ Could not delete old notification ${notifications[i].id}: $e');
          }
        }
        
        print('✅ Cleaned up ${notifications.length - 500} old notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up old notifications: $e');
    }
  }

  /// Debug print notifications
  static Future<void> printNotificationDebug() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) {
        print('🔍 Debug: No user logged in');
        return;
      }

      print('🔍 === NOTIFICATION DEBUG for user: $userId ===');
      
      final notifications = await getUserNotifications();
      final unreadCount = await getUnreadCount();
      final stats = await getNotificationStats();
      
      print('🔍 Total notifications: ${notifications.length}');
      print('🔍 Unread: $unreadCount');
      print('🔍 Stats: $stats');
      
      for (var notification in notifications.take(5)) {
        print('🔍 ${notification.typeIcon} ${notification.title} - ${notification.type} (${notification.isRead ? 'Read' : 'Unread'})');
      }
      
      print('======================================');
    } catch (e) {
      print('❌ Error in notification debug: $e');
    }
  }
}