// services/HiveService.dart (SakuRimba)
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/rent.dart';
import '../models/notification.dart';

class HiveService {
  static const String _userBoxName = 'user_objects';
  static const String _passwordBoxName = 'users';
  static const String _rentBoxName = 'rentals';
  static const String _notificationBoxName = 'notifications';
  static const String _favoritesBoxPrefix = 'favorites_';
  static const String _userDataBoxPrefix = 'user_data_';
  static const String _settingsBoxName = 'settings';

  // Initialize Hive
  static Future<void> init() async {
    try {
      print('🚀 Initializing Hive for SakuRimba...');
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserAdapter());
        print('✅ UserAdapter registered');
      }
      
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(RentAdapter());
        print('✅ RentAdapter registered');
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(NotificationAdapter());
        print('✅ NotificationAdapter registered');
      }

      // Open essential boxes
      await openEssentialBoxes();
      print('✅ Hive initialization completed for SakuRimba');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  // Open essential boxes
  static Future<void> openEssentialBoxes() async {
    try {
      // Open password box (existing system)
      if (!Hive.isBoxOpen(_passwordBoxName)) {
        await Hive.openBox(_passwordBoxName);
        print('✅ Password box opened: $_passwordBoxName');
      }

      // Open user objects box
      if (!Hive.isBoxOpen(_userBoxName)) {
        await Hive.openBox<User>(_userBoxName);
        print('✅ User box opened: $_userBoxName');
      }

      // Open rental box
      if (!Hive.isBoxOpen(_rentBoxName)) {
        await Hive.openBox<Rent>(_rentBoxName);
        print('✅ Rental box opened: $_rentBoxName');
      }

      // Open notification box
      if (!Hive.isBoxOpen(_notificationBoxName)) {
        await Hive.openBox<Notification>(_notificationBoxName);
        print('✅ Notification box opened: $_notificationBoxName');
      }

      // Open settings box
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        await Hive.openBox(_settingsBoxName);
        print('✅ Settings box opened: $_settingsBoxName');
      }
    } catch (e) {
      print('❌ Error opening essential boxes: $e');
      rethrow;
    }
  }

  // ============================================================================
  // USER BOX OPERATIONS
  // ============================================================================

  static Future<Box<User>> getUserBox() async {
    if (!Hive.isBoxOpen(_userBoxName)) {
      print('📦 Opening user box: $_userBoxName');
      await Hive.openBox<User>(_userBoxName);
    }
    return Hive.box<User>(_userBoxName);
  }

  static Box<User> getUserBoxSync() {
    if (!Hive.isBoxOpen(_userBoxName)) {
      throw HiveError('User box is not open. Call HiveService.init() first.');
    }
    return Hive.box<User>(_userBoxName);
  }

  // Password Box Operations (existing system)
  static Box getPasswordBox() {
    if (!Hive.isBoxOpen(_passwordBoxName)) {
      throw HiveError('Password box is not open. Call HiveService.init() first.');
    }
    return Hive.box(_passwordBoxName);
  }

  // User CRUD Operations
  static Future<void> saveUser(User user) async {
    try {
      final box = await getUserBox();
      await box.put(user.username, user);
      print('✅ User saved: ${user.username}');
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  static Future<User?> getUser(String username) async {
    try {
      final box = await getUserBox();
      return box.get(username);
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  static Future<void> updateUser(User user) async {
    try {
      user.updatedAt = DateTime.now();
      await saveUser(user);
      print('✅ User updated: ${user.username}');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String username) async {
    try {
      final box = await getUserBox();
      await box.delete(username);
      print('✅ User deleted: $username');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final box = await getUserBox();
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Password Operations
  static Future<void> savePassword(String username, String passwordHash) async {
    try {
      final box = getPasswordBox();
      await box.put(username, passwordHash);
      print('✅ Password saved for: $username');
    } catch (e) {
      print('❌ Error saving password: $e');
      rethrow;
    }
  }

  static String? getPassword(String username) {
    try {
      final box = getPasswordBox();
      return box.get(username);
    } catch (e) {
      print('❌ Error getting password: $e');
      return null;
    }
  }

  static bool passwordExists(String username) {
    try {
      final box = getPasswordBox();
      return box.containsKey(username);
    } catch (e) {
      print('❌ Error checking password existence: $e');
      return false;
    }
  }

  // ============================================================================
  // RENTAL BOX OPERATIONS
  // ============================================================================

  static Future<Box<Rent>> getRentBox() async {
    if (!Hive.isBoxOpen(_rentBoxName)) {
      await Hive.openBox<Rent>(_rentBoxName);
    }
    return Hive.box<Rent>(_rentBoxName);
  }

  static Box<Rent> getRentBoxSync() {
    if (!Hive.isBoxOpen(_rentBoxName)) {
      throw HiveError('Rental box is not open. Call HiveService.init() first.');
    }
    return Hive.box<Rent>(_rentBoxName);
  }

  // Rental CRUD Operations dengan business logic validation
  static Future<String> saveRental(Rent rental) async {
    try {
      final box = await getRentBox();
      
      // Validate business logic before saving
      if (rental.paymentStatus == 'dp' && rental.paidAmount < rental.totalPrice * 0.5) {
        throw Exception('Jumlah DP harus minimal 50% dari total harga');
      }
      
      if (rental.paymentStatus == 'paid' && rental.paidAmount < rental.totalPrice) {
        throw Exception('Jumlah pembayaran kurang dari total harga');
      }
      
      // Auto-confirm jika sudah bayar
      final finalRental = _autoConfirmIfPaid(rental);
      
      await box.put(finalRental.id, finalRental);
      print('✅ Rental saved: ${finalRental.id} for user: ${finalRental.userId} - Status: ${finalRental.status}');
      return finalRental.id;
    } catch (e) {
      print('❌ Error saving rental: $e');
      rethrow;
    }
  }

  static Future<void> updateRental(Rent rental) async {
    try {
      await saveRental(rental);
      print('✅ Rental updated: ${rental.id}');
    } catch (e) {
      print('❌ Error updating rental: $e');
      rethrow;
    }
  }

  static Future<Rent> updateRentalStatus(String rentalId, String newStatus) async {
    try {
      final box = await getRentBox();
      final rental = box.get(rentalId);
      
      if (rental == null) {
        throw Exception('Rental tidak ditemukan');
      }
      
      final updatedRental = rental.copyWith(status: newStatus);
      await box.put(rentalId, updatedRental);
      
      print('✅ Rental status updated: $rentalId -> $newStatus');
      return updatedRental;
    } catch (e) {
      print('❌ Error updating rental status: $e');
      rethrow;
    }
  }

  static Future<Rent> updateRentalPayment(String rentalId, String newPaymentStatus, double amount) async {
    try {
      final box = await getRentBox();
      final rental = box.get(rentalId);
      
      if (rental == null) {
        throw Exception('Rental tidak ditemukan');
      }
      
      Rent updatedRental;
      
      if (newPaymentStatus == 'paid' && rental.paidAmount > 0) {
        // Pembayaran sisa
        updatedRental = rental.copyWith(
          paymentStatus: 'paid',
          paidAmount: rental.totalPrice,
          paymentDate: DateTime.now(),
        );
        print('✅ Remaining payment completed for rental: $rentalId');
      } else {
        // Pembayaran baru
        updatedRental = rental.copyWith(
          paymentStatus: newPaymentStatus,
          paidAmount: amount,
          paymentDate: DateTime.now(),
        );
        print('✅ New payment processed for rental: $rentalId -> $newPaymentStatus (${amount})');
      }
      
      // Auto-confirm setelah pembayaran
      final finalRental = _autoConfirmIfPaid(updatedRental);
      
      await box.put(rentalId, finalRental);
      
      print('✅ Final rental status: ${finalRental.status} - Payment: ${finalRental.paymentStatus}');
      return finalRental;
    } catch (e) {
      print('❌ Error updating rental payment: $e');
      rethrow;
    }
  }

  static Future<void> deleteRental(String rentalId) async {
    try {
      final box = await getRentBox();
      final rental = box.get(rentalId);
      
      if (rental == null) {
        throw Exception('Rental tidak ditemukan');
      }
      
      if (!_canBeDeleted(rental)) {
        throw Exception('Rental tidak dapat dihapus. Status saat ini: ${rental.status}');
      }
      
      await box.delete(rentalId);
      print('✅ Rental deleted: $rentalId');
    } catch (e) {
      print('❌ Error deleting rental: $e');
      rethrow;
    }
  }

  static Future<Rent?> getRental(String rentalId) async {
    try {
      final box = await getRentBox();
      return box.get(rentalId);
    } catch (e) {
      print('❌ Error getting rental: $e');
      return null;
    }
  }

  // Rental Queries
  static Future<List<Rent>> getAllRentals() async {
    try {
      final box = await getRentBox();
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting all rentals: $e');
      return [];
    }
  }

  static Future<List<Rent>> getRentalsByUser(String userId) async {
    try {
      final box = await getRentBox();
      final userRentals = box.values.where((rental) => rental.userId == userId).toList();
      
      // Sort by booking date (newest first)
      userRentals.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
      print('✅ Retrieved ${userRentals.length} rentals for user: $userId');
      return userRentals;
    } catch (e) {
      print('❌ Error getting rentals for user $userId: $e');
      return [];
    }
  }

  static Future<List<Rent>> getRentalsByUserAndStatus(String userId, String status) async {
    try {
      final userRentals = await getRentalsByUser(userId);
      return userRentals.where((rental) => rental.status == status).toList();
    } catch (e) {
      print('❌ Error getting rentals by status: $e');
      return [];
    }
  }

  static Future<bool> hasActiveRentalForPeralatan(String userId, String peralatanId) async {
    try {
      final userRentals = await getRentalsByUser(userId);
      return userRentals.any((rental) => 
        rental.peralatanId == peralatanId && 
        ['pending', 'confirmed', 'active'].contains(rental.status)
      );
    } catch (e) {
      print('❌ Error checking active rental for peralatan: $e');
      return false;
    }
  }

  // ============================================================================
  // NOTIFICATION BOX OPERATIONS
  // ============================================================================

  static Future<Box<Notification>> getNotificationBox() async {
    if (!Hive.isBoxOpen(_notificationBoxName)) {
      await Hive.openBox<Notification>(_notificationBoxName);
    }
    return Hive.box<Notification>(_notificationBoxName);
  }

  static Future<void> saveNotification(Notification notification) async {
    try {
      final box = await getNotificationBox();
      await box.put(notification.id, notification);
      print('✅ Notification saved: ${notification.id}');
    } catch (e) {
      print('❌ Error saving notification: $e');
      rethrow;
    }
  }

  static Future<List<Notification>> getNotificationsByUser(String userId) async {
    try {
      final box = await getNotificationBox();
      final notifications = box.values.where((notif) => notif.userId == userId).toList();
      
      // Sort by created date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    } catch (e) {
      print('❌ Error getting notifications for user: $e');
      return [];
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final box = await getNotificationBox();
      final notification = box.get(notificationId);
      
      if (notification != null) {
        final updatedNotification = notification.copyWith(isRead: true);
        await box.put(notificationId, updatedNotification);
        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // ============================================================================
  // FAVORITES BOX OPERATIONS
  // ============================================================================

  static Future<Box> getFavoritesBox(String username) async {
    final boxName = '$_favoritesBoxPrefix$username';
    try {
      if (!Hive.isBoxOpen(boxName)) {
        final box = await Hive.openBox(boxName);
        print('📦 Opened favorites box for user: $username');
        return box;
      }
      return Hive.box(boxName);
    } catch (e) {
      print('❌ Error opening favorites box for $username: $e');
      rethrow;
    }
  }

  static Future<void> addToFavorites(String username, String peralatanId, Map<String, dynamic> peralatanData) async {
    try {
      final box = await getFavoritesBox(username);
      await box.put(peralatanId, peralatanData);
      print('✅ Added to favorites: $peralatanId for user $username');
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  static Future<void> removeFromFavorites(String username, String peralatanId) async {
    try {
      final box = await getFavoritesBox(username);
      await box.delete(peralatanId);
      print('✅ Removed from favorites: $peralatanId for user $username');
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  static Future<bool> isFavorite(String username, String peralatanId) async {
    try {
      final box = await getFavoritesBox(username);
      return box.containsKey(peralatanId);
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites(String username) async {
    try {
      final box = await getFavoritesBox(username);
      final List<Map<String, dynamic>> favorites = [];
      
      for (final key in box.keys) {
        try {
          final value = box.get(key);
          if (value is Map) {
            final Map<String, dynamic> peralatanData = Map<String, dynamic>.from(value);
            favorites.add(peralatanData);
          }
        } catch (e) {
          print('⚠️ Error parsing favorite $key for user $username: $e');
        }
      }
      
      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }

  // ============================================================================
  // SETTINGS BOX OPERATIONS
  // ============================================================================

  static Future<Box> getSettingsBox() async {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }
    return Hive.box(_settingsBoxName);
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = await getSettingsBox();
      await box.put(key, value);
      print('✅ Setting saved: $key');
    } catch (e) {
      print('❌ Error saving setting: $e');
      rethrow;
    }
  }

  static Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      final box = await getSettingsBox();
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      print('❌ Error getting setting: $e');
      return defaultValue;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  static String generateRentalId() {
    final now = DateTime.now();
    return 'RT${now.millisecondsSinceEpoch}';
  }

  static String generateNotificationId() {
    final now = DateTime.now();
    return 'NT${now.millisecondsSinceEpoch}';
  }

  static Rent _autoConfirmIfPaid(Rent rental) {
    if (rental.paymentStatus == 'paid' && rental.status == 'pending') {
      return rental.copyWith(status: 'confirmed');
    }
    return rental;
  }

  static bool _canBeDeleted(Rent rental) {
    return ['completed', 'cancelled'].contains(rental.status);
  }

  // Auto-update expired rentals
  static Future<int> updateExpiredRentals() async {
    try {
      final box = await getRentBox();
      final allRentals = box.values.toList();
      int updatedCount = 0;
      
      for (Rent rental in allRentals) {
        if (rental.status == 'active' && DateTime.now().isAfter(rental.endDate)) {
          try {
            final updatedRental = rental.copyWith(status: 'completed');
            await box.put(rental.id, updatedRental);
            updatedCount++;
            print('✅ Auto-completed expired rental: ${rental.id}');
          } catch (e) {
            print('⚠️ Could not auto-complete rental ${rental.id}: $e');
          }
        }
      }
      
      return updatedCount;
    } catch (e) {
      print('❌ Error updating expired rentals: $e');
      return 0;
    }
  }

  // Cleanup Operations
  static Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
      print('✅ All Hive boxes closed');
    } catch (e) {
      print('❌ Error closing boxes: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await Hive.deleteFromDisk();
      print('✅ All Hive data deleted from disk');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  // Debug Methods
  static Future<void> printRentalsDebug(String userId) async {
    print('=== RENTAL DEBUG for user: $userId ===');
    
    try {
      final userRentals = await getRentalsByUser(userId);
      print('User rentals count: ${userRentals.length}');
      
      for (var rental in userRentals) {
        print('  ${rental.id}: ${rental.peralatanNama} - ${rental.status} - ${rental.paymentStatus}');
      }
    } catch (e) {
      print('❌ Error in rental debug: $e');
    }
    
    print('======================================');
  }
}