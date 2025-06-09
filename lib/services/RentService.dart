// services/RentService.dart (SakuRimba)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../services/NotificationService.dart';
import '../models/rent.dart';
import '../models/Peralatan.dart';

class RentService {
  // Get current user ID
  static String? getCurrentUserId() {
    return UserService.getCurrentUserId();
  }

  // Generate unique rental ID
  static String generateRentalId() {
    return HiveService.generateRentalId();
  }

  // ============================================================================
  // RENTAL CREATION AND MANAGEMENT
  // ============================================================================

  /// Create new rental booking
 /// Buat booking rental baru, simpan ke Hive, lalu kirim notifikasi “created”
  static Future<String?> createRental({
    required String peralatanId,
    required String peralatanNama,
    required int quantity,
    required int rentalDays,
    required double pricePerDay,
    required DateTime startDate,
    required DateTime endDate,
    String? userPhone,
  }) async {
    try {
      // Pastikan user sudah login
      final userId = UserService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final user = UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Data user tidak ditemukan.');
      }

      // Validasi tanggal
      if (startDate.isAfter(endDate)) {
        throw Exception('Tanggal mulai tidak boleh setelah tanggal selesai.');
      }
      if (startDate.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
        throw Exception('Tanggal mulai tidak boleh di masa lalu.');
      }

      // Hitung total harga
      final totalPrice = quantity * rentalDays * pricePerDay;

      // Buat objek Rent
      final rental = Rent(
        id: HiveService.generateRentalId(),
        peralatanId: peralatanId,
        peralatanNama: peralatanNama,
        userId: userId,
        userName: user.nama.isNotEmpty ? user.nama : user.username,
        userPhone: userPhone ?? user.phone,
        quantity: quantity,
        rentalDays: rentalDays,
        pricePerDay: pricePerDay,
        totalPrice: totalPrice,
        startDate: startDate,
        endDate: endDate,
        bookingDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Simpan rental ke Hive
      final rentalId = await HiveService.saveRental(rental);

      // Kirim notifikasi “created”
      await NotificationService.sendRentalNotification(
        userId: userId,
        rentalId: rentalId,
        peralatanNama: peralatanNama,
        type: 'created',
      );

      print('✅ Rental created successfully: $rentalId');
      return rentalId;
    } catch (e) {
      print('❌ Error creating rental: $e');
      return null;
    }
  }

  /// Update status rental dan kirim notifikasi sesuai status baru
  static Future<Rent?> updateRentalStatus(
      String rentalId,
      String newStatus,
  ) async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      final rental = await HiveService.getRental(rentalId);
      if (rental == null) {
        throw Exception('Rental tidak ditemukan.');
      }

      // Pastikan user punya akses
      if (!UserService.canAccessRental(rental.userId)) {
        throw Exception('Anda tidak memiliki akses untuk rental ini.');
      }

      // Update status di Hive
      final updatedRental = await HiveService.updateRentalStatus(rentalId, newStatus);

      // Kirim notifikasi berdasarkan status
      await NotificationService.sendRentalNotification(
        userId: userId,
        rentalId: rentalId,
        peralatanNama: rental.peralatanNama,
        type: newStatus,  // e.g. 'confirmed','active','completed','cancelled'
      );

