import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rent.dart';
import '../services/PaymentService.dart';
import '../services/UserService.dart';

class PaymentPage extends StatefulWidget {
  final Rent rental;
  
  const PaymentPage({
    super.key,
    required this.rental,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  String _selectedPaymentMethod = 'bank_transfer';
  String _paymentType = 'full'; // full, dp, or remaining
  bool _isProcessing = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue[600],
      'description': 'Transfer ke rekening BCA, BNI, atau Mandiri',
    },
    {
      'id': 'e_wallet',
      'name': 'E-Wallet',
      'icon': Icons.wallet,
      'color': Colors.green[600],
      'description': 'Bayar dengan GoPay, OVO, atau DANA',
    },
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': Icons.qr_code,
      'color': Colors.purple[600],
      'description': 'Scan QR Code untuk pembayaran instant',
    },
    {
      'id': 'credit_card',
      'name': 'Kartu Kredit',
      'icon': Icons.credit_card,
      'color': Colors.orange[600],
      'description': 'Visa, Mastercard, atau JCB',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // FIXED: Set default payment type based on rental payment status
    if (widget.rental.paymentStatus == 'dp') {
      _paymentType = 'remaining'; // Pay remaining amount
    } else if (widget.rental.paymentStatus == 'unpaid') {
      _paymentType = 'dp'; // Default to DP for unpaid
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  double get _totalAmount {
    return widget.rental.totalPrice;
  }

  double get _dpAmount {
    return _totalAmount * 0.5;
  }

  double get _remainingAmount {
    return _totalAmount - widget.rental.paidAmount;
  }

  double get _paymentAmount {
    switch (_paymentType) {
      case 'dp':
        return _dpAmount;
      case 'remaining':
        return _remainingAmount;
      case 'full':
      default:
        return _totalAmount;
    }
  }

  // FIXED: Get expected rental status after payment
  String get _expectedRentalStatusAfterPayment {
    return PaymentService.getRentalStatusAfterPayment(_paymentType, widget.rental.status);
  }

  // FIXED: Use actual PaymentService with proper payment type
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('🏦 Starting payment process...');
      print('💰 Amount: $_paymentAmount');
      print('💳 Method: $_selectedPaymentMethod');
      print('📝 Type: $_paymentType');
      print('🎯 Expected rental status after payment: $_expectedRentalStatusAfterPayment');

      // FIXED: Call PaymentService with proper payment type
      final success = await PaymentService.processPayment(
        rentalId: widget.rental.id,
        amount: _paymentAmount,
        paymentMethod: _selectedPaymentMethod,
        paymentType: _paymentType,
      );

      if (success) {
        if (mounted) {
          print('✅ Payment successful, showing success dialog');
          _showPaymentSuccessDialog();
        }
      } else {
        if (mounted) {
          print('❌ Payment failed, showing failure dialog');
          _showPaymentFailedDialog();
        }
      }
    } catch (e) {
      print('❌ Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Pembayaran Berhasil!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran Anda telah berhasil diproses.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💳 Detail Pembayaran:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jumlah: Rp ${_formatCurrency(_paymentAmount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Metode: ${_getPaymentMethodName(_selectedPaymentMethod)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Tipe: ${PaymentService.getPaymentTypeName(_paymentType)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Waktu: ${DateTime.now().toString().substring(0, 19)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // FIXED: Show rental status update information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Status Sewa Diperbarui',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusUpdateMessage(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Back to previous page with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Get status update message based on payment type
  String _getStatusUpdateMessage() {
    switch (_paymentType) {
      case 'dp':
        return 'Status sewa berubah menjadi "Dikonfirmasi" karena DP telah dibayar.';
      case 'full':
        if (widget.rental.paymentStatus == 'unpaid') {
          return 'Status sewa berubah menjadi "Aktif" karena pembayaran lunas.';
        } else {
          return 'Status sewa berubah menjadi "Aktif" karena pelunasan.';
        }
      case 'remaining':
        return 'Status sewa berubah menjadi "Aktif" karena pelunasan sisa pembayaran.';
      default:
        return 'Status sewa telah diperbarui sesuai pembayaran.';
    }
  }

  void _showPaymentFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Pembayaran Gagal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pembayaran tidak dapat diproses. Silakan coba lagi atau hubungi customer service.',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CS: 0821-xxxx-xxxx (24 jam)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String methodId) {
    final method = _paymentMethods.firstWhere((m) => m['id'] == methodId);
    return method['name'];
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Pembayaran',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Rental Summary
          _buildRentalSummary(),
          
          // Payment Type Selection
          if (widget.rental.paymentStatus == 'unpaid')
            _buildPaymentTypeSelection(),
          
          // Payment Amount Summary
          _buildPaymentSummary(),
          
          // Payment Methods
          _buildPaymentMethods(),
          
          // Payment Button
          _buildPaymentButton(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRentalSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Sewa',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            widget.rental.peralatanNama,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          _buildDetailRow('ID Sewa:', widget.rental.id),
          _buildDetailRow('Durasi:', '${widget.rental.rentalDays} hari'),
          _buildDetailRow('Jumlah:', '${widget.rental.quantity} unit'),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(widget.rental.paymentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status Pembayaran:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _getPaymentStatusLabel(widget.rental.paymentStatus),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getPaymentStatusColor(widget.rental.paymentStatus),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green[600]!;
      case 'dp':
        return Colors.orange[600]!;
      case 'unpaid':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'dp':
        return 'DP (50%)';
      case 'unpaid':
        return 'Belum Bayar';
      default:
        return status;
    }
  }

  Widget _buildPaymentTypeSelection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Jenis Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Column(
            children: [
              _buildPaymentTypeOption(
                'full',
                'Bayar Penuh',
                'Rp ${_formatCurrency(_totalAmount)}',
                'Status sewa langsung menjadi "Aktif"',
              ),
              const SizedBox(height: 12),
              _buildPaymentTypeOption(
                'dp',
                'DP (50%)',
                'Rp ${_formatCurrency(_dpAmount)}',
                'Status sewa menjadi "Dikonfirmasi"',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption(String value, String title, String amount, String description) {
    final isSelected = _paymentType == value;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.teal[50] : Colors.white,
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        value: value,
        groupValue: _paymentType,
        onChanged: (val) {
          setState(() {
            _paymentType = val!;
          });
        },
        activeColor: Colors.teal[600],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          
          const SizedBox(height: 12),
          
          _buildSummaryRow('Total Sewa:', 'Rp ${_formatCurrency(_totalAmount)}'),
          
          if (widget.rental.paidAmount > 0)
            _buildSummaryRow('Sudah Dibayar:', 'Rp ${_formatCurrency(widget.rental.paidAmount)}'),
          
          const Divider(color: Colors.teal),
          
          _buildSummaryRow(
            'Yang Harus Dibayar:',
            'Rp ${_formatCurrency(_paymentAmount)}',
            isHighlight: true,
          ),
          
          const SizedBox(height: 8),
          
          // FIXED: Show expected status after payment
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setelah pembayaran, status sewa akan menjadi "${_getStatusLabel(_expectedRentalStatusAfterPayment)}"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isHighlight ? 16 : 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? Colors.teal[700] : Colors.grey[800],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'active':
        return 'Aktif';
      case 'pending':
        return 'Menunggu';
      default:
        return status;
    }
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Column(
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? Colors.teal[50] : Colors.white,
                ),
                child: RadioListTile<String>(
                  value: method['id'],
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (method['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          method['icon'],
                          color: method['color'],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              method['description'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  activeColor: Colors.teal[600],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Payment Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memproses Pembayaran...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Bayar Sekarang (Rp ${_formatCurrency(_paymentAmount)})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Security Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran Anda dilindungi dengan enkripsi SSL 256-bit',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}