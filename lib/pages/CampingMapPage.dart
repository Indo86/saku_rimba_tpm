// IMPROVED: CampingMapPage.dart - Real Indonesian Data & Better UX
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../services/LocationService.dart';
import '../services/UserService.dart';

class CampingMapPage extends StatefulWidget {
  const CampingMapPage({super.key});

  @override
  State<CampingMapPage> createState() => _CampingMapPageState();
}

class _CampingMapPageState extends State<CampingMapPage> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _campingSpots = [];
  List<Map<String, dynamic>> _rentalShops = [];
  List<Map<String, dynamic>> _filteredSpots = [];
  List<Map<String, dynamic>> _filteredShops = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'Semua';
  double _radiusKm = 50.0;
  String? _currentLocation;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  final List<String> _filterOptions = [
    'Semua',
    'Gunung',
    'Pantai', 
    'Hutan',
    'Danau',
    'Perbukitan'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadLocationData();
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

  /// IMPROVED: Load location data using LocationService with real Indonesian data
  Future<void> _loadLocationData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Initialize location service
      await LocationService.init();
      
      // Check if location service is available
      if (!LocationService.isLocationEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Silakan aktifkan GPS.');
      }
      
      // Get current location for context
      final position = await LocationService.getCurrentLocation();
      final address = LocationService.currentAddress;
      
      setState(() {
        _currentLocation = address ?? 'Lokasi terdeteksi: ${position?.latitude.toStringAsFixed(4)}, ${position?.longitude.toStringAsFixed(4)}';
      });

      // Load nearby camping spots and rental shops with real data
      final spots = await LocationService.findNearbyCampingSpots(
        radiusKm: _radiusKm,
      );
      
      final shops = await LocationService.findNearbyRentalShops(
        radiusKm: _radiusKm,
      );

      setState(() {
        _campingSpots = spots;
        _rentalShops = shops;
        _filteredSpots = spots;
        _filteredShops = shops;
        _isLoading = false;
      });

      _applyFilter();
      
      print('✅ Loaded ${spots.length} camping spots and ${shops.length} rental shops');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      print('❌ Error loading location data: $e');
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'Semua') {
        _filteredSpots = _campingSpots;
      } else {
        _filteredSpots = _campingSpots.where((spot) {
          final type = spot['type'] as String? ?? '';
          return type.toLowerCase().contains(_selectedFilter.toLowerCase());
        }).toList();
      }
      
      // Shops are not filtered by type, only by radius
      _filteredShops = _rentalShops;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilter();
  }

  void _onRadiusChanged(double radius) {
    setState(() {
      _radiusKm = radius;
    });
    _loadLocationData(); // Reload with new radius
  }

  /// IMPROVED: Open navigation with better error handling and multiple options
  Future<void> _openNavigation(Map<String, dynamic> destination) async {
    try {
      final lat = destination['latitude'] as double?;
      final lng = destination['longitude'] as double?;
      final name = destination['name'] as String? ?? 'Destinasi';

      if (lat == null || lng == null) {
        throw Exception('Koordinat destinasi tidak valid');
      }

      // Show navigation options
      _showNavigationOptions(lat, lng, name);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka navigasi: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _showNavigationOptions(double lat, double lng, String name) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      // supaya bottom inset (keyboard / gesture bar) di-handle
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Aplikasi Navigasi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Menuju: $name',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                // list opsi
                _buildNavigationOption(
                  'Google Maps',
                  Icons.map,
                  Colors.green[600]!,
                  () => _launchGoogleMaps(lat, lng, name),
                ),
                const SizedBox(height: 12),
                _buildNavigationOption(
                  'Waze',
                  Icons.navigation,
                  Colors.blue[600]!,
                  () => _launchWaze(lat, lng),
                ),
                const SizedBox(height: 12),
                _buildNavigationOption(
                  'Apple Maps',
                  Icons.map_outlined,
                  Colors.grey[700]!,
                  () => _launchAppleMaps(lat, lng, name),
                ),
                const SizedBox(height: 12),
                _buildNavigationOption(
                  'Browser Maps',
                  Icons.public,
                  Colors.orange[600]!,
                  () => _launchBrowserMaps(lat, lng, name),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildNavigationOption(String name, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // Navigation app launchers with better URL formats
  Future<void> _launchGoogleMaps(double lat, double lng, String name) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    await _launchUrl(url, 'Google Maps');
  }

  Future<void> _launchWaze(double lat, double lng) async {
    final url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    await _launchUrl(url, 'Waze');
  }

  Future<void> _launchAppleMaps(double lat, double lng, String name) async {
    final encodedName = Uri.encodeComponent(name);
    final url = 'https://maps.apple.com/?q=$encodedName&ll=$lat,$lng';
    await _launchUrl(url, 'Apple Maps');
  }

  Future<void> _launchBrowserMaps(double lat, double lng, String name) async {
    final url = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=15&layers=M';
    await _launchUrl(url, 'OpenStreetMap');
  }

  Future<void> _launchUrl(String url, String appName) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Navigator.pop(context); // Close the bottom sheet
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Membuka $appName...',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Tidak dapat membuka $appName');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka $appName: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// IMPROVED: Show detailed destination information
  void _showDestinationDetail(Map<String, dynamic> destination) {
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getDestinationIcon(destination),
                          color: Colors.teal[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination['name'] ?? 'Destinasi',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (destination['distance'] != null)
                              Text(
                                '${(destination['distance'] as double).toStringAsFixed(1)} km dari Anda',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                    // Basic Info
                    _buildInfoSection('Informasi Dasar', [
                      _buildInfoRow('Lokasi', destination['location'] ?? 'Tidak tersedia'),
                      _buildInfoRow('Jenis', destination['type'] ?? 'Camping'),
                      if (destination['rating'] != null)
                        _buildInfoRow('Rating', '⭐ ${destination['rating']}'),
                      if (destination['elevation'] != null)
                        _buildInfoRow('Ketinggian', '${destination['elevation']} mdpl'),
                      if (destination['difficulty'] != null)
                        _buildInfoRow('Tingkat Kesulitan', destination['difficulty']),
                      if (destination['estimatedTime'] != null)
                        _buildInfoRow('Estimasi Waktu', destination['estimatedTime']),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Features
                    if (destination['features'] != null)
                      _buildFeaturesSection(destination['features']),
                    
                    const SizedBox(height: 20),
                    
                    // Facilities
                    if (destination['facilities'] != null)
                      _buildFacilitiesSection(destination['facilities']),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    if (destination['description'] != null)
                      _buildDescriptionSection(destination['description']),
                    
                    const SizedBox(height: 20),
                    
                    // Tips
                    _buildTipsSection(destination),
                    
                    const SizedBox(height: 20),
                    
                    // Navigation Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openNavigation(destination);
                        },
                        icon: const Icon(Icons.navigation),
                        label: Text(
                          'Buka Navigasi',
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
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDestinationIcon(Map<String, dynamic> destination) {
    final type = destination['type'] as String? ?? '';
    switch (type.toLowerCase()) {
      case 'gunung':
        return Icons.terrain;
      case 'pantai':
        return Icons.beach_access;
      case 'hutan':
        return Icons.forest;
      case 'danau':
        return Icons.water;
      case 'perbukitan':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(': ', style: GoogleFonts.poppins(fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(String features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasilitas & Fitur',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            features,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection(List<dynamic> facilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasilitas Tersedia',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facilities.map((facility) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Text(
              facility.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(Map<String, dynamic> destination) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Tips Camping',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getCampingTips(destination),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getCampingTips(Map<String, dynamic> destination) {
    final type = destination['type'] as String? ?? '';
    final elevation = destination['elevation'] as int? ?? 0;
    
    switch (type.toLowerCase()) {
      case 'gunung':
        if (elevation > 2000) {
          return 'Bawa jaket tebal, suhu bisa mencapai 5-10°C di malam hari. Siapkan sleeping bag yang sesuai. Cek cuaca sebelum mendaki.';
        } else {
          return 'Bawa jaket ringan untuk malam hari. Pastikan kondisi fisik prima. Jangan lupa bawa air yang cukup.';
        }
      case 'pantai':
        return 'Gunakan sunscreen dan topi. Bawa air tawar untuk mandi. Waspada air pasang. Siapkan tenda yang tahan angin.';
      case 'danau':
        return 'Lokasi biasanya lembab, bawa pakaian ganti. Hati-hati dengan tepi danau yang licin. Manfaatkan air untuk keperluan masak.';
      case 'hutan':
        return 'Bawa obat nyamuk dan antiseptik. Gunakan sepatu tertutup. Jangan tinggalkan makanan terbuka. Waspada satwa liar.';
      default:
        return 'Selalu bawa P3K, senter, dan power bank. Cek kondisi cuaca. Beritahu rencana perjalanan ke keluarga.';
    }
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Peta Camping',
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
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadLocationData,
          tooltip: 'Refresh Lokasi',
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showFilterDialog,
          tooltip: 'Filter',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Camping',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Rental',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Current Location Banner
        _buildLocationBanner(),
        
        // Filter Chips
        _buildFilterChips(),
        
        // Content Tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCampingSpotsTab(),
              _buildRentalShopsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.teal[100],
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.teal[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentLocation ?? 'Memuat lokasi...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.teal[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Radius: ${_radiusKm.toInt()} km',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.teal[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = filter == _selectedFilter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.teal[700],
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(filter),
              backgroundColor: Colors.white,
              selectedColor: Colors.teal[600],
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Colors.teal[600]! : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampingSpotsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (_filteredSpots.isEmpty) {
      return _buildEmptyWidget('camping spots');
    }

    return RefreshIndicator(
      onRefresh: _loadLocationData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSpots.length,
        itemBuilder: (context, index) {
          return _buildDestinationCard(_filteredSpots[index]);
        },
      ),
    );
  }

  Widget _buildRentalShopsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredShops.isEmpty) {
      return _buildEmptyWidget('rental shops');
    }

    return RefreshIndicator(
      onRefresh: _loadLocationData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          return _buildRentalShopCard(_filteredShops[index]);
        },
      ),
    );
  }

  Widget _buildDestinationCard(Map<String, dynamic> destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDestinationDetail(destination),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDestinationIcon(destination),
                      color: Colors.teal[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination['name'] ?? 'Destinasi',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          destination['location'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (destination['distance'] != null)
                        Text(
                          '${(destination['distance'] as double).toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                      if (destination['rating'] != null)
                        Text(
                          '⭐ ${destination['rating']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (destination['features'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  destination['features'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDestinationDetail(destination),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: Text(
                        'Detail',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal[600],
                        side: BorderSide(color: Colors.teal[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openNavigation(destination),
                      icon: const Icon(Icons.navigation, size: 16),
                      label: Text(
                        'Navigasi',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRentalShopCard(Map<String, dynamic> shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openNavigation(shop),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'] ?? 'Toko Rental',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          shop['address'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (shop['distance'] != null)
                        Text(
                          '${(shop['distance'] as double).toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                      if (shop['rating'] != null)
                        Text(
                          '⭐ ${shop['rating']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (shop['openHours'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      shop['openHours'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              
              if (shop['priceRange'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      shop['priceRange'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (shop['equipment'] != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: (shop['equipment'] as List<String>)
                      .take(3)
                      .map((item) => Chip(
                            label: Text(
                              item,
                              style: GoogleFonts.poppins(fontSize: 10),
                            ),
                            backgroundColor: Colors.grey[100],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openNavigation(shop),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: Text(
                    'Navigasi ke Toko',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              onPressed: _loadLocationData,
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

  Widget _buildEmptyWidget(String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'camping spots' ? Icons.place_outlined : Icons.store_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak Ada ${type == 'camping spots' ? 'Spot Camping' : 'Toko Rental'}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Coba perluas radius pencarian atau ubah filter',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.tune),
              label: Text(
                'Ubah Filter',
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Filter Pencarian',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Radius Pencarian',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Slider(
              value: _radiusKm,
              min: 10,
              max: 200,
              divisions: 19,
              label: '${_radiusKm.toInt()} km',
              onChanged: (value) {
                setState(() {
                  _radiusKm = value;
                });
              },
              activeColor: Colors.teal[600],
            ),
            Text(
              'Radius: ${_radiusKm.toInt()} km',
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
              _onRadiusChanged(_radiusKm);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Terapkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}