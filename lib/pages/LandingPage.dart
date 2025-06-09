import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ApiService.dart';
import '../services/UserService.dart';
import '../services/FavoriteService.dart';
import '../models/Peralatan.dart';
import '../components/bottomNav.dart';
import 'LoginPage.dart';
import 'RentDetailPage.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Peralatan> _allPeralatan = [];
  List<Peralatan> _filteredPeralatan = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  String _errorMessage = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // FIXED: Dynamic categories from data
  List<String> _categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPeralatan();
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

  Future<void> _loadPeralatan() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final peralatanList = await ApiService.fetchPeralatan();
      
      // FIXED: Extract dynamic categories from data
      _extractCategoriesFromData(peralatanList);
      
      setState(() {
        _allPeralatan = peralatanList;
        _filteredPeralatan = peralatanList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data peralatan: $e';
      });
    }
  }

  // FIXED: Extract categories dynamically from data
  void _extractCategoriesFromData(List<Peralatan> peralatanList) {
    Set<String> categoriesSet = {'Semua'};
    for (var peralatan in peralatanList) {
      if (peralatan.kategori.isNotEmpty) {
        categoriesSet.add(peralatan.kategori);
      }
    }
    _categories = categoriesSet.toList();
  }

  void _filterPeralatan() {
    setState(() {
      _filteredPeralatan = _allPeralatan.where((peralatan) {
        final matchesSearch = peralatan.nama
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()) ||
            peralatan.deskripsi
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Semua' ||
            peralatan.kategori.toLowerCase() == _selectedCategory.toLowerCase();
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged() {
    _filterPeralatan();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterPeralatan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
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
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'SakuRimba',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () {
            if (UserService.isUserLoggedIn()) {
              // Navigate to profile
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadPeralatan,
      child: CustomScrollView(
        slivers: [
          // Search Section
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),
          
          // Category Filter
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: _buildErrorWidget(),
            )
          else if (_filteredPeralatan.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyWidget(),
            )
          else
            // FIXED: Responsive grid with better card layout
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPeralatanCard(_filteredPeralatan[index]),
                ),
                childCount: _filteredPeralatan.length,
              ),
            ),
          ),


        ],
      ),
    );
  }

  // FIXED: Better responsive grid calculations
  int _getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 1000) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }

double _getGridAspectRatio(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < 600) return 0.75;    // mobile: lebih tinggi
  if (w < 1000) return 0.80;   // tablet
  return 0.85;                  // desktop
}


  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cari Peralatan Camping',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => _onSearchChanged(),
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Cari tenda, sleeping bag, kompor...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.teal[700],
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _onCategoryChanged(category),
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

Widget _buildPeralatanCard(Peralatan peralatan) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RentDetailPage(peralatan: peralatan),
          ),
        );
      },
      child: Container(
        width: double.infinity, // biar full parent
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4/2, // 2:1, lebih lebar & cocok di list
              child: peralatan.image.isNotEmpty
                  ? Image.network(
                      peralatan.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama peralatan
                  Text(
                    peralatan.nama,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.teal[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      peralatan.kategori,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Harga dan stok
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Rp ${_formatCurrency(peralatan.harga)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                              TextSpan(
                                text: '/hari',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: peralatan.stok > 0
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: peralatan.stok > 0
                                ? Colors.green[200]!
                                : Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              peralatan.stok > 0
                                  ? Icons.inventory_2_outlined
                                  : Icons.remove_shopping_cart_outlined,
                              size: 14,
                              color: peralatan.stok > 0
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${peralatan.stok}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: peralatan.stok > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
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
          ],
        ),
      ),
    ),
  );
}




  // FIXED: Currency formatting helper
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Widget _buildFavoriteButton(Peralatan peralatan) {
    return FutureBuilder<bool>(
      future: FavoriteService.isFavorite(peralatan.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () async {
            if (UserService.isUserLoggedIn()) {
              await FavoriteService.toggleFavorite(peralatan);
              setState(() {});
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Silakan login untuk menambah favorit',
                    style: GoogleFonts.poppins(),
                  ),
                  action: SnackBarAction(
                    label: 'Login',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red[600] : Colors.grey[600],
              size: 18,
            ),
          ),
        );
      },
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
              onPressed: _loadPeralatan,
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
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah kata kunci pencarian atau filter kategori',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _onCategoryChanged('Semua');
              },
              icon: const Icon(Icons.clear_all),
              label: Text(
                'Reset Filter',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}