      print('✅ Rental status updated: $rentalId -> $newStatus');
      return updatedRental;
    } catch (e) {
      print('❌ Error updating rental status: $e');
      return null;
    }
  }

  /// Proses pembayaran dan kirim notifikasi sesuai jenis pembayaran
  static Future<Rent?> processPayment(
    String rentalId,
    String paymentStatus,
    double amount,
  ) async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      final rental = await HiveService.getRental(rentalId);
      if (rental == null) {
        throw Exception('Rental tidak ditemukan.');
      }

      if (!UserService.canAccessRental(rental.userId)) {
        throw Exception('Anda tidak memiliki akses untuk rental ini.');
      }

      // Update status pembayaran di Hive
      final updatedRental = await HiveService.updateRentalPayment(
        rentalId,
        paymentStatus,
        amount,
      );

      // Kirim notifikasi pembayaran
      await NotificationService.sendPaymentNotification(
        userId: userId,
        rentalId: rentalId,
        amount: amount,
        type: paymentStatus,  // 'dp','paid','refund'
      );

      print('✅ Payment processed: $rentalId -> $paymentStatus (Rp $amount)');
      return updatedRental;
    } catch (e) {
      print('❌ Error processing payment: $e');
      return null;
    }
  }


  /// Mark the rental as completed (status = "completed") and notify user
  static Future<bool> completeRental(String rentalId) async {
    try {
      // Pastikan rental ada
      final rental = await HiveService.getRental(rentalId);
      if (rental == null) {
        throw Exception('Rental tidak ditemukan');
      }

      // Hanya rental dengan status "active" yang bisa diselesaikan
      if (rental.status != 'active') {
        throw Exception(
          'Tidak dapat menyelesaikan rental dengan status: ${rental.status}',
        );
      }

      // Update status di Hive dan kirim notifikasi via updateRentalStatus
      final updated = await updateRentalStatus(rentalId, 'completed');
      if (updated == null) {
        throw Exception('Gagal update status ke completed');
      }

      return true;
    } catch (e) {
      print('❌ Error completing rental: $e');
      return false;
    }
  }
  /// Pay remaining amount for rental
  static Future<Rent?> payRemainingAmount(String rentalId) async {
    try {
      final rental = await HiveService.getRental(rentalId);
      if (rental == null) {
        throw Exception('Rental tidak ditemukan.');
      }

      final remainingAmount = rental.totalPrice - rental.paidAmount;
      
      return await processPayment(rentalId, 'paid', remainingAmount);
    } catch (e) {
      print('❌ Error paying remaining amount: $e');
      return null;
    }
  }

  /// Cancel rental
  static Future<bool> cancelRental(String rentalId, {String? reason}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      final rental = await HiveService.getRental(rentalId);
      if (rental == null) {
        throw Exception('Rental tidak ditemukan.');
      }

      if (!UserService.canAccessRental(rental.userId)) {
        throw Exception('Anda tidak memiliki akses untuk rental ini.');
      }

      // Check if rental can be cancelled
      if (!['pending', 'confirmed'].contains(rental.status)) {
        throw Exception('Rental tidak dapat dibatalkan karena status saat ini: ${rental.status}');
      }

      // Update status to cancelled
      await HiveService.updateRentalStatus(rentalId, 'cancelled');

      // Create cancellation notification
      await NotificationService.sendReminderNotification(
        userId: userId,
        title: 'Rental Dibatalkan',
        message: 'Rental ${rental.peralatanNama} telah dibatalkan.'
                + (reason != null ? ' Alasan: $reason' : ''),
        data: {
          'rental_id': rentalId,
          if (reason != null) 'reason': reason,
        },
      );

      print('✅ Rental cancelled: $rentalId');
      return true;
    } catch (e) {
      print('❌ Error cancelling rental: $e');
      return false;
    }
  }

  // ============================================================================
  // RENTAL QUERIES
  // ============================================================================

  /// Get all rentals for current user
  static Future<List<Rent>> getUserRentals() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      return await HiveService.getRentalsByUser(userId);
    } catch (e) {
      print('❌ Error getting user rentals: $e');
      return [];
    }
  }

  /// Get rentals by status for current user
  static Future<List<Rent>> getUserRentalsByStatus(String status) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login.');
      }

      return await HiveService.getRentalsByUserAndStatus(userId, status);
    } catch (e) {
      print('❌ Error getting user rentals by status: $e');
      return [];
    }
  }

  /// Get active rentals for current user
  static Future<List<Rent>> getActiveRentals() async {
    return await getUserRentalsByStatus('active');
  }

  /// Get pending rentals for current user
  static Future<List<Rent>> getPendingRentals() async {
    return await getUserRentalsByStatus('pending');
  }

  /// Get completed rentals for current user
  static Future<List<Rent>> getCompletedRentals() async {
    return await getUserRentalsByStatus('completed');
  }

  /// Get cancelled rentals for current user
  static Future<List<Rent>> getCancelledRentals() async {
    return await getUserRentalsByStatus('cancelled');
  }

  /// Get rental by ID
  static Future<Rent?> getRental(String rentalId) async {
    try {
      return await HiveService.getRental(rentalId);
    } catch (e) {
      print('❌ Error getting rental: $e');
      return null;
    }
  }

  /// Check if user has active rental for specific peralatan
  static Future<bool> hasActiveRentalForPeralatan(String peralatanId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      return await HiveService.hasActiveRentalForPeralatan(userId, peralatanId);
    } catch (e) {
      print('❌ Error checking active rental: $e');
      return false;
    }
  }

  /// Search rentals
  static Future<List<Rent>> searchRentals(String query) async {
    try {
      final userRentals = await getUserRentals();
      
      if (query.isEmpty) return userRentals;
      
      final searchLower = query.toLowerCase();
      return userRentals.where((rental) {
        return rental.peralatanNama.toLowerCase().contains(searchLower) ||
               rental.id.toLowerCase().contains(searchLower) ||
               rental.status.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      print('❌ Error searching rentals: $e');
      return [];
    }
  }

  // ============================================================================
  // RENTAL STATISTICS AND ANALYTICS
  // ============================================================================

  /// Get rental statistics for current user
  static Future<Map<String, dynamic>> getRentalStats() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return {};

      final userRentals = await getUserRentals();
      
      // Count by status
      int pending = userRentals.where((r) => r.status == 'pending').length;
      int confirmed = userRentals.where((r) => r.status == 'confirmed').length;
      int active = userRentals.where((r) => r.status == 'active').length;
      int completed = userRentals.where((r) => r.status == 'completed').length;
      int cancelled = userRentals.where((r) => r.status == 'cancelled').length;
      
      // Calculate financial stats
      double totalSpent = userRentals
          .where((r) => r.status == 'completed')
          .fold(0.0, (sum, r) => sum + r.totalPrice);
      
      double pendingPayments = userRentals
          .where((r) => ['pending', 'confirmed', 'active'].contains(r.status))
          .fold(0.0, (sum, r) => sum + (r.totalPrice - r.paidAmount));
      
      // Most rented categories
      Map<String, int> categoryCount = {};
      // Note: Ini memerlukan data kategori dari peralatan, 
      // untuk sementara kita skip atau gunakan nama peralatan sebagai proxy
      
      return {
        'total': userRentals.length,
        'pending': pending,
        'confirmed': confirmed,
        'active': active,
        'completed': completed,
        'cancelled': cancelled,
        'totalSpent': totalSpent,
        'pendingPayments': pendingPayments,
        'averageRentalDuration': _calculateAverageRentalDuration(userRentals),
        'lastRental': userRentals.isNotEmpty ? userRentals.first.bookingDate : null,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting rental stats: $e');
      return {};
    }
  }

  /// Get upcoming rentals (starting soon)
  static Future<List<Rent>> getUpcomingRentals() async {
    try {
      final userRentals = await getUserRentals();
      final now = DateTime.now();
      
      return userRentals.where((rental) {
        return ['confirmed', 'pending'].contains(rental.status) &&
               rental.startDate.isAfter(now) &&
               rental.startDate.difference(now).inDays <= 7; // Next 7 days
      }).toList();
    } catch (e) {
      print('❌ Error getting upcoming rentals: $e');
      return [];
    }
  }

  /// Get overdue returns
  static Future<List<Rent>> getOverdueReturns() async {
    try {
      final userRentals = await getUserRentals();
      final now = DateTime.now();
      
      return userRentals.where((rental) {
        return rental.status == 'active' &&
               rental.endDate.isBefore(now);
      }).toList();
    } catch (e) {
      print('❌ Error getting overdue returns: $e');
      return [];
    }
  }

  // ============================================================================
  // REMINDER AND NOTIFICATION HELPERS
  // ============================================================================

  /// Check and send reminders for upcoming rentals
static Future<void> checkAndSendReminders() async {
  try {
    final upcomingRentals = await getUpcomingRentals();
    for (var rental in upcomingRentals) {
      final daysUntilStart = rental.startDate
          .difference(DateTime.now())
          .inDays;
      
      if (daysUntilStart == 1) {
        await NotificationService.sendReminderNotification(
          userId: rental.userId,
          title: 'Reminder: Rental Besok',
          message: 'Rental ${rental.peralatanNama} dimulai besok '
                   '(${_formatDate(rental.startDate)})',
          data: {'rental_id': rental.id},
        );
      } else if (daysUntilStart == 0) {
        await NotificationService.sendReminderNotification(
          userId: rental.userId,
          title: 'Reminder: Rental Hari Ini',
          message: 'Rental ${rental.peralatanNama} dimulai hari ini. '
                   'Jangan lupa ambil peralatan Anda!',
          data: {'rental_id': rental.id},
        );
      }
    }
  } catch (e) {
    print('❌ Error checking and sending reminders: $e');
  }
}

  /// Check and update expired rentals
  static Future<int> updateExpiredRentals() async {
    try {
      return await HiveService.updateExpiredRentals();
    } catch (e) {
      print('❌ Error updating expired rentals: $e');
      return 0;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  static double _calculateAverageRentalDuration(List<Rent> rentals) {
    if (rentals.isEmpty) return 0.0;
    
    double totalDays = rentals.fold(0.0, (sum, rental) => sum + rental.rentalDays);
    return totalDays / rentals.length;
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Validate rental dates
  static bool validateRentalDates(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    
    // Start date should not be in the past (allow same day)
    if (startDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return false;
    }
    
    // End date should be after start date
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      return false;
    }
    
    return true;
  }

  /// Calculate rental cost
  static double calculateRentalCost(int quantity, int days, double pricePerDay) {
    return quantity * days * pricePerDay;
  }

  /// Calculate minimum down payment (50%)
  static double calculateMinimumDP(double totalPrice) {
    return totalPrice * 0.5;
  }

  // ============================================================================
  // DEBUG AND MAINTENANCE
  // ============================================================================

  /// Debug print rental information
  static Future<void> printRentalDebug() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        print('🔍 Debug: No user logged in');
        return;
      }

      await HiveService.printRentalsDebug(userId);
      
      final stats = await getRentalStats();
      print('🔍 Rental Stats: $stats');
      
      final upcoming = await getUpcomingRentals();
      print('🔍 Upcoming Rentals: ${upcoming.length}');
      
      final overdue = await getOverdueReturns();
      print('🔍 Overdue Returns: ${overdue.length}');
    } catch (e) {
      print('❌ Error in rental debug: $e');
    }
  }

  /// Cleanup old completed rentals (keep only last 100)
  static Future<void> cleanupOldRentals() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      final completedRentals = await getUserRentalsByStatus('completed');
      
      if (completedRentals.length > 100) {
        // Sort by completion date, keep only latest 100
        completedRentals.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
        
        // Delete old ones (beyond 100)
        for (int i = 100; i < completedRentals.length; i++) {
          try {
            await HiveService.deleteRental(completedRentals[i].id);
          } catch (e) {
            print('⚠️ Could not delete old rental ${completedRentals[i].id}: $e');
          }
        }
        
        print('✅ Cleaned up ${completedRentals.length - 100} old rentals');
      }
    } catch (e) {
      print('❌ Error cleaning up old rentals: $e');
    }
  }
}

  