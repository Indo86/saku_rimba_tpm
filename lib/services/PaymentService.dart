import '../services/HiveService.dart';
import '../services/NotificationService.dart';
import '../services/UserService.dart';
import '../models/rent.dart';
import 'RentService.dart';

class PaymentService {
  // Payment methods
  static const String BANK_TRANSFER = 'bank_transfer';
  static const String E_WALLET = 'e_wallet';
  static const String QRIS = 'qris';
  static const String CREDIT_CARD = 'credit_card';

  // Payment status
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_SUCCESS = 'success';
  static const String STATUS_FAILED = 'failed';
  static const String STATUS_CANCELLED = 'cancelled';

static Future<bool> processPayment({
    required String rentalId,
    required double amount,
    required String paymentMethod,
    required String paymentType, // 'full' or 'dp'
  }) async {
    try {
      print('🏦 Processing payment for rental: $rentalId');
      print('💰 Amount: $amount');
      print('💳 Method: $paymentMethod');
      print('📝 Type: $paymentType');

      // 1. Ambil data rental
      final Rent? rental = await RentService.getRental(rentalId);
      if (rental == null) throw Exception('Rental not found');

      // 2. Simulasikan pemrosesan pembayaran
      await _simulatePaymentProcessing(paymentMethod);

      // 3. Hitung status baru dan update di Hive
      final String newStatus = paymentType == 'full' ? 'paid' : 'dp';
      final Rent? updatedRental = await HiveService.updateRentalPayment(
        rentalId,
        newStatus,
        amount,
      );
      if (updatedRental == null) {
        print('❌ Failed to update rental payment status');
        return false;
      }

      // 4. Kirim notifikasi pembayaran
      await NotificationService.sendPaymentNotification(
        userId: updatedRental.userId,
        rentalId: rentalId,
        amount: amount,
        type: newStatus,
      );

      // 5. Log pembayaran
      await _logPayment(rentalId, amount, paymentMethod, paymentType);

      print('✅ Payment processed successfully');
      return true;
    } catch (e) {
      print('❌ Payment processing failed: $e');
      return false;
    }
  }


  /// Calculate expected payment amount
  static double _calculateExpectedAmount(Rent rental, String paymentType) {
    switch (paymentType) {
      case 'dp':
        return rental.totalPrice * 0.5;
      case 'full':
        if (rental.paymentStatus == 'dp') {
          // Remaining amount after DP
          return rental.totalPrice - rental.paidAmount;
        } else {
          // Full amount
          return rental.totalPrice;
        }
      default:
        return rental.totalPrice;
    }
  }

  /// Simulate payment processing delay
  static Future<void> _simulatePaymentProcessing(String paymentMethod) async {
    // Simulate different processing times for different methods
    int delay;
    switch (paymentMethod) {
      case QRIS:
        delay = 1000; // 1 second
        break;
      case E_WALLET:
        delay = 1500; // 1.5 seconds
        break;
      case BANK_TRANSFER:
        delay = 2000; // 2 seconds
        break;
      case CREDIT_CARD:
        delay = 2500; // 2.5 seconds
        break;
      default:
        delay = 2000;
    }
    
    await Future.delayed(Duration(milliseconds: delay));
    
    // Simulate 5% chance of payment failure
    if (DateTime.now().millisecond % 20 == 0) {
      throw Exception('Payment gateway error');
    }
  }

  /// Update rental payment status
static Future<bool> _updateRentalPaymentStatus(
    Rent rental,
    double amount,
    String newStatus,
  ) async {
    try {
      // Call HiveService.updateRentalPayment, returns updated Rent or null
      final Rent? updated = await HiveService.updateRentalPayment(
        rental.id,
        newStatus,
        amount,
      );
      return updated != null;
    } catch (e) {
      print('❌ Error updating rental payment status: \$e');
      return false;
    }
  }


  /// Send payment notification
  static Future<void> _sendPaymentNotification(
    Rent rental, 
    double amount, 
    String paymentMethod
  ) async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return;
      
