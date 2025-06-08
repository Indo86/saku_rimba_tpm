// models/Notification.dart (SakuRimba)
import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 3)
class Notification extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String message;

  @HiveField(4)
  String type; // 'rental', 'payment', 'system', 'reminder', 'promotion'

  @HiveField(5)
  String priority; // 'low', 'medium', 'high', 'urgent'

  @HiveField(6)
  bool isRead;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? readAt;

  @HiveField(9)
  Map<String, dynamic>? data; // Extra data untuk context

  @HiveField(10)
  String? actionType; // 'view_rental', 'make_payment', 'none'

  @HiveField(11)
  String? actionData; // ID atau data untuk action

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'system',
    this.priority = 'medium',
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionType,
    this.actionData,
  });

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'actionType': actionType,
      'actionData': actionData,
    };
  }

  /// Create instance from Map
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      priority: map['priority'] ?? 'medium',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      readAt: map['readAt'] != null 
          ? DateTime.parse(map['readAt']) 
          : null,
      data: map['data'] != null 
          ? Map<String, dynamic>.from(map['data']) 
          : null,
      actionType: map['actionType'],
      actionData: map['actionData'],
    );
  }

  /// Copy with method
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionType,
    String? actionData,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
    );
  }

  /// Mark as read
  Notification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Check if notification is recent (less than 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Get priority color
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return '#FF0000'; // Red
      case 'high':
        return '#FF8C00'; // Orange
      case 'medium':
        return '#4CAF50'; // Green
      case 'low':
        return '#9E9E9E'; // Grey
      default:
        return '#4CAF50';
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case 'rental':
        return '🏕️';
      case 'payment':
        return '💰';
      case 'system':
        return '⚙️';
      case 'reminder':
        return '⏰';
      case 'promotion':
        return '🎉';
      default:
        return '📢';
    }
  }

  /// Get formatted time difference
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${(difference.inDays / 7).floor()} minggu yang lalu';
    }
  }

  /// Get short description
  String get shortMessage {
    if (message.length <= 50) return message;
    return '${message.substring(0, 47)}...';
  }

  /// Check if has action
  bool get hasAction {
    return actionType != null && actionType != 'none';
  }

  /// Factory methods for common notification types
  static Notification createRentalNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    Map<String, dynamic>? data,
    String? actionType,
    String? actionData,
  }) {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: 'rental',
      priority: priority,
      createdAt: DateTime.now(),
      data: data,
      actionType: actionType,
      actionData: actionData,
    );
  }

  static Notification createPaymentNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    String priority = 'high',
    Map<String, dynamic>? data,
    String? actionType,
    String? actionData,
  }) {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: 'payment',
      priority: priority,
      createdAt: DateTime.now(),
      data: data,
      actionType: actionType,
      actionData: actionData,
    );
  }

  static Notification createReminderNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    Map<String, dynamic>? data,
    String? actionType,
    String? actionData,
  }) {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: 'reminder',
      priority: priority,
      createdAt: DateTime.now(),
      data: data,
      actionType: actionType,
      actionData: actionData,
    );
  }

  static Notification createSystemNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    String priority = 'low',
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: 'system',
      priority: priority,
      createdAt: DateTime.now(),
      data: data,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}