// services/FavoriteService.dart (SakuRimba)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../models/Peralatan.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoriteService {
  // API endpoint untuk data peralatan
  static const String _apiEndpoint = 'https://your-api-endpoint.com/api/peralatan';

  // Get current user ID dari UserService
  static String? getCurrentUserId() {
    return UserService.getCurrentUsername();
  }

  // Get favorite peralatan IDs for current user dari Hive
  static Future<Set<String>> getFavoriteIds() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favoritesBox = await HiveService.getFavoritesBox(userId);
      final favoriteIds = favoritesBox.keys.cast<String>().toSet();
      print('📱 Loaded ${favoriteIds.length} favorite IDs for user: $userId');
      return favoriteIds;
    } catch (e) {
      print('❌ Error getting favorite IDs: $e');
      return <String>{};
    }
  }

  // Get favorite peralatan details by fetching from API
  static Future<List<Peralatan>> getFavoritePeralatan() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Get favorites from Hive
      final favorites = await HiveService.getFavorites(userId);
      if (favorites.isEmpty) return [];

      List<Peralatan> favoritePeralatan = [];
      
      for (var favoriteData in favorites) {
        try {
          // Try to create Peralatan from stored data first
          if (favoriteData.containsKey('id') && 
              favoriteData.containsKey('nama') && 
              favoriteData.containsKey('kategori')) {
            favoritePeralatan.add(Peralatan.fromJson(favoriteData));
          }
        } catch (e) {
          print('❌ Error parsing stored peralatan data: $e');
          // If stored data is corrupted, try to fetch from API
          if (favoriteData.containsKey('id')) {
            try {
              final response = await http.get(Uri.parse(
                  '$_apiEndpoint/${favoriteData['id']}'));
              
              if (response.statusCode == 200) {
                final peralatanData = json.decode(response.body);
                favoritePeralatan.add(Peralatan.fromJson(peralatanData));
              }
            } catch (apiError) {
              print('❌ Error fetching peralatan from API: $apiError');
            }
          }
        }
      }
      
      print('✅ Successfully loaded ${favoritePeralatan.length} favorite peralatan for user: $userId');
      return favoritePeralatan;
    } catch (e) {
      print('❌ Error getting favorite peralatan: $e');
      return [];
    }
  }

  // Add peralatan to favorites using Hive
  static Future<bool> addToFavorites(Peralatan peralatan) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Check if already in favorites
      if (await isFavorite(peralatan.id)) {
        print('ℹ️ Peralatan ${peralatan.id} already in favorites for user: $userId');
        return false;
      }

      // Add to Hive favorites
      await HiveService.addToFavorites(userId, peralatan.id, peralatan.toJson());
      print('✅ Added peralatan ${peralatan.id} to favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  // Remove peralatan from favorites
  static Future<bool> removeFromFavorites(String peralatanId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Check if in favorites
      if (!await isFavorite(peralatanId)) {
        print('ℹ️ Peralatan $peralatanId not in favorites for user: $userId');
        return false;
      }

      // Remove from Hive favorites
      await HiveService.removeFromFavorites(userId, peralatanId);
      print('✅ Removed peralatan $peralatanId from favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(Peralatan peralatan) async {
    try {
      final isFav = await isFavorite(peralatan.id);
      
      if (isFav) {
        return await removeFromFavorites(peralatan.id);
      } else {
        return await addToFavorites(peralatan);
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      return false;
    }
  }

  // Check if peralatan is favorite using Hive
  static Future<bool> isFavorite(String peralatanId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final result = await HiveService.isFavorite(userId, peralatanId);
      return result;
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Clear all favorites for current user
  static Future<void> clearAllFavorites() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      final favoritesBox = await HiveService.getFavoritesBox(userId);
      await favoritesBox.clear();
      print('✅ Cleared all favorites for user: $userId');
    } catch (e) {
      print('❌ Error clearing favorites: $e');
    }
  }

  // Get favorite count
  static Future<int> getFavoriteCount() async {
    try {
      final favoriteIds = await getFavoriteIds();
      return favoriteIds.length;
    } catch (e) {
      print('❌ Error getting favorite count: $e');
      return 0;
    }
  }

  // Search in favorites
  static Future<List<Peralatan>> searchFavorites(String query) async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      
      if (query.isEmpty) return favoritePeralatan;
      
      final searchLower = query.toLowerCase();
      return favoritePeralatan.where((peralatan) {
        return peralatan.nama.toLowerCase().contains(searchLower) ||
               peralatan.kategori.toLowerCase().contains(searchLower) ||
               peralatan.deskripsi.toLowerCase().contains(searchLower) ||
               peralatan.lokasi.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      print('❌ Error searching favorites: $e');
      return [];
    }
  }

  // Filter favorites by category
  static Future<List<Peralatan>> getFavoritesByCategory(String category) async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      
      if (category.isEmpty || category.toLowerCase() == 'semua') {
        return favoritePeralatan;
      }
      
      return favoritePeralatan.where((peralatan) => 
        peralatan.kategori.toLowerCase() == category.toLowerCase()
      ).toList();
    } catch (e) {
      print('❌ Error filtering favorites by category: $e');
      return [];
    }
  }

  // Get favorite categories
  static Future<List<String>> getFavoriteCategories() async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      final categories = favoritePeralatan
          .map((peralatan) => peralatan.kategori)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      print('❌ Error getting favorite categories: $e');
      return [];
    }
  }

  // Sort favorites by different criteria
  static Future<List<Peralatan>> sortFavorites(String sortBy) async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      
      switch (sortBy.toLowerCase()) {
        case 'nama':
          favoritePeralatan.sort((a, b) => a.nama.compareTo(b.nama));
          break;
        case 'kategori':
          favoritePeralatan.sort((a, b) => a.kategori.compareTo(b.kategori));
          break;
        case 'harga':
          favoritePeralatan.sort((a, b) => a.harga.compareTo(b.harga));
          break;
        case 'harga_desc':
          favoritePeralatan.sort((a, b) => b.harga.compareTo(a.harga));
          break;
        case 'tahun':
          favoritePeralatan.sort((a, b) => b.tahunDibeli.compareTo(a.tahunDibeli));
          break;
        case 'stok':
          favoritePeralatan.sort((a, b) => b.stok.compareTo(a.stok));
          break;
        default:
          favoritePeralatan.sort((a, b) => a.nama.compareTo(b.nama));
      }
      
      return favoritePeralatan;
    } catch (e) {
      print('❌ Error sorting favorites: $e');
      return [];
    }
  }

  // Get favorites with availability filter
  static Future<List<Peralatan>> getAvailableFavorites() async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      return favoritePeralatan.where((peralatan) => peralatan.stok > 0).toList();
    } catch (e) {
      print('❌ Error getting available favorites: $e');
      return [];
    }
  }

  // Export favorites (untuk backup)
  static Future<Map<String, dynamic>> exportFavorites() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favorites = await HiveService.getFavorites(userId);
      final favoriteIds = await getFavoriteIds();
      final categories = await getFavoriteCategories();
      
      return {
        'userId': userId,
        'favoriteIds': favoriteIds.toList(),
        'favoriteData': favorites,
        'categories': categories,
        'exportDate': DateTime.now().toIso8601String(),
        'count': favoriteIds.length,
        'version': '1.0',
      };
    } catch (e) {
      print('❌ Error exporting favorites: $e');
      return {};
    }
  }

  // Import favorites (untuk restore)
  static Future<bool> importFavorites(Map<String, dynamic> data) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favoriteData = data['favoriteData'] as List<Map<String, dynamic>>?;
      if (favoriteData == null) return false;

      // Clear existing favorites
      await clearAllFavorites();

      // Add imported favorites
      for (var peralatanData in favoriteData) {
        if (peralatanData.containsKey('id')) {
          await HiveService.addToFavorites(userId, peralatanData['id'], peralatanData);
        }
      }

      print('✅ Imported ${favoriteData.length} favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error importing favorites: $e');
      return false;
    }
  }

  // Check if user is logged in
  static bool isUserLoggedIn() {
    return UserService.isUserLoggedIn() && getCurrentUserId() != null;
  }

  // Initialize favorites for user (dipanggil saat login)
  static Future<void> initializeFavoritesForUser(String userId) async {
    try {
      // Pastikan favorites box untuk user dibuka
      await HiveService.getFavoritesBox(userId);
      print('✅ Initialized favorites for user: $userId');
    } catch (e) {
      print('❌ Error initializing favorites for user: $e');
    }
  }

  // Get favorite statistics
  static Future<Map<String, dynamic>> getFavoriteStats() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return {};

      final favoritePeralatan = await getFavoritePeralatan();
      final categories = await getFavoriteCategories();
      
      // Calculate stats
      int totalFavorites = favoritePeralatan.length;
      int availableItems = favoritePeralatan.where((p) => p.stok > 0).length;
      int totalValue = favoritePeralatan.fold(0, (sum, p) => sum + p.harga);
      double avgPrice = totalFavorites > 0 ? totalValue / totalFavorites : 0;
      
      // Category breakdown
      Map<String, int> categoryBreakdown = {};
      for (var category in categories) {
        categoryBreakdown[category] = favoritePeralatan
            .where((p) => p.kategori == category)
            .length;
      }
      
      return {
        'totalFavorites': totalFavorites,
        'availableItems': availableItems,
        'unavailableItems': totalFavorites - availableItems,
        'totalValue': totalValue,
        'averagePrice': avgPrice,
        'categoriesCount': categories.length,
        'categoryBreakdown': categoryBreakdown,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting favorite stats: $e');
      return {};
    }
  }

  // Get recommendations based on favorites
  static Future<List<String>> getRecommendedCategories() async {
    try {
      final favoritePeralatan = await getFavoritePeralatan();
      
      // Count category frequency
      Map<String, int> categoryCount = {};
      for (var peralatan in favoritePeralatan) {
        categoryCount[peralatan.kategori] = 
            (categoryCount[peralatan.kategori] ?? 0) + 1;
      }
      
      // Sort by frequency and return top categories
      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedCategories.map((entry) => entry.key).take(5).toList();
    } catch (e) {
      print('❌ Error getting recommended categories: $e');
      return [];
    }
  }

  // Debug method
  static Future<void> printFavoritesDebug() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        print('🔍 Debug: No user logged in');
        return;
      }

      print('🔍 Debug Favorites for user: $userId');
      final favoriteIds = await getFavoriteIds();
      print('🔍 Favorite IDs: $favoriteIds');
      
      final favorites = await HiveService.getFavorites(userId);
      print('🔍 Favorite data count: ${favorites.length}');
      
      for (var favorite in favorites) {
        print('🔍 Favorite: ${favorite['id']} - ${favorite['nama']} (${favorite['kategori']})');
      }
      
      final stats = await getFavoriteStats();
      print('🔍 Stats: $stats');
    } catch (e) {
      print('❌ Error in debug favorites: $e');
    }
  }
}