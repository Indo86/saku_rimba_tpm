// services/ApiService.dart (SakuRimba)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/Peralatan.dart';
import '../services/HiveService.dart';

class ApiService {
  // API Configuration
  static const String _baseUrl = 'https://6839447d6561b8d882af9534.mockapi.io/api/project_tpm/peralatanRimba';
  static const Duration _timeout = Duration(seconds: 30);
  
  // API Endpoints
  static const String _peralatanEndpoint = '/peralatan';
  static const String _kategoriesEndpoint = '/categories';
  static const String _locationsEndpoint = '/locations';
  
  // Cache settings
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(hours: 1);
  
  // Retry settings
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize API service
  static Future<void> init() async {
    try {
      print('🌐 Initializing ApiService...');
      
      // Test API connectivity
      await _testConnection();
      
      // Load cached data if available
      await _loadCachedData();
      
      print('✅ ApiService initialized');
    } catch (e) {
      print('❌ Error initializing ApiService: $e');
      // Continue with cached data if available
    }
  }

  /// Test API connection
  static Future<bool> _testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_peralatanEndpoint?page=1&limit=1'),
        headers: _getHeaders(),
      ).timeout(_timeout);
      
      final isConnected = response.statusCode == 200;
      print(isConnected ? '✅ API connection successful' : '❌ API connection failed');
      return isConnected;
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }

  // ============================================================================
  // PERALATAN API METHODS
  // ============================================================================

  /// Get all peralatan with pagination
  static Future<List<Peralatan>> getAllPeralatan({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid()) {
        final cachedData = await _getCachedPeralatan();
        if (cachedData.isNotEmpty) {
          print('📱 Using cached peralatan data');
          return cachedData;
        }
      }

      print('🌐 Fetching peralatan from API...');
      
      final response = await _makeRequest(
        'GET',
        '$_peralatanEndpoint?page=$page&limit=$limit',
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final List<Peralatan> peralatanList = data
            .map((json) => Peralatan.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the data
        await _cachePeralatan(peralatanList);
        
        print('✅ Fetched ${peralatanList.length} peralatan items');
        return peralatanList;
      } else {
        throw Exception('API response not successful: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error getting peralatan: $e');
      
      // Return cached data as fallback
      final cachedData = await _getCachedPeralatan();
      if (cachedData.isNotEmpty) {
        print('📱 Returning cached data as fallback');
        return cachedData;
      }
      
      return [];
    }
  }

  /// Get peralatan by ID
  static Future<Peralatan?> getPeralatanById(String id) async {
    try {
      print('🌐 Fetching peralatan by ID: $id');
      
      final response = await _makeRequest(
        'GET',
        '$_peralatanEndpoint/$id',
      );

      if (response['success']) {
        final data = response['data'] as Map<String, dynamic>;
        final peralatan = Peralatan.fromJson(data);
        
        print('✅ Fetched peralatan: ${peralatan.nama}');
        return peralatan;
      } else {
        throw Exception('API response not successful: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error getting peralatan by ID: $e');
      return null;
    }
  }

  /// Search peralatan
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
      print('🔍 Searching peralatan with query: $query');
      
      // Build query parameters
      Map<String, String> params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (query != null && query.isNotEmpty) {
        params['search'] = query;
      }
      if (kategori != null && kategori.isNotEmpty) {
        params['kategori'] = kategori;
      }
      if (lokasi != null && lokasi.isNotEmpty) {
        params['lokasi'] = lokasi;
      }
      if (minHarga != null) {
        params['minHarga'] = minHarga.toString();
      }
      if (maxHarga != null) {
        params['maxHarga'] = maxHarga.toString();
      }
      if (tersedia != null) {
        params['tersedia'] = tersedia.toString();
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _makeRequest(
        'GET',
        '$_peralatanEndpoint?$queryString',
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final List<Peralatan> results = data
            .map((json) => Peralatan.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ Search found ${results.length} results');
        return results;
      } else {
        throw Exception('Search failed: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error searching peralatan: $e');
      
      // Fallback to local search in cached data
      return await _searchInCachedData(query: query, kategori: kategori, lokasi: lokasi);
    }
  }

  /// Get peralatan by category
  static Future<List<Peralatan>> getPeralatanByCategory(String kategori) async {
    try {
      return await searchPeralatan(kategori: kategori);
    } catch (e) {
      print('❌ Error getting peralatan by category: $e');
      return [];
    }
  }

  /// Get featured/popular peralatan
  static Future<List<Peralatan>> getFeaturedPeralatan() async {
    try {
      print('🌟 Fetching featured peralatan...');
      
      final response = await _makeRequest(
        'GET',
        '$_peralatanEndpoint?featured=true&limit=10',
      );

      if (response['success']) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final List<Peralatan> featured = data
            .map((json) => Peralatan.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ Fetched ${featured.length} featured items');
        return featured;
      } else {
        throw Exception('Failed to get featured items: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error getting featured peralatan: $e');
      
      // Return random items from cache as fallback
      final cachedData = await _getCachedPeralatan();
      if (cachedData.length > 5) {
        cachedData.shuffle();
        return cachedData.take(5).toList();
      }
      
      return [];
    }
  }

  // ============================================================================
  // CATEGORIES AND LOCATIONS API
  // ============================================================================

  /// Get all categories
  static Future<List<String>> getCategories() async {
    try {
      print('🏷️ Fetching categories...');
      
      final response = await _makeRequest('GET', _kategoriesEndpoint);

      if (response['success']) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final categories = data.cast<String>();
        
        print('✅ Fetched ${categories.length} categories');
        return categories;
      } else {
        throw Exception('Failed to get categories: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error getting categories: $e');
      
      // Return default categories as fallback
      return [
        'Tenda',
        'Sleeping Bag',
        'Carrier',
        'Kompor',
        'Pakaian',
        'Sepatu',
        'Aksesoris',
        'Elektronik',
        'Peralatan Masak',
        'Safety Equipment',
      ];
    }
  }

  /// Get all locations
  static Future<List<String>> getLocations() async {
    try {
      print('📍 Fetching locations...');
      
      final response = await _makeRequest('GET', _locationsEndpoint);

      if (response['success']) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final locations = data.cast<String>();
        
        print('✅ Fetched ${locations.length} locations');
        return locations;
      } else {
        throw Exception('Failed to get locations: ${response['message']}');
      }
    } catch (e) {
      print('❌ Error getting locations: $e');
      
      // Return default locations as fallback
      return [
        'Jakarta',
        'Bogor',
        'Bandung',
        'Sukabumi',
        'Cianjur',
        'Garut',
        'Tasikmalaya',
        'Cirebon',
        'Bekasi',
        'Depok',
      ];
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Make HTTP request with retry logic
  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = _getHeaders();
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } catch (e) {
      print('❌ Request failed (attempt ${retryCount + 1}): $e');
      
      // Retry logic
      if (retryCount < _maxRetries && _shouldRetry(e)) {
        print('🔄 Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
        return _makeRequest(method, endpoint, body: body, retryCount: retryCount + 1);
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Request failed after ${retryCount + 1} attempts',
      };
    }
  }

  /// Get HTTP headers
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SakuRimba/1.0',
    };
  }

  /// Check if error should trigger retry
  static bool _shouldRetry(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) {
      // Retry on server errors (5xx)
      return error.message.contains('5');
    }
    return false;
  }

  // ============================================================================
  // CACHING METHODS
  // ============================================================================

  /// Check if cache is valid
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Load cached data from Hive
  static Future<void> _loadCachedData() async {
    try {
      final lastUpdate = await HiveService.getSetting<String>('api_cache_last_update');
      if (lastUpdate != null) {
        _lastCacheUpdate = DateTime.parse(lastUpdate);
      }
      
      print('✅ Cached data loaded');
    } catch (e) {
      print('❌ Error loading cached data: $e');
    }
  }

  /// Cache peralatan data
  static Future<void> _cachePeralatan(List<Peralatan> peralatanList) async {
    try {
      final jsonList = peralatanList.map((p) => p.toJson()).toList();
      await HiveService.saveSetting('cached_peralatan', jsonList);
      await HiveService.saveSetting('api_cache_last_update', DateTime.now().toIso8601String());
      
      _lastCacheUpdate = DateTime.now();
      print('✅ Peralatan data cached (${peralatanList.length} items)');
    } catch (e) {
      print('❌ Error caching peralatan data: $e');
    }
  }

  /// Get cached peralatan data
  static Future<List<Peralatan>> _getCachedPeralatan() async {
    try {
      final cachedData = await HiveService.getSetting<List<dynamic>>('cached_peralatan');
      if (cachedData != null) {
        return cachedData
            .map((json) => Peralatan.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting cached peralatan: $e');
      return [];
    }
  }

  /// Search in cached data (fallback)
  static Future<List<Peralatan>> _searchInCachedData({
    String? query,
    String? kategori,
    String? lokasi,
  }) async {
    try {
      final cachedData = await _getCachedPeralatan();
      
      return cachedData.where((peralatan) {
        bool matches = true;
        
        if (query != null && query.isNotEmpty) {
          final searchLower = query.toLowerCase();
          matches = matches && (
            peralatan.nama.toLowerCase().contains(searchLower) ||
            peralatan.deskripsi.toLowerCase().contains(searchLower)
          );
        }
        
        if (kategori != null && kategori.isNotEmpty) {
          matches = matches && peralatan.kategori.toLowerCase() == kategori.toLowerCase();
        }
        
        if (lokasi != null && lokasi.isNotEmpty) {
          matches = matches && peralatan.lokasi.toLowerCase().contains(lokasi.toLowerCase());
        }
        
        return matches;
      }).toList();
    } catch (e) {
      print('❌ Error searching cached data: $e');
      return [];
    }
  }

  // ============================================================================
  // CONNECTIVITY AND STATUS
  // ============================================================================

  /// Check internet connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get API service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    final isConnected = await checkConnectivity();
    final isApiReachable = await _testConnection();
    
    return {
      'internetConnected': isConnected,
      'apiReachable': isApiReachable,
      'cacheValid': _isCacheValid(),
      'lastCacheUpdate': _lastCacheUpdate?.toIso8601String(),
      'baseUrl': _baseUrl,
    };
  }

  /// Clear cache
  static Future<void> clearCache() async {
    try {
      final settingsBox = await HiveService.getSettingsBox();
      await settingsBox.delete('cached_peralatan');
      await settingsBox.delete('api_cache_last_update');
      
      _lastCacheUpdate = null;
      print('✅ API cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Force refresh data
  static Future<List<Peralatan>> forceRefreshPeralatan() async {
    print('🔄 Force refreshing peralatan data...');
    return await getAllPeralatan(forceRefresh: true);
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Debug print API information
  static Future<void> printApiDebug() async {
    try {
      print('🔍 === API SERVICE DEBUG ===');
      
      final status = await getServiceStatus();
      print('🔍 Status: $status');
      
      final cachedData = await _getCachedPeralatan();
      print('🔍 Cached peralatan count: ${cachedData.length}');
      
      final categories = await getCategories();
      print('🔍 Available categories: $categories');
      
      final locations = await getLocations();
      print('🔍 Available locations: $locations');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in API debug: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cachedData = await _getCachedPeralatan();
      
      if (cachedData.isEmpty) {
        return {'message': 'No cached data available'};
      }
      
      // Analyze cached data
      final categories = <String, int>{};
      final locations = <String, int>{};
      int totalItems = cachedData.length;
      int availableItems = 0;
      
      for (var peralatan in cachedData) {
        categories[peralatan.kategori] = (categories[peralatan.kategori] ?? 0) + 1;
        locations[peralatan.lokasi] = (locations[peralatan.lokasi] ?? 0) + 1;
        if (peralatan.stok > 0) availableItems++;
      }
      
      return {
        'totalItems': totalItems,
        'availableItems': availableItems,
        'categoriesCount': categories.length,
        'locationsCount': locations.length,
        'categoryBreakdown': categories,
        'locationBreakdown': locations,
        'cacheAge': _lastCacheUpdate != null 
            ? DateTime.now().difference(_lastCacheUpdate!).inMinutes 
            : null,
        'isValid': _isCacheValid(),
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
}