      final methodName = _getPaymentMethodName(paymentMethod);
      
      await NotificationService.createNotification(
        userId: userId,
        title: 'Pembayaran Berhasil',
        message: 'Pembayaran sebesar Rp ${amount.toStringAsFixed(0)} untuk sewa ${rental.peralatanNama} berhasil diproses via $methodName.',
        type: 'payment',
        data: {
          'rental_id': rental.id,
          'amount': amount,
          'payment_method': paymentMethod,
        },
      );
    } catch (e) {
      print('❌ Error sending payment notification: $e');
    }
  }

  /// Log payment for record keeping
  static Future<void> _logPayment(
    String rentalId,
    double amount, 
    String paymentMethod, 
    String paymentType
  ) async {
    try {
      final paymentLog = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'rental_id': rentalId,
        'user_id': UserService.getCurrentUserId(),
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_type': paymentType,
        'status': STATUS_SUCCESS,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Save to local storage
      final paymentLogs = await HiveService.getSetting<List<dynamic>>('payment_logs') ?? [];
      paymentLogs.add(paymentLog);
      
      // Keep only last 100 payment logs
      if (paymentLogs.length > 100) {
        paymentLogs.removeRange(0, paymentLogs.length - 100);
      }
      
      await HiveService.saveSetting('payment_logs', paymentLogs);
      
      print('📝 Payment logged successfully');
    } catch (e) {
      print('❌ Error logging payment: $e');
    }
  }

  /// Get payment method display name
  static String _getPaymentMethodName(String methodId) {
    switch (methodId) {
      case BANK_TRANSFER:
        return 'Transfer Bank';
      case E_WALLET:
        return 'E-Wallet';
      case QRIS:
        return 'QRIS';
      case CREDIT_CARD:
        return 'Kartu Kredit';
      default:
        return 'Unknown';
    }
  }

  /// Get payment history for current user
  static Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final paymentLogs = await HiveService.getSetting<List<dynamic>>('payment_logs') ?? [];
      final userId = UserService.getCurrentUserId();
      
      if (userId == null) return [];
      
      return paymentLogs
          .cast<Map<String, dynamic>>()
          .where((log) => log['user_id'] == userId)
          .toList()
          ..sort((a, b) => b['created_at'].compareTo(a['created_at']));
    } catch (e) {
      print('❌ Error getting payment history: $e');
      return [];
    }
  }

  /// Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final paymentHistory = await getPaymentHistory();
      
      if (paymentHistory.isEmpty) {
        return {
          'total_payments': 0,
          'total_amount': 0.0,
          'successful_payments': 0,
          'failed_payments': 0,
          'most_used_method': 'N/A',
        };
      }
      
      double totalAmount = 0;
      int successfulPayments = 0;
      int failedPayments = 0;
      final methodCount = <String, int>{};
      
      for (final payment in paymentHistory) {
        final amount = payment['amount'] as double? ?? 0.0;
        final status = payment['status'] as String? ?? '';
        final method = payment['payment_method'] as String? ?? '';
        
        totalAmount += amount;
        
        if (status == STATUS_SUCCESS) {
          successfulPayments++;
        } else if (status == STATUS_FAILED) {
          failedPayments++;
        }
        
        methodCount[method] = (methodCount[method] ?? 0) + 1;
      }
      
      // Find most used method
      String mostUsedMethod = 'N/A';
      int maxCount = 0;
      methodCount.forEach((method, count) {
        if (count > maxCount) {
          maxCount = count;
          mostUsedMethod = _getPaymentMethodName(method);
        }
      });
      
      return {
        'total_payments': paymentHistory.length,
        'total_amount': totalAmount,
        'successful_payments': successfulPayments,
        'failed_payments': failedPayments,
        'most_used_method': mostUsedMethod,
        'success_rate': paymentHistory.isNotEmpty 
            ? (successfulPayments / paymentHistory.length * 100).round() 
            : 0,
      };
    } catch (e) {
      print('❌ Error getting payment stats: $e');
      return {};
    }
  }

