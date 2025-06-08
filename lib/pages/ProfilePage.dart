// UPDATED: ProfilePage with Map Integration
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/UserService.dart';
import '../services/RentService.dart';
import '../services/NotificationService.dart';
import '../services/LocationService.dart'; // FIXED: Add LocationService
import '../models/user.dart';
import '../components/bottomNav.dart';
import 'LoginPage.dart';
import 'SettingsPage.dart';
import 'EditProfilePage.dart' as editProfile;
import 'NotificationPage.dart';
import 'RentPage.dart' as rentPage;
import 'CurrencyConverterPage.dart' as currencyConverter;
import 'TimeConverterPage.dart';
import 'SuggestionPage.dart';
import 'SensorPage.dart';
import 'CampingMapPage.dart'; // FIXED: Add CampingMapPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  User? _currentUser;
  Map<String, dynamic> _userStats = {};
  bool _isLoading = true;
  String? _currentLocation;
  bool _locationLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _getCurrentLocation();
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

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (!UserService.isUserLoggedIn()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load user data
      final user = UserService.getCurrentUser();
      
      // Load user statistics
      final stats = await RentService.getRentalStats();
      
      setState(() {
        _currentUser = user;
        _userStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat data profil: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _locationLoading = true;
      });

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Lokasi tidak diizinkan';
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Izin lokasi ditolak permanen';
          _locationLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = 'Magelang, Jawa Tengah (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _locationLoading = false;
      });

    } catch (e) {
      setState(() {
        _currentLocation = 'Gagal mendapatkan lokasi';
        _locationLoading = false;
      });
    }
  }

  // FIXED: Navigate to camping map
  void _navigateToCampingMap() async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Izin lokasi diperlukan untuk menggunakan peta',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Silakan aktifkan izin lokasi di pengaturan untuk menggunakan peta',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to camping map
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CampingMapPage(),
        ),
      );
    } catch (e) {
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
  }

  void _findNearbyCampingSpots() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                color: Colors.green[50],
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
                    '🏕️ Spot Camping Terdekat',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentLocation ?? 'Memuat lokasi...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildCampingSpotCard(
                    'Gunung Merbabu',
                    '15 km dari lokasi Anda',
                    'Basecamp New Selo',
                    '⭐ 4.5 • 🌲 Hutan Pinus • 🏔️ 3.145 mdpl',
                    Icons.terrain,
                    Colors.green[600]!,
                    -7.4550, 110.4403, // Sample coordinates
                  ),
                  _buildCampingSpotCard(
                    'Umbul Ponggok',
                    '12 km dari lokasi Anda',
                    'Klaten, Jawa Tengah',
                    '⭐ 4.3 • 🏊 Mata Air • 📸 Spot Foto',
                    Icons.water,
                    Colors.blue[600]!,
                    -7.6517, 110.7222,
                  ),
                  _buildCampingSpotCard(
                    'Kaliurang',
                    '25 km dari lokasi Anda',
                    'Sleman, DI Yogyakarta',
                    '⭐ 4.4 • 🌋 Lereng Merapi • 🌡️ Sejuk',
                    Icons.volcano,
                    Colors.orange[600]!,
                    -7.5954, 110.4189,
                  ),
                  _buildCampingSpotCard(
                    'Ketep Pass',
                    '8 km dari lokasi Anda',
                    'Magelang, Jawa Tengah',
                    '⭐ 4.6 • 🌅 Sunrise • 🔭 Observatory',
                    Icons.landscape,
                    Colors.purple[600]!,
                    -7.4711, 110.3175,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // FIXED: Button to open full map
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCampingMap();
                      },
                      icon: const Icon(Icons.map),
                      label: Text(
                        'Buka Peta Lengkap & Navigasi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampingSpotCard(String name, String distance, String location, String features, IconData icon, Color color, double lat, double lng) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              distance,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              features,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        onTap: () {
          // FIXED: Quick navigation option
          _showQuickNavigationDialog(name, lat, lng);
        },
      ),
    );
  }

  void _showQuickNavigationDialog(String name, double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.navigation, color: Colors.teal[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Navigasi ke $name',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Pilih aplikasi untuk navigasi ke $name',
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
              Navigator.pop(context);
              _navigateToCampingMap();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Buka Peta',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Clear user session
      await UserService.clearCurrentUser();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        // Show logout message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Berhasil logout',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.teal[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal logout: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun?',
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
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Profil',
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
        if (UserService.isUserLoggedIn()) ...[
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            tooltip: 'Pengaturan',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    if (!UserService.isUserLoggedIn()) {
      return _buildLoginPrompt();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsSection(),
            _buildLocationSection(),
            _buildMenuSection(),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
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
              Icons.person_outline,
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
              'Silakan login untuk mengakses profil dan fitur lainnya',
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

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal[800]!,
            Colors.teal[600]!,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Picture
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _currentUser?.profileImage != null && _currentUser!.profileImage.isNotEmpty
                      ? Image.network(
                          _currentUser!.profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // User Name
              Text(
                _currentUser?.nama.isNotEmpty == true 
                    ? _currentUser!.nama 
                    : _currentUser?.username ?? 'User',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Username
              if (_currentUser?.nama.isNotEmpty == true)
                Text(
                  '@${_currentUser?.username ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Profile Completion
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Profil ${UserService.getUserProfileCompletion().toInt()}% lengkap',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
            'Statistik Saya',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Sewa',
                  '${_userStats['total'] ?? 0}',
                  Icons.receipt_long,
                  Colors.blue[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Aktif',
                  '${_userStats['active'] ?? 0}',
                  Icons.schedule,
                  Colors.green[600]!,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Selesai',
                  '${_userStats['completed'] ?? 0}',
                  Icons.check_circle,
                  Colors.teal[600]!,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_userStats['totalSpent'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Total Pengeluaran: ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Rp ${(_userStats['totalSpent'] as double).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Lokasi Saat Ini',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (_locationLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green[600],
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[600], size: 20),
                  onPressed: _getCurrentLocation,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _currentLocation ?? 'Memuat lokasi...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _findNearbyCampingSpots,
                  icon: const Icon(Icons.explore, size: 18),
                  label: Text(
                    'Spot Terdekat',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToCampingMap,
                  icon: const Icon(Icons.map, size: 18),
                  label: Text(
                    'Buka Peta',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuCard([
            _buildMenuItem(
              'Edit Profil',
              'Ubah informasi dan foto profil',
              Icons.edit,
              () => _navigateToEditProfile(),
            ),
            _buildMenuItem(
              'Notifikasi',
              'Kelola pengaturan notifikasi',
              Icons.notifications,
              () => _navigateToNotifications(),
            ),
            _buildMenuItem(
              'Riwayat Sewa',
              'Lihat semua riwayat penyewaan',
              Icons.history,
              () => _navigateToRentHistory(),
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildMenuCard([
            // FIXED: Add Map menu item
            _buildMenuItem(
              'Peta Camping',
              'Temukan spot camping dan navigasi',
              Icons.map,
              () => _navigateToCampingMap(),
            ),
            _buildMenuItem(
              'Sensor Monitor',
              'Kompas, water level, dan sensor outdoor',
              Icons.sensors,
              () => _navigateToSensor(),
            ),
            _buildMenuItem(
              'Konversi Mata Uang',
              'Konverter mata uang global',
              Icons.currency_exchange,
              () => _navigateToCurrencyConverter(),
            ),
            _buildMenuItem(
              'Konversi Waktu',
              'Konverter zona waktu',
              Icons.access_time,
              () => _navigateToTimeConverter(),
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildMenuCard([
            _buildMenuItem(
              'Pengaturan',
              'Kelola pengaturan aplikasi',
              Icons.settings,
              () => _navigateToSettings(),
            ),
            _buildMenuItem(
              'Saran & Kesan',
              'Mata Kuliah Mobile Programming',
              Icons.school,
              () => _navigateToSuggestion(),
            ),
            _buildMenuItem(
              'Bantuan',
              'FAQ dan dukungan pelanggan',
              Icons.help,
              () => _navigateToHelp(),
            ),
            _buildMenuItem(
              'Tentang Aplikasi',
              'Informasi tentang SakuRimba',
              Icons.info,
              () => _navigateToAbout(),
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Logout Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(Icons.logout),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[600]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.teal[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  // Navigation methods
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const editProfile.EditProfilePage(),
      ),
    ).then((_) => _loadUserData()); // Reload data when returning
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),
    );
  }

  void _navigateToRentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const rentPage.RentPage(),
      ),
    );
  }

  void _navigateToSensor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SensorPage(),
      ),
    );
  }

  void _navigateToCurrencyConverter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const currencyConverter.CurrencyConverterPage(),
      ),
    );
  }

  void _navigateToTimeConverter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimeConverterPage(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToSuggestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuggestionPage(),
      ),
    );
  }

  void _navigateToHelp() {
    // TODO: Implement help page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Fitur bantuan akan segera tersedia',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  void _navigateToAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.backpack, color: Colors.teal[600]),
            const SizedBox(width: 8),
            Text(
              'SakuRimba',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Alat Camping',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi penyewaan peralatan camping yang memudahkan petualangan outdoor Anda dengan fitur sensor monitoring, lokasi, dan navigasi terintegrasi.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Versi: 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.teal[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}