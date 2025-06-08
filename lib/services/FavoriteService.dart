// services/FavoriteService.dart (SakuRimba)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../models/Peralatan.dart';

class FavoriteService {
  /// Add peralatan to favorites
  static Future<void> addToFavorites(Peralatan peralatan) async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Convert peralatan to map for storage
      final peralatanData = peralatan.toJson();
      
      await HiveService.addToFavorites(username, peralatan.id, peralatanData);
      
      print('✅ Added to favorites: ${peralatan.nama} for user: $username');
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove peralatan from favorites
  static Future<void> removeFromFavorites(Peralatan peralatan) async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        throw Exception('User tidak login.');
      }

      await HiveService.removeFromFavorites(username, peralatan.id);
      
      print('✅ Removed from favorites: ${peralatan.nama} for user: $username');
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  static Future<void> toggleFavorite(Peralatan peralatan) async {
    try {
      final isFav = await isFavorite(peralatan.id);
      
      if (isFav) {
        await removeFromFavorites(peralatan);
      } else {
        await addToFavorites(peralatan);
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Check if peralatan is in favorites
  static Future<bool> isFavorite(String peralatanId) async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        return false;
      }

      return await HiveService.isFavorite(username, peralatanId);
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  /// Get all favorites for current user
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        throw Exception('User tidak login.');
      }

      final favorites = await HiveService.getFavorites(username);
      
      print('✅ Retrieved ${favorites.length} favorites for user: $username');
      return favorites;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }

  /// Get favorites as Peralatan objects
  static Future<List<Peralatan>> getFavoritesAsPeralatan() async {
    try {
      final favoritesData = await getFavorites();
      
      final List<Peralatan> peralatanList = [];
      
      for (var data in favoritesData) {
        try {
          final peralatan = Peralatan.fromJson(data);
          peralatanList.add(peralatan);
        } catch (e) {
          print('⚠️ Error parsing favorite peralatan: $e');
          print('❌ Problematic data: $data');
        }
      }
      
      print('✅ Converted ${peralatanList.length} favorites to Peralatan objects');
      return peralatanList;
    } catch (e) {
      print('❌ Error converting favorites to Peralatan: $e');
      return [];
    }
  }

  /// Get favorites count
  static Future<int> getFavoritesCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('❌ Error getting favorites count: $e');
      return 0;
    }
  }

  /// Clear all favorites
  static Future<void> clearAllFavorites() async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        throw Exception('User tidak login.');
      }

      final favorites = await getFavorites();
      
      for (var favorite in favorites) {
        try {
          final peralatanId = favorite['id'];
          if (peralatanId != null) {
            await HiveService.removeFromFavorites(username, peralatanId);
          }
        } catch (e) {
          print('⚠️ Error removing favorite during clear: $e');
        }
      }
      
      print('✅ Cleared all favorites for user: $username');
    } catch (e) {
      print('❌ Error clearing favorites: $e');
      rethrow;
    }
  }

  /// Get favorites by category
  static Future<List<Map<String, dynamic>>> getFavoritesByCategory(String category) async {
    try {
      final allFavorites = await getFavorites();
      
      final categoryFavorites = allFavorites.where((favorite) {
        return favorite['kategori']?.toString().toLowerCase() == category.toLowerCase();
      }).toList();
      
      print('✅ Found ${categoryFavorites.length} favorites in category: $category');
      return categoryFavorites;
    } catch (e) {
      print('❌ Error getting favorites by category: $e');
      return [];
    }
  }

  /// Search favorites
  static Future<List<Map<String, dynamic>>> searchFavorites(String query) async {
    try {
      final allFavorites = await getFavorites();
      
      if (query.isEmpty) return allFavorites;
      
      final searchLower = query.toLowerCase();
      final searchResults = allFavorites.where((favorite) {
        final nama = favorite['nama']?.toString().toLowerCase() ?? '';
        final kategori = favorite['kategori']?.toString().toLowerCase() ?? '';
        final deskripsi = favorite['deskripsi']?.toString().toLowerCase() ?? '';
        
        return nama.contains(searchLower) ||
               kategori.contains(searchLower) ||
               deskripsi.contains(searchLower);
      }).toList();
      
      print('✅ Search found ${searchResults.length} favorites for query: $query');
      return searchResults;
    } catch (e) {
      print('❌ Error searching favorites: $e');
      return [];
    }
  }

  /// Get favorite categories
  static Future<List<String>> getFavoriteCategories() async {
    try {
      final allFavorites = await getFavorites();
      
      final categories = allFavorites
          .map((favorite) => favorite['kategori']?.toString())
          .where((category) => category != null && category.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      categories.sort();
      
      print('✅ Found ${categories.length} favorite categories');
      return categories;
    } catch (e) {
      print('❌ Error getting favorite categories: $e');
      return [];
    }
  }

  /// Get most expensive favorite
  static Future<Map<String, dynamic>?> getMostExpensiveFavorite() async {
    try {
      final allFavorites = await getFavorites();
      
      if (allFavorites.isEmpty) return null;
      
      Map<String, dynamic>? mostExpensive;
      double maxPrice = 0;
      
      for (var favorite in allFavorites) {
        final price = _parsePrice(favorite['harga']);
        if (price > maxPrice) {
          maxPrice = price;
          mostExpensive = favorite;
        }
      }
      
      print('✅ Most expensive favorite: ${mostExpensive?['nama']} - Rp ${maxPrice.toStringAsFixed(0)}');
      return mostExpensive;
    } catch (e) {
      print('❌ Error getting most expensive favorite: $e');
      return null;
    }
  }

  /// Get cheapest favorite
  static Future<Map<String, dynamic>?> getCheapestFavorite() async {
    try {
      final allFavorites = await getFavorites();
      
      if (allFavorites.isEmpty) return null;
      
      Map<String, dynamic>? cheapest;
      double minPrice = double.infinity;
      
      for (var favorite in allFavorites) {
        final price = _parsePrice(favorite['harga']);
        if (price < minPrice) {
          minPrice = price;
          cheapest = favorite;
        }
      }
      
      print('✅ Cheapest favorite: ${cheapest?['nama']} - Rp ${minPrice.toStringAsFixed(0)}');
      return cheapest;
    } catch (e) {
      print('❌ Error getting cheapest favorite: $e');
      return null;
    }
  }

  /// Get average price of favorites
  static Future<double> getAverageFavoritePrice() async {
    try {
      final allFavorites = await getFavorites();
      
      if (allFavorites.isEmpty) return 0.0;
      
      double totalPrice = 0.0;
      int validCount = 0;
      
      for (var favorite in allFavorites) {
        final price = _parsePrice(favorite['harga']);
        if (price > 0) {
          totalPrice += price;
          validCount++;
        }
      }
      
      final averagePrice = validCount > 0 ? totalPrice / validCount : 0.0;
      
      print('✅ Average favorite price: Rp ${averagePrice.toStringAsFixed(0)}');
      return averagePrice;
    } catch (e) {
      print('❌ Error calculating average favorite price: $e');
      return 0.0;
    }
  }

  /// Get favorites statistics
  static Future<Map<String, dynamic>> getFavoritesStats() async {
    try {
      final allFavorites = await getFavorites();
      final categories = await getFavoriteCategories();
      final mostExpensive = await getMostExpensiveFavorite();
      final cheapest = await getCheapestFavorite();
      final averagePrice = await getAverageFavoritePrice();
      
      // Category breakdown
      Map<String, int> categoryBreakdown = {};
      for (var favorite in allFavorites) {
        final category = favorite['kategori']?.toString() ?? 'Unknown';
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }
      
      // Price range analysis
      final prices = allFavorites.map((f) => _parsePrice(f['harga'])).where((p) => p > 0).toList();
      prices.sort();
      
      final stats = {
        'total': allFavorites.length,
        'categories': categories.length,
        'categoryBreakdown': categoryBreakdown,
        'mostExpensive': mostExpensive,
        'cheapest': cheapest,
        'averagePrice': averagePrice,
        'priceRange': prices.isNotEmpty ? {
          'min': prices.first,
          'max': prices.last,
          'median': prices.length > 0 ? prices[prices.length ~/ 2] : 0.0,
        } : null,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      print('✅ Generated favorites statistics');
      return stats;
    } catch (e) {
      print('❌ Error generating favorites stats: $e');
      return {
        'total': 0,
        'categories': 0,
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check if favorites need sync (placeholder for future implementation)
  static Future<bool> needsSync() async {
    try {
      // In a real app, this would check if local favorites are in sync with server
      // For now, always return false
      return false;
    } catch (e) {
      print('❌ Error checking sync status: $e');
      return false;
    }
  }

  /// Sync favorites with server (placeholder for future implementation)
  static Future<void> syncFavorites() async {
    try {
      // In a real app, this would sync favorites with server
      print('📡 Sync favorites feature not implemented yet');
    } catch (e) {
      print('❌ Error syncing favorites: $e');
      rethrow;
    }
  }

  /// Export favorites data
  static Future<Map<String, dynamic>> exportFavorites() async {
    try {
      final username = UserService.getCurrentUsername();
      final favorites = await getFavorites();
      final stats = await getFavoritesStats();
      
      final exportData = {
        'user': username,
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'favorites': favorites,
        'statistics': stats,
      };
      
      print('✅ Exported ${favorites.length} favorites');
      return exportData;
    } catch (e) {
      print('❌ Error exporting favorites: $e');
      return {
        'error': e.toString(),
        'export_date': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Import favorites data (placeholder for future implementation)
  static Future<bool> importFavorites(Map<String, dynamic> data) async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        throw Exception('User tidak login.');
      }

      if (!data.containsKey('favorites') || data['favorites'] is! List) {
        throw Exception('Invalid favorites data format');
      }

      final favorites = data['favorites'] as List;
      int importedCount = 0;
      
      for (var favoriteData in favorites) {
        try {
          if (favoriteData is Map<String, dynamic> && favoriteData.containsKey('id')) {
            await HiveService.addToFavorites(username, favoriteData['id'], favoriteData);
            importedCount++;
          }
        } catch (e) {
          print('⚠️ Error importing favorite item: $e');
        }
      }
      
      print('✅ Imported $importedCount favorites');
      return importedCount > 0;
    } catch (e) {
      print('❌ Error importing favorites: $e');
      return false;
    }
  }

  /// Helper method to parse price from various formats
  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    
    if (price is num) {
      return price.toDouble();
    }
    
    if (price is String) {
      final parsed = double.tryParse(price);
      return parsed ?? 0.0;
    }
    
    return 0.0;
  }

  /// Debug method to print favorites information
  static Future<void> printFavoritesDebug() async {
    try {
      final username = UserService.getCurrentUsername();
      
      print('🔍 === FAVORITES SERVICE DEBUG ===');
      print('Current user: $username');
      
      if (username != null) {
        final favorites = await getFavorites();
        final stats = await getFavoritesStats();
        
        print('Total favorites: ${favorites.length}');
        print('Statistics: $stats');
        
        if (favorites.isNotEmpty) {
          print('Sample favorites:');
          for (int i = 0; i < favorites.length && i < 3; i++) {
            final fav = favorites[i];
            print('  ${i + 1}. ${fav['nama']} - ${fav['kategori']} - Rp ${fav['harga']}');
          }
        }
        
        final categories = await getFavoriteCategories();
        print('Favorite categories: ${categories.join(', ')}');
      } else {
        print('No user logged in');
      }
      
      print('==============================');
    } catch (e) {
      print('❌ Error in favorites debug: $e');
    }
  }

  /// Validate favorite data
  static bool validateFavoriteData(Map<String, dynamic> data) {
    final requiredFields = ['id', 'nama', 'kategori', 'harga'];
    
    for (String field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        print('❌ Missing required field in favorite: $field');
        return false;
      }
    }
    
    // Validate price
    final price = _parsePrice(data['harga']);
    if (price <= 0) {
      print('❌ Invalid price in favorite: ${data['harga']}');
      return false;
    }
    
    return true;
  }

  /// Clean up invalid favorites
  static Future<int> cleanupInvalidFavorites() async {
    try {
      final username = UserService.getCurrentUsername();
      if (username == null) {
        return 0;
      }

      final allFavorites = await getFavorites();
      int removedCount = 0;
      
      for (var favorite in allFavorites) {
        if (!validateFavoriteData(favorite)) {
          try {
            final peralatanId = favorite['id'];
            if (peralatanId != null) {
              await HiveService.removeFromFavorites(username, peralatanId);
              removedCount++;
            }
          } catch (e) {
            print('⚠️ Error removing invalid favorite: $e');
          }
        }
      }
      
      print('✅ Cleaned up $removedCount invalid favorites');
      return removedCount;
    } catch (e) {
      print('❌ Error cleaning up favorites: $e');
      return 0;
    }
  }
}