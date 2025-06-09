import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/RentService.dart';
import '../services/UserService.dart';
import '../models/rent.dart';
import '../components/bottomNav.dart';
import 'RentDetailPage.dart';
import 'LoginPage.dart';
import 'PaymentPage.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});

  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage>
    with TickerProviderStateMixin {
  List<Rent> _allRentals = [];
  List<Rent> _filteredRentals = [];
  String _selectedStatus = 'Semua';
  bool _isLoading = true;
  String _errorMessage = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  // Status filters
  final List<String> _statusFilters = [
    'Semua',
    'pending',
    'confirmed',
    'active',
    'completed',
    'cancelled'
  ];

  final Map<String, String> _statusLabels = {
    'Semua': 'Semua',
    'pending': 'Menunggu',
    'confirmed': 'Dikonfirmasi',
    'active': 'Aktif',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _loadRentals();
    
    // FIXED: Listen to app lifecycle changes for auto-refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoRefresh();
    });
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

  // FIXED: Setup auto-refresh functionality
  void _setupAutoRefresh() {
    // Auto refresh when page becomes visible again
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(onResume: () {
      if (mounted) {
        _loadRentals();
      }
    }));
  }

  Future<void> _loadRentals() async {
    try {
      if (!UserService.isUserLoggedIn()) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Silakan login untuk melihat riwayat sewa';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔄 Loading rentals from RentService...');
      final rentals = await RentService.getUserRentals();
      print('✅ Loaded ${rentals.length} rentals');
      
      // FIXED: Log rental details for debugging
      for (var rental in rentals) {
        print('  📋 ${rental.id}: ${rental.peralatanNama} - Status: ${rental.status} - Payment: ${rental.paymentStatus}');
      }
      
      setState(() {
        _allRentals = rentals;
        _filteredRentals = rentals;
        _isLoading = false;
      });
      
      // Apply current filter
      _filterRentals();
    } catch (e) {
      print('❌ Error loading rentals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data sewa: $e';
      });
    }
  }

  void _filterRentals() {
    setState(() {
      if (_selectedStatus == 'Semua') {
        _filteredRentals = _allRentals;
      } else {
        _filteredRentals = _allRentals
            .where((rental) => rental.status == _selectedStatus)
            .toList();
      }
    });
    
    print('🔍 Filtered ${_filteredRentals.length} rentals for status: $_selectedStatus');
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterRentals();
  }

  Future<void> _cancelRental(Rent rental) async {
    try {
      final success = await RentService.cancelRental(
        rental.id,
        reason: 'Dibatalkan oleh pengguna',
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Sewa berhasil dibatalkan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        // Reload rentals
        await _loadRentals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membatalkan sewa: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Complete Rental Function
  Future<void> _completeRental(Rent rental) async {
    try {
      final success = await RentService.completeRental(rental.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Sewa telah diselesaikan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        // Reload rentals
        await _loadRentals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyelesaikan sewa: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelConfirmation(Rent rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Batalkan Sewa',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan sewa "${rental.peralatanNama}"?',
          style: GoogleFonts.poppins(
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRental(rental);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Batalkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Show Complete Confirmation Dialog
  void _showCompleteConfirmation(Rent rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Selesaikan Sewa',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menyelesaikan sewa "${rental.peralatanNama}"?',
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
                    '✅ Konfirmasi Penyelesaian',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dengan mengkonfirmasi, status sewa akan berubah menjadi "Selesai" dan tidak dapat diubah lagi.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green[700],
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
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeRental(rental);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Selesaikan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Navigate to payment with result handling
  void _navigateToPayment(Rent rental) async {
    print('💳 Navigating to payment for rental: ${rental.id}');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(rental: rental),
      ),
    );
    
    // FIXED: Check if payment was successful and refresh data
    if (result == true) {
      print('✅ Payment completed successfully, refreshing rental data...');
      await _loadRentals();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran berhasil! Status sewa telah diperbarui.',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      print('ℹ️ Payment page closed without completion, refreshing anyway...');
      // Refresh anyway in case there were changes
      await _loadRentals();
    }
  }

  void _showRentDetail(Rent rental) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Detail Sewa',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Equipment Name & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rental.peralatanNama,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildStatusChip(rental.status),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'ID: ${rental.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Details Grid
                    _buildDetailGrid(rental),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Info
                    _buildPaymentSection(rental),
                    
                    const SizedBox(height: 20),
                    
                    // Actions
                    if (rental.status == 'pending' || rental.status == 'confirmed' || rental.status == 'active')
                      _buildActionButtons(rental),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
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
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Riwayat Sewa',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_allRentals.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _loadRentals();
            },
            tooltip: 'Refresh',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (!UserService.isUserLoggedIn()) {
      return _buildLoginPrompt();
    }

    return Column(
      children: [
        // Status Filter
        _buildStatusFilter(),
        
        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Login Diperlukan',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan login untuk melihat riwayat sewa Anda',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: Text(
                'Login Sekarang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final label = _statusLabels[status] ?? status;
          final isSelected = status == _selectedStatus;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.teal[700],
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onStatusChanged(status),
              backgroundColor: Colors.white,
              selectedColor: Colors.teal[600],
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 1,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (_filteredRentals.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadRentals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRentals.length,
        itemBuilder: (context, index) {
          return _buildRentalCard(_filteredRentals[index]);
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRentals,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus == 'Semua' 
                  ? 'Belum Ada Riwayat Sewa'
                  : 'Tidak Ada Sewa ${_statusLabels[_selectedStatus]}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedStatus == 'Semua'
                  ? 'Mulai sewa peralatan camping untuk petualangan Anda'
                  : 'Belum ada sewa dengan status ${_statusLabels[_selectedStatus]?.toLowerCase()}',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BottomNav(currentIndex: 0),
                  ),
                );
              },
              icon: const Icon(Icons.explore),
              label: Text(
                'Jelajahi Peralatan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Responsive rental card with proper overflow handling
  Widget _buildRentalCard(Rent rental) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: () => _showRentDetail(rental),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with responsive layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.peralatanNama,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${rental.id}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(rental.status),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Details in responsive grid
                  isSmallScreen 
                      ? _buildSmallScreenDetails(rental)
                      : _buildLargeScreenDetails(rental),
                  
                  const SizedBox(height: 12),
                  
                  // Payment info with responsive layout
                  _buildPaymentInfoCard(rental, isSmallScreen),
                  
                  // Actions for pending/confirmed/active rentals
                  if (rental.status == 'pending' || rental.status == 'confirmed' || rental.status == 'active') ...[
                    const SizedBox(height: 12),
                    _buildRentalCardActions(rental, isSmallScreen),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // FIXED: Small screen details layout
  Widget _buildSmallScreenDetails(Rent rental) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Jumlah',
                '${rental.quantity} item',
                Icons.shopping_cart_outlined,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                'Durasi',
                '${rental.rentalDays} hari',
                Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Mulai',
                _formatDate(rental.startDate),
                Icons.play_arrow_outlined,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                'Selesai',
                _formatDate(rental.endDate),
                Icons.stop_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // FIXED: Large screen details layout
  Widget _buildLargeScreenDetails(Rent rental) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            'Jumlah',
            '${rental.quantity} item',
            Icons.shopping_cart_outlined,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            'Durasi',
            '${rental.rentalDays} hari',
            Icons.calendar_today_outlined,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            'Mulai',
            _formatDate(rental.startDate),
            Icons.play_arrow_outlined,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            'Selesai',
            _formatDate(rental.endDate),
            Icons.stop_outlined,
          ),
        ),
      ],
    );
  }

  // FIXED: Responsive payment info card
  Widget _buildPaymentInfoCard(Rent rental, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Harga:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              Flexible(
                child: Text(
                  'Rp ${_formatCurrency(rental.totalPrice)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[700],
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          if (rental.paidAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dibayar:',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                Flexible(
                  child: Text(
                    'Rp ${_formatCurrency(rental.paidAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pembayaran:',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[700],
                ),
              ),
              _buildPaymentStatusChip(rental.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Responsive card actions with Complete button for active status
  Widget _buildRentalCardActions(Rent rental, bool isSmallScreen) {
    List<Widget> actions = [];

    // Cancel button for pending rentals
    if (rental.status == 'pending') {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _showCancelConfirmation(rental),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(
            'Batalkan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange[600],
            side: BorderSide(color: Colors.orange[600]!),
          ),
        ),
      );
    }

    // Payment button for unpaid rentals
    if (rental.paymentStatus != 'paid') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _navigateToPayment(rental),
          icon: const Icon(Icons.payment),
          label: Text(
            rental.paymentStatus == 'unpaid' ? 'Bayar' : 'Bayar Sisa',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // NEW: Complete button for active rentals
    if (rental.status == 'active') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _showCompleteConfirmation(rental),
          icon: const Icon(Icons.check_circle),
          label: Text(
            'Selesaikan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    if (isSmallScreen) {
      // Stack actions vertically on small screens
      return Column(
        children: actions.map((action) => 
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: action,
          )
        ).toList(),
      );
    } else {
      // Horizontal layout for larger screens
      return Row(
        children: actions.map((action) => 
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: action,
            ),
          )
        ).toList(),
      );
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(Rent rental) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Jumlah', '${rental.quantity} item'),
              ),
              Expanded(
                child: _buildDetailRow('Durasi', '${rental.rentalDays} hari'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailRow('Mulai', _formatDate(rental.startDate)),
              ),
              Expanded(
                child: _buildDetailRow('Selesai', _formatDate(rental.endDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentSection(Rent rental) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Harga:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Flexible(
                child: Text(
                  'Rp ${_formatCurrency(rental.totalPrice)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          if (rental.paidAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dibayar:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Flexible(
                  child: Text(
                    'Rp ${_formatCurrency(rental.paidAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              _buildPaymentStatusChip(rental.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: Action buttons with Complete option for active rentals
  Widget _buildActionButtons(Rent rental) {
    List<Widget> actions = [];

    // Cancel button for pending rentals
    if (rental.status == 'pending') {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCancelConfirmation(rental);
            },
            icon: const Icon(Icons.cancel_outlined),
            label: Text(
              'Batalkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[600],
              side: BorderSide(color: Colors.orange[600]!),
            ),
          ),
        ),
      );
    }

    // Payment button for unpaid rentals
    if (rental.paymentStatus != 'paid') {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPayment(rental);
            },
            icon: const Icon(Icons.payment),
            label: Text(
              rental.paymentStatus == 'unpaid' ? 'Bayar Sekarang' : 'Bayar Sisa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // NEW: Complete button for active rentals
    if (rental.status == 'active') {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCompleteConfirmation(rental);
            },
            icon: const Icon(Icons.check_circle),
            label: Text(
              'Selesaikan Sewa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(children: actions);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange[600]!;
        label = 'Menunggu';
        break;
      case 'confirmed':
        color = Colors.blue[600]!;
        label = 'Dikonfirmasi';
        break;
      case 'active':
        color = Colors.green[600]!;
        label = 'Aktif';
        break;
      case 'completed':
        color = Colors.grey[600]!;
        label = 'Selesai';
        break;
      case 'cancelled':
        color = Colors.red[600]!;
        label = 'Dibatalkan';
        break;
      default:
        color = Colors.grey[600]!;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(String paymentStatus) {
    Color color;
    String label;
    
    switch (paymentStatus) {
      case 'unpaid':
        color = Colors.red[600]!;
        label = 'Belum Bayar';
        break;
      case 'dp':
        color = Colors.orange[600]!;
        label = 'DP';
        break;
      case 'paid':
        color = Colors.green[600]!;
        label = 'Lunas';
        break;
      case 'refunded':
        color = Colors.blue[600]!;
        label = 'Dikembalikan';
        break;
      default:
        color = Colors.grey[600]!;
        label = paymentStatus;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// FIXED: Add lifecycle observer for auto-refresh
class _AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;
  
  _AppLifecycleObserver({required this.onResume});
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}