// services/ApiService.dart (SakuRimba) - FIXED
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Peralatan.dart';

class ApiService {
  // Base URL for the API
  static const String _baseUrl = 'https://6839447d6561b8d882af9534.mockapi.io/api/project_tpm';
  
  // API endpoints
  static const String _peralatanEndpoint = '/peralatanRimba';
  
  // HTTP client timeout
  static const Duration _timeout = Duration(seconds: 30);

  /// Fetch all peralatan from API
  static Future<List<Peralatan>> fetchPeralatan() async {
    try {
      print('🌐 Fetching peralatan from API...');
      
      final url = Uri.parse('$_baseUrl$_peralatanEndpoint');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        final List<Peralatan> peralatanList = jsonData.map((item) {
          try {
            return Peralatan.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print('⚠️ Error parsing peralatan item: $e');
            print('❌ Problematic item: $item');
            return null;
          }
        }).where((item) => item != null).cast<Peralatan>().toList();

        print('✅ Successfully fetched ${peralatanList.length} peralatan items');
        return peralatanList;
      } else {
        throw Exception('Failed to load peralatan: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error fetching peralatan: $e');
      
      // Return empty list instead of mock data - let the app handle the fallback
      return [];
    }
  }

  /// Fetch single peralatan by ID
  static Future<Peralatan?> fetchPeralatanById(String id) async {
    try {
      print('🌐 Fetching peralatan by ID: $id');
      
      final url = Uri.parse('$_baseUrl$_peralatanEndpoint/$id');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final peralatan = Peralatan.fromJson(jsonData);
        
        print('✅ Successfully fetched peralatan: ${peralatan.nama}');
        return peralatan;
      } else {
        throw Exception('Failed to load peralatan: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching peralatan by ID: $e');
      return null;
    }
  }

