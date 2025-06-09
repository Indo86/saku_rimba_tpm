import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/Peralatan.dart';
import '../services/RentService.dart';
import '../services/UserService.dart';
import '../services/FavoriteService.dart';
import 'LoginPage.dart';

class RentDetailPage extends StatefulWidget {
  final Peralatan peralatan;

  const RentDetailPage({
    super.key,
    required this.peralatan,
  });

  @override
  State<RentDetailPage> createState() => _RentDetailPageState();
}

class _RentDetailPageState extends State<RentDetailPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  int _quantity = 1;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  bool _isFavorite = false;
  bool _isLoading = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserPhone();
    _checkFavoriteStatus();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  Future<void> _loadUserPhone() async {
    final user = UserService.getCurrentUser();
    if (user != null && user.phone.isNotEmpty) {
      setState(() {
        _phoneController.text = user.phone;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (UserService.isUserLoggedIn()) {
      final isFav = await FavoriteService.isFavorite(widget.peralatan.id);
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  int get _rentalDays => _endDate.difference(_startDate).inDays;
  double get _totalPrice => _quantity * _rentalDays * widget.peralatan.harga.toDouble();
  double get _minimumDP => _totalPrice * 0.5;

  void _updateQuantity(String value) {
    final quantity = int.tryParse(value) ?? 0;
    if (quantity > 0 && quantity <= widget.peralatan.stok) {
      setState(() {
        _quantity = quantity;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (!UserService.isUserLoggedIn()) {
      _showLoginPrompt();
      return;
    }
    try {
      await FavoriteService.toggleFavorite(widget.peralatan);
      setState(() {
        _isFavorite = !_isFavorite;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: _isFavorite ? Colors.red[600] : Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengubah favorit: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRental() async {
    if (!UserService.isUserLoggedIn()) {
      _showLoginPrompt();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jumlah peralatan harus lebih dari 0',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (widget.peralatan.stok < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok tidak mencukupi. Stok tersedia: ${widget.peralatan.stok}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_rentalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tanggal selesai harus setelah tanggal mulai',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final rentalId = await RentService.createRental(
        peralatanId: widget.peralatan.id,
        peralatanNama: widget.peralatan.nama,
        quantity: _quantity,
        rentalDays: _rentalDays,
        pricePerDay: widget.peralatan.harga.toDouble(),
        startDate: _startDate,
        endDate: _endDate,
        userPhone: _phoneController.text.trim(),
      );
      if (rentalId != null) {
        if (mounted) _showSuccessDialog(rentalId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat rental. Silakan coba lagi.', style: GoogleFonts.poppins(),),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins(),),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.teal[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Login Diperlukan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login terlebih dahulu untuk menyewa peralatan ini',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Batal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String rentalId) {
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
            Text('Rental Berhasil', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rental Anda telah berhasil dibuat dengan ID: $rentalId', style: GoogleFonts.poppins()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💰 Info Pembayaran', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.orange[700])),
                  const SizedBox(height: 4),
                  Text('Anda dapat membayar DP (50%) atau langsung lunas. Silakan cek menu "Sewa" untuk melakukan pembayaran.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[700])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.teal[600])),
          ),
        ],
      ),
    );
  }

  // ---- FIXED: BOTTOM SHEET RENTAL FORM DENGAN STATEFULBUILDER ----
  void _showRentalForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Temporary copy untuk date & quantity agar realtime di modal
        DateTime startDate = _startDate;
        DateTime endDate = _endDate;
        int quantity = _quantity;

        return StatefulBuilder(
          builder: (context, setModalState) {
            int rentalDays = endDate.difference(startDate).inDays;
            double totalPrice = quantity * rentalDays * widget.peralatan.harga.toDouble();
            double minDP = totalPrice * 0.5;

            return SlideTransition(
              position: _slideAnimation,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // HEADER
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
                            'Sewa ${widget.peralatan.nama}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // FORM
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Input
                              _buildSectionTitle('Jumlah Peralatan'),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan jumlah peralatan',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.add_shopping_cart, color: Colors.teal[600]),
                                  suffixText: 'unit',
                                  suffixStyle: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.teal[600]!,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red[400]!),
                                  ),
                                  fillColor: Colors.grey[50],
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Jumlah peralatan diperlukan';
                                  }
                                  final qty = int.tryParse(value.trim());
                                  if (qty == null) return 'Masukkan angka yang valid';
                                  if (qty <= 0) return 'Jumlah harus lebih dari 0';
                                  if (qty > widget.peralatan.stok) return 'Melebihi stok tersedia (${widget.peralatan.stok})';
                                  return null;
                                },
                                onChanged: (value) {
                                  final qty = int.tryParse(value) ?? 1;
                                  setModalState(() {
                                    quantity = qty;
                                  });
                                  setState(() {
                                    _quantity = qty;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stok tersedia: ${widget.peralatan.stok} unit',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // DATE PICKER DENGAN STATEFULBUILDER
                              _buildSectionTitle('Periode Sewa'),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: Column(
                                  children: [
                                    // Start Date
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: startDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null && picked != startDate) {
                                          setModalState(() { startDate = picked; });
                                          setState(() { _startDate = picked; });
                                          // Ensure end date > start date
                                          if (endDate.isBefore(picked.add(const Duration(days: 1)))) {
                                            setModalState(() { endDate = picked.add(const Duration(days: 1)); });
                                            setState(() { _endDate = picked.add(const Duration(days: 1)); });
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: Colors.teal[600], size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Tanggal Mulai', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                                  const SizedBox(height: 4),
                                                  Text(_formatDateLong(startDate), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // End Date
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: endDate,
                                          firstDate: startDate.add(const Duration(days: 1)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null && picked != endDate) {
                                          setModalState(() { endDate = picked; });
                                          setState(() { _endDate = picked; });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.event, color: Colors.teal[600], size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Tanggal Selesai', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                                  const SizedBox(height: 4),
                                                  Text(_formatDateLong(endDate), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Durasi
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, color: Colors.blue[600], size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Durasi sewa: $rentalDays hari',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Phone Number
                              _buildSectionTitle('Nomor Telepon'),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nomor telepon',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.phone, color: Colors.teal[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.teal[600]!,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red[400]!),
                                  ),
                                  fillColor: Colors.grey[50],
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nomor telepon diperlukan';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Nomor telepon minimal 10 digit';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Price Summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal[200]!),
                                ),
                                child: Column(
                                  children: [
                                    _buildPriceRow('Harga per hari', 'Rp ${widget.peralatan.harga.toString()}'),
                                    _buildPriceRow('Jumlah', '$quantity unit'),
                                    _buildPriceRow('Durasi', '$rentalDays hari'),
                                    const Divider(color: Colors.teal),
                                    _buildPriceRow('Total Harga', 'Rp ${totalPrice.toStringAsFixed(0)}', isTotal: true),
                                    _buildPriceRow('Minimum DP (50%)', 'Rp ${minDP.toStringAsFixed(0)}', isSubtext: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // BUTTON
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            // Sync all value ke parent sebelum submit
                            setState(() {
                              _startDate = startDate;
                              _endDate = endDate;
                              _quantity = quantity;
                            });
                            _submitRental();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : Text('Sewa Sekarang', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isSubtext = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isSubtext ? 12 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isSubtext ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSubtext ? 12 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? Colors.teal[700] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateLong(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _phoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.teal[800],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: widget.peralatan.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.peralatan.image),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: widget.peralatan.image.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red[400] : Colors.white,
                ),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.peralatan.nama,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.peralatan.kategori,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.peralatan.stok > 0 ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stok: ${widget.peralatan.stok}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.peralatan.stok > 0 ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rp ${widget.peralatan.harga.toString()}/hari',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Details Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Peralatan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Kapasitas', '${widget.peralatan.kapasitas} orang'),
                      _buildDetailRow('Lokasi', widget.peralatan.lokasi),
                      _buildDetailRow('Tahun Beli', widget.peralatan.tahunDibeli.toString()),
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.peralatan.deskripsi.isNotEmpty
                            ? widget.peralatan.deskripsi
                            : 'Tidak ada deskripsi tersedia.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ],
      ),
      // Floating Action Button
      floatingActionButton: widget.peralatan.stok > 0
          ? FloatingActionButton.extended(
              onPressed: _showRentalForm,
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Sewa Sekarang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.block),
              label: Text(
                'Stok Habis',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