static Future<bool> refundPayment({
    required String rentalId,
    required double amount,
    required String reason,
  }) async {
    try {
      print('💸 Processing refund for rental: $rentalId');
      print('💰 Amount: $amount');
      print('📝 Reason: $reason');

      // 1. Ambil data rental
      final Rent? rental = await RentService.getRental(rentalId);
      if (rental == null) throw Exception('Rental not found');

      // 2. Validasi nilai refund
      if (amount > rental.paidAmount) {
        throw Exception('Refund amount cannot exceed paid amount');
      }

      // 3. Simulasikan pemrosesan refund
      await Future.delayed(const Duration(seconds: 2));

      // 4. Kurangi paidAmount dan update paymentStatus di Hive
      final double refundedPaid = rental.paidAmount - amount;
      final String refundStatus = refundedPaid <= 0 ? 'refunded' : 'partial';
      final Rent? updatedRental = await HiveService.updateRentalPayment(
        rentalId,
        refundStatus,
        -amount,
      );
      if (updatedRental == null) {
        print('❌ Failed to update refund status');
        return false;
      }

      // 5. Log refund
      await _logRefund(rentalId, amount, reason);

      // 6. Kirim notifikasi refund
      await NotificationService.sendPaymentNotification(
        userId: updatedRental.userId,
        rentalId: rentalId,
        amount: amount,
        type: 'refund',
      );

      print('✅ Refund processed successfully');
      return true;
    } catch (e) {
      print('❌ Refund processing failed: $e');
      return false;
    }
  }

  /// Log refund
  static Future<void> _logRefund(
    String rentalId,
    double amount,
    String reason,
  ) async {
    try {
      final refundLog = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'rental_id': rentalId,
        'user_id': UserService.getCurrentUserId(),
        'amount': amount,
        'reason': reason,
        'status': STATUS_SUCCESS,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final refundLogs = await HiveService.getSetting<List<dynamic>>('refund_logs') ?? [];
      refundLogs.add(refundLog);
      
      await HiveService.saveSetting('refund_logs', refundLogs);
      
      print('📝 Refund logged successfully');
    } catch (e) {
      print('❌ Error logging refund: $e');
    }
  }

  /// Send refund notification
  static Future<void> _sendRefundNotification(
    Rent rental,
    double amount,
    String reason,
  ) async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return;
      
      await NotificationService.createNotification(
        userId: userId,
        title: 'Refund Diproses',
        message: 'Refund sebesar Rp ${amount.toStringAsFixed(0)} untuk sewa ${rental.peralatanNama} sedang diproses. Alasan: $reason',
        type: 'payment',
        data: {
          'rental_id': rental.id,
          'refund_amount': amount,
          'reason': reason,
        },
      );
    } catch (e) {
      print('❌ Error sending refund notification: $e');
    }
  }

  /// Check if rental can be paid
  static bool canMakePayment(Rent rental) {
    return rental.paymentStatus != 'paid' && 
           rental.paymentStatus != 'refunded' &&
           rental.status != 'cancelled' &&
           rental.status != 'completed';
  }

  /// Check if rental can be refunded
  static bool canRefund(Rent rental) {
    return rental.paidAmount > 0 && 
           rental.paymentStatus != 'refunded' &&
           (rental.status == 'cancelled' || 
            rental.status == 'pending' ||
            DateTime.now().isBefore(rental.startDate));
  }

  /// Debug method
  static Future<void> printPaymentDebug() async {
    try {
      print('💳 === PAYMENT SERVICE DEBUG ===');
      
      final stats = await getPaymentStats();
      print('💳 Payment Stats: $stats');
      
      final history = await getPaymentHistory();
      print('💳 Payment History Count: ${history.length}');
      
      if (history.isNotEmpty) {
        final recent = history.first;
        print('💳 Recent Payment: ${recent['amount']} via ${recent['payment_method']}');
      }
      
      print('==============================');
    } catch (e) {
      print('❌ Error in payment debug: $e');
    }
  }
}