  /// Enhanced search peralatan with multiple filters - FIXED: Added named parameters
  static Future<List<Peralatan>> searchPeralatan({
    String? query,
    String? kategori,
    String? lokasi,
    int? minHarga,
    int? maxHarga,
    bool? tersedia,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 Searching peralatan with filters:');
      if (query != null) print('  - Query: $query');
      if (kategori != null) print('  - Kategori: $kategori');
      if (lokasi != null) print('  - Lokasi: $lokasi');
      if (minHarga != null) print('  - Min Harga: $minHarga');
      if (maxHarga != null) print('  - Max Harga: $maxHarga');
      if (tersedia != null) print('  - Tersedia: $tersedia');
      
      // For simplicity, fetch all and filter locally
      // In a real API, this would be done server-side with query parameters
      final allPeralatan = await fetchPeralatan();
      
      List<Peralatan> filteredPeralatan = allPeralatan;
      
      // Apply text search filter
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        filteredPeralatan = filteredPeralatan.where((peralatan) {
          return peralatan.nama.toLowerCase().contains(queryLower) ||
                 peralatan.kategori.toLowerCase().contains(queryLower) ||
                 peralatan.deskripsi.toLowerCase().contains(queryLower);
        }).toList();
      }
      
      // Apply category filter
      if (kategori != null && kategori.isNotEmpty) {
        filteredPeralatan = filteredPeralatan.where((peralatan) {
          return peralatan.kategori.toLowerCase() == kategori.toLowerCase();
        }).toList();
      }
      
      // Apply location filter
      if (lokasi != null && lokasi.isNotEmpty) {
        filteredPeralatan = filteredPeralatan.where((peralatan) {
          return peralatan.lokasi.toLowerCase().contains(lokasi.toLowerCase());
        }).toList();
      }
      
      // Apply price range filter
      if (minHarga != null) {
        filteredPeralatan = filteredPeralatan.where((peralatan) {
          return peralatan.harga >= minHarga;
        }).toList();
      }
      
      if (maxHarga != null) {
        filteredPeralatan = filteredPeralatan.where((peralatan) {
          return peralatan.harga <= maxHarga;
        }).toList();
      }
      
      // Apply availability filter
      if (tersedia != null) {
        if (tersedia) {
          filteredPeralatan = filteredPeralatan.where((peralatan) {
            return peralatan.stok > 0;
          }).toList();
        } else {
          filteredPeralatan = filteredPeralatan.where((peralatan) {
            return peralatan.stok == 0;
          }).toList();
        }
      }
      
      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      if (startIndex >= filteredPeralatan.length) {
        filteredPeralatan = [];
      } else if (endIndex >= filteredPeralatan.length) {
        filteredPeralatan = filteredPeralatan.sublist(startIndex);
      } else {
        filteredPeralatan = filteredPeralatan.sublist(startIndex, endIndex);
      }

      print('✅ Found ${filteredPeralatan.length} matching peralatan');
      return filteredPeralatan;
    } catch (e) {
      print('❌ Error searching peralatan: $e');
      return [];
    }
  }

  /// Simple search method for backward compatibility
  static Future<List<Peralatan>> simpleSearch(String query) async {
    return searchPeralatan(query: query);
  }

  /// Get peralatan by category
  static Future<List<Peralatan>> getPeralatanByCategory(String category) async {
    try {
      print('📂 Fetching peralatan by category: $category');
      
      return searchPeralatan(kategori: category);
    } catch (e) {
      print('❌ Error fetching peralatan by category: $e');
      return [];
    }
  }

  /// Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final allPeralatan = await fetchPeralatan();
      
      if (allPeralatan.isEmpty) {
        // Return default categories if no data from API
        return ['Tenda', 'Sleeping Bag', 'Kompor', 'Carrier', 'Peralatan Masak', 'Lampu'];
      }
      
      final categories = allPeralatan
          .map((peralatan) => peralatan.kategori)
          .toSet()
          .toList();
      
      categories.sort();
      
      print('✅ Found ${categories.length} categories');
      return categories;
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return ['Tenda', 'Sleeping Bag', 'Kompor', 'Carrier', 'Peralatan Masak', 'Lampu'];
    }
  }

  /// Get available locations
  static Future<List<String>> getLocations() async {
    try {
      final allPeralatan = await fetchPeralatan();
      
      if (allPeralatan.isEmpty) {
        return ['Jakarta', 'Bandung', 'Yogyakarta', 'Surabaya', 'Medan'];
      }
      
      final locations = allPeralatan
          .map((peralatan) => peralatan.lokasi)
          .toSet()
          .toList();
      
      locations.sort();
      
      print('✅ Found ${locations.length} locations');
      return locations;
    } catch (e) {
      print('❌ Error fetching locations: $e');
      return ['Jakarta', 'Bandung', 'Yogyakarta', 'Surabaya', 'Medan'];
    }
  }

  /// Get price range statistics
  static Future<Map<String, int>> getPriceRange() async {
    try {
      final allPeralatan = await fetchPeralatan();
      
      if (allPeralatan.isEmpty) {
        return {'min': 25000, 'max': 100000};
      }
      
      final prices = allPeralatan.map((p) => p.harga).toList();
      prices.sort();
      
      return {
        'min': prices.first,
        'max': prices.last,
      };
    } catch (e) {
      print('❌ Error getting price range: $e');
      return {'min': 25000, 'max': 100000};
    }
  }

  /// Check API connection
  static Future<bool> checkConnection() async {
    try {
      final url = Uri.parse('$_baseUrl$_peralatanEndpoint');
      
      final response = await http.head(url).timeout(
        const Duration(seconds: 10),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ API connection check failed: $e');
      return false;
    }
  }

  /// Get API health status
  static Future<Map<String, dynamic>> getApiHealth() async {
    try {
      final isConnected = await checkConnection();
      final startTime = DateTime.now();
      
      if (isConnected) {
        final peralatan = await fetchPeralatan();
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        
        return {
          'status': 'healthy',
          'connected': true,
          'response_time_ms': responseTime,
          'data_count': peralatan.length,
          'last_check': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'unhealthy',
          'connected': false,
          'response_time_ms': null,
          'data_count': 0,
          'last_check': DateTime.now().toIso8601String(),
          'fallback_needed': true,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'connected': false,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
        'fallback_needed': true,
      };
    }
  }

  /// Debug method to print API information
  static Future<void> printApiDebug() async {
    try {
      print('🔍 === API SERVICE DEBUG ===');
      print('Base URL: $_baseUrl');
      print('Peralatan Endpoint: $_peralatanEndpoint');
      print('Timeout: $_timeout');
      
      final health = await getApiHealth();
      print('API Health: $health');
      
      if (health['connected'] == true) {
        final peralatan = await fetchPeralatan();
        print('Total Peralatan: ${peralatan.length}');
        
        final categories = await getCategories();
        print('Categories: ${categories.join(', ')}');
        
        final locations = await getLocations();
        print('Locations: ${locations.join(', ')}');
        
        final priceRange = await getPriceRange();
        print('Price Range: ${priceRange['min']} - ${priceRange['max']}');
        
        // Sample peralatan info
        if (peralatan.isNotEmpty) {
          final sample = peralatan.first;
          print('Sample Peralatan: ${sample.nama} - ${sample.kategori}');
        }
      } else {
        print('⚠️ API not accessible - app should handle fallback');
      }
      
      print('==============================');
    } catch (e) {
      print('❌ Error in API debug: $e');
    }
  }

  /// Validate peralatan data
  static bool validatePeralatan(Map<String, dynamic> data) {
    final requiredFields = ['id', 'nama', 'kategori', 'harga', 'stok'];
    
    for (String field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        print('❌ Missing required field: $field');
        return false;
      }
    }
    
    // Validate data types
    if (data['harga'] is! int && data['harga'] is! num) {
      print('❌ Invalid harga type: ${data['harga'].runtimeType}');
      return false;
    }
    
    if (data['stok'] is! int && data['stok'] is! num) {
      print('❌ Invalid stok type: ${data['stok'].runtimeType}');
      return false;
    }
    
    return true;
  }

  /// Retry mechanism for failed requests
  static Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          print('❌ Max retries reached ($maxRetries). Last error: $e');
          rethrow;
        }
        
        print('⚠️ Request failed (attempt $attempt/$maxRetries): $e');
        print('⏳ Retrying in ${delay.inSeconds} seconds...');
        
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Retry mechanism failed unexpectedly');
  }

  /// Fetch peralatan with retry mechanism
  static Future<List<Peralatan>> fetchPeralatanWithRetry() async {
    return _retryRequest(() => fetchPeralatan());
  }

  /// Get fresh data (bypass any caching)
  static Future<List<Peralatan>> getFreshPeralatan() async {
    try {
      print('🔄 Fetching fresh peralatan data...');
      
      final url = Uri.parse('$_baseUrl$_peralatanEndpoint?_=${DateTime.now().millisecondsSinceEpoch}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        final List<Peralatan> peralatanList = jsonData.map((item) {
          return Peralatan.fromJson(item as Map<String, dynamic>);
        }).toList();

        print('✅ Fresh data fetched: ${peralatanList.length} items');
        return peralatanList;
      } else {
        throw Exception('Failed to fetch fresh data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching fresh data: $e');
      return [];
    }
  }
}