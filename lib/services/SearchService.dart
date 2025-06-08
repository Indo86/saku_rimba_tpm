// services/SearchService.dart (SakuRimba)
import '../models/Peralatan.dart';
import '../services/ApiService.dart';
import '../services/HiveService.dart';
import '../services/UserService.dart';

class SearchService {
  // Search history settings
  static const int _maxSearchHistoryEntries = 50;
  static const int _maxRecentSearches = 10;
  
  // Search filters
  static Map<String, dynamic> _currentFilters = {};
  static List<String> _searchHistory = [];
  static List<String> _popularSearches = [];
  
  // Search suggestions
  static List<String> _searchSuggestions = [];
  static DateTime? _lastSuggestionsUpdate;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize search service
  static Future<void> init() async {
    try {
      print('🔍 Initializing SearchService...');
      
      // Load search history and popular searches
      await _loadSearchHistory();
      await _loadPopularSearches();
      await _loadSearchSuggestions();
      
      print('✅ SearchService initialized');
    } catch (e) {
      print('❌ Error initializing SearchService: $e');
    }
  }

  // ============================================================================
  // SEARCH FUNCTIONALITY
  // ============================================================================

  /// Perform comprehensive search
  static Future<Map<String, dynamic>> searchPeralatan({
    required String query,
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
    String sortBy = 'relevance',
    bool saveToHistory = true,
  }) async {
    try {
      print('🔍 Searching for: "$query"');
      
      // Save to search history
      if (saveToHistory && query.trim().isNotEmpty) {
        await _saveSearchToHistory(query.trim());
      }
      
      // Apply filters
      final searchFilters = {
        ...filters ?? {},
        ..._currentFilters,
      };
      
      // Perform API search
      final results = await ApiService.searchPeralatan(
        query: query.isEmpty ? null : query,
        kategori: searchFilters['kategori'],
        lokasi: searchFilters['lokasi'],
        minHarga: searchFilters['minHarga'],
        maxHarga: searchFilters['maxHarga'],
        tersedia: searchFilters['tersedia'],
        page: page,
        limit: limit,
      );
      
      // Sort results
      final sortedResults = _sortResults(results, sortBy);
      
      // Analyze search results
      final analysis = _analyzeSearchResults(sortedResults, query);
      
      return {
        'query': query,
        'results': sortedResults,
        'totalResults': sortedResults.length,
        'page': page,
        'limit': limit,
        'hasMore': sortedResults.length >= limit,
        'filters': searchFilters,
        'sortBy': sortBy,
        'analysis': analysis,
        'suggestions': await _generateSearchSuggestions(query),
      };
    } catch (e) {
      print('❌ Error performing search: $e');
      return {
        'query': query,
        'results': <Peralatan>[],
        'totalResults': 0,
        'error': e.toString(),
      };
    }
  }

  /// Quick search (for auto-complete)
  static Future<List<Map<String, dynamic>>> quickSearch(String query) async {
    try {
      if (query.length < 2) return [];
      
      // Search in cached data for quick results
      final cachedResults = await _quickSearchInCache(query);
      
      return cachedResults.map((peralatan) => {
        'id': peralatan.id,
        'nama': peralatan.nama,
        'kategori': peralatan.kategori,
        'harga': peralatan.harga,
        'image': peralatan.image,
        'stok': peralatan.stok,
        'type': 'peralatan',
      }).toList();
    } catch (e) {
      print('❌ Error in quick search: $e');
      return [];
    }
  }

  /// Search suggestions based on query
  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) {
        return _getRecentSearches();
      }
      
      final suggestions = <String>[];
      final queryLower = query.toLowerCase();
      
      // Add matching search suggestions
      suggestions.addAll(
        _searchSuggestions
            .where((suggestion) => suggestion.toLowerCase().contains(queryLower))
            .take(5)
            .toList()
      );
      
      // Add matching categories
      final categories = await ApiService.getCategories();
      suggestions.addAll(
        categories
            .where((category) => category.toLowerCase().contains(queryLower))
            .take(3)
            .toList()
      );
      
      // Add matching search history
      suggestions.addAll(
        _searchHistory
            .where((search) => search.toLowerCase().contains(queryLower))
            .take(5)
            .toList()
      );
      
      // Remove duplicates and limit results
      return suggestions.toSet().take(10).toList();
    } catch (e) {
      print('❌ Error getting search suggestions: $e');
      return [];
    }
  }

  /// Search by category
  static Future<List<Peralatan>> searchByCategory(String kategori) async {
    try {
      return await ApiService.getPeralatanByCategory(kategori);
    } catch (e) {
      print('❌ Error searching by category: $e');
      return [];
    }
  }

  /// Search by location
  static Future<List<Peralatan>> searchByLocation(String lokasi) async {
    try {
      return await ApiService.searchPeralatan(lokasi: lokasi);
    } catch (e) {
      print('❌ Error searching by location: $e');
      return [];
    }
  }

  /// Search by price range
  static Future<List<Peralatan>> searchByPriceRange({
    int? minHarga,
    int? maxHarga,
  }) async {
    try {
      return await ApiService.searchPeralatan(
        minHarga: minHarga,
        maxHarga: maxHarga,
      );
    } catch (e) {
      print('❌ Error searching by price range: $e');
      return [];
    }
  }

  // ============================================================================
  // FILTERS AND SORTING
  // ============================================================================

  /// Set search filters
  static void setFilters(Map<String, dynamic> filters) {
    _currentFilters = Map.from(filters);
    print('🔧 Search filters updated: $_currentFilters');
  }

  /// Add filter
  static void addFilter(String key, dynamic value) {
    _currentFilters[key] = value;
    print('🔧 Added filter: $key = $value');
  }

  /// Remove filter
  static void removeFilter(String key) {
    _currentFilters.remove(key);
    print('🔧 Removed filter: $key');
  }

  /// Clear all filters
  static void clearFilters() {
    _currentFilters.clear();
    print('🔧 All filters cleared');
  }

  /// Get current filters
  static Map<String, dynamic> getCurrentFilters() {
    return Map.from(_currentFilters);
  }

  /// Sort search results
  static List<Peralatan> _sortResults(List<Peralatan> results, String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'nama':
      case 'name':
        results.sort((a, b) => a.nama.compareTo(b.nama));
        break;
      case 'harga_asc':
      case 'price_asc':
        results.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case 'harga_desc':
      case 'price_desc':
        results.sort((a, b) => b.harga.compareTo(a.harga));
        break;
      case 'stok':
      case 'stock':
        results.sort((a, b) => b.stok.compareTo(a.stok));
        break;
      case 'tahun':
      case 'year':
        results.sort((a, b) => b.tahunDibeli.compareTo(a.tahunDibeli));
        break;
      case 'kategori':
      case 'category':
        results.sort((a, b) => a.kategori.compareTo(b.kategori));
        break;
      case 'relevance':
      default:
        // Keep original order for relevance
        break;
    }
    
    return results;
  }

  // ============================================================================
  // SEARCH HISTORY
  // ============================================================================

  /// Save search to history
  static Future<void> _saveSearchToHistory(String query) async {
    try {
      // Remove if already exists
      _searchHistory.remove(query);
      
      // Add to beginning
      _searchHistory.insert(0, query);
      
      // Limit size
      if (_searchHistory.length > _maxSearchHistoryEntries) {
        _searchHistory = _searchHistory.take(_maxSearchHistoryEntries).toList();
      }
      
      // Save to storage
      await HiveService.saveSetting('search_history', _searchHistory);
      
      // Update popular searches
      await _updatePopularSearches(query);
    } catch (e) {
      print('❌ Error saving search to history: $e');
    }
  }

  /// Load search history
  static Future<void> _loadSearchHistory() async {
    try {
      final history = await HiveService.getSetting<List<dynamic>>('search_history');
      if (history != null) {
        _searchHistory = history.cast<String>();
      }
    } catch (e) {
      print('❌ Error loading search history: $e');
    }
  }

  /// Get recent searches
  static List<String> _getRecentSearches() {
    return _searchHistory.take(_maxRecentSearches).toList();
  }

  /// Get search history
  static List<String> getSearchHistory() {
    return List.from(_searchHistory);
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    try {
      _searchHistory.clear();
      await HiveService.saveSetting('search_history', _searchHistory);
      print('✅ Search history cleared');
    } catch (e) {
      print('❌ Error clearing search history: $e');
    }
  }

  /// Remove search from history
  static Future<void> removeFromSearchHistory(String query) async {
    try {
      _searchHistory.remove(query);
      await HiveService.saveSetting('search_history', _searchHistory);
      print('✅ Removed "$query" from search history');
    } catch (e) {
      print('❌ Error removing from search history: $e');
    }
  }

  // ============================================================================
  // POPULAR SEARCHES
  // ============================================================================

  /// Update popular searches
  static Future<void> _updatePopularSearches(String query) async {
    try {
      // Simple popularity tracking (could be more sophisticated)
      final popularSearchesMap = await HiveService.getSetting<Map<dynamic, dynamic>>(
        'popular_searches_count', 
        defaultValue: <String, int>{}
      ) ?? <String, int>{};
      
      final popularCount = Map<String, int>.from(popularSearchesMap);
      popularCount[query] = (popularCount[query] ?? 0) + 1;
      
      // Get top searches
      final sortedEntries = popularCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _popularSearches = sortedEntries
          .take(20)
          .map((entry) => entry.key)
          .toList();
      
      // Save back to storage
      await HiveService.saveSetting('popular_searches_count', popularCount);
      await HiveService.saveSetting('popular_searches', _popularSearches);
    } catch (e) {
      print('❌ Error updating popular searches: $e');
    }
  }

  /// Load popular searches
  static Future<void> _loadPopularSearches() async {
    try {
      final popular = await HiveService.getSetting<List<dynamic>>('popular_searches');
      if (popular != null) {
        _popularSearches = popular.cast<String>();
      }
    } catch (e) {
      print('❌ Error loading popular searches: $e');
    }
  }

  /// Get popular searches
  static List<String> getPopularSearches() {
    return List.from(_popularSearches);
  }

  // ============================================================================
  // SEARCH SUGGESTIONS
  // ============================================================================

  /// Load search suggestions
  static Future<void> _loadSearchSuggestions() async {
    try {
      final suggestions = await HiveService.getSetting<List<dynamic>>('search_suggestions');
      if (suggestions != null) {
        _searchSuggestions = suggestions.cast<String>();
        
        final lastUpdate = await HiveService.getSetting<String>('search_suggestions_last_update');
        if (lastUpdate != null) {
          _lastSuggestionsUpdate = DateTime.parse(lastUpdate);
        }
      }
      
      // Update suggestions if old or empty
      if (_searchSuggestions.isEmpty || 
          _lastSuggestionsUpdate == null ||
          DateTime.now().difference(_lastSuggestionsUpdate!).inDays > 7) {
        await _updateSearchSuggestions();
      }
    } catch (e) {
      print('❌ Error loading search suggestions: $e');
    }
  }

  /// Update search suggestions from API or popular terms
  static Future<void> _updateSearchSuggestions() async {
    try {
      final suggestions = <String>[];
      
      // Add categories as suggestions
      final categories = await ApiService.getCategories();
      suggestions.addAll(categories);
      
      // Add popular search terms
      suggestions.addAll(_popularSearches);
      
      // Add common camping equipment terms
      suggestions.addAll([
        'tenda 2 orang',
        'sleeping bag hangat',
        'carrier 50L',
        'kompor gas',
        'jaket outdoor',
        'sepatu hiking',
        'headlamp LED',
        'matras camping',
        'rain cover',
        'flysheet',
      ]);
      
      // Remove duplicates and save
      _searchSuggestions = suggestions.toSet().toList();
      _lastSuggestionsUpdate = DateTime.now();
      
      await HiveService.saveSetting('search_suggestions', _searchSuggestions);
      await HiveService.saveSetting('search_suggestions_last_update', _lastSuggestionsUpdate!.toIso8601String());
      
      print('✅ Search suggestions updated (${_searchSuggestions.length} items)');
    } catch (e) {
      print('❌ Error updating search suggestions: $e');
    }
  }

  /// Generate search suggestions based on query
  static Future<List<String>> _generateSearchSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final suggestions = <String>[];
      final queryLower = query.toLowerCase();
      
      // Generate related suggestions
      if (queryLower.contains('tenda')) {
        suggestions.addAll(['tenda 2 orang', 'tenda 4 orang', 'tenda dome', 'tenda ultralight']);
      } else if (queryLower.contains('carrier') || queryLower.contains('tas')) {
        suggestions.addAll(['carrier 40L', 'carrier 50L', 'carrier 60L', 'daypack']);
      } else if (queryLower.contains('sepatu')) {
        suggestions.addAll(['sepatu hiking', 'sepatu gunung', 'sepatu waterproof']);
      } else if (queryLower.contains('jaket')) {
        suggestions.addAll(['jaket outdoor', 'jaket waterproof', 'jaket windbreaker']);
      }
      
      return suggestions.take(5).toList();
    } catch (e) {
      print('❌ Error generating search suggestions: $e');
      return [];
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Quick search in cached data
  static Future<List<Peralatan>> _quickSearchInCache(String query) async {
    try {
      // Get cached peralatan data
      final cachedData = await HiveService.getSetting<List<dynamic>>('cached_peralatan');
      if (cachedData == null) return [];
      
      final peralatanList = cachedData
          .map((json) => Peralatan.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      final queryLower = query.toLowerCase();
      
      return peralatanList.where((peralatan) {
        return peralatan.nama.toLowerCase().contains(queryLower) ||
               peralatan.kategori.toLowerCase().contains(queryLower) ||
               peralatan.deskripsi.toLowerCase().contains(queryLower);
      }).take(10).toList();
    } catch (e) {
      print('❌ Error in quick search cache: $e');
      return [];
    }
  }

  /// Analyze search results
  static Map<String, dynamic> _analyzeSearchResults(List<Peralatan> results, String query) {
    if (results.isEmpty) {
      return {
        'hasResults': false,
        'suggestions': [
          'Coba kata kunci yang lebih umum',
          'Periksa ejaan kata kunci',
          'Gunakan nama kategori seperti "tenda" atau "carrier"',
        ],
      };
    }
    
    // Analyze categories
    final categories = <String, int>{};
    final locations = <String, int>{};
    int minPrice = results.first.harga;
    int maxPrice = results.first.harga;
    int availableCount = 0;
    
    for (var peralatan in results) {
      categories[peralatan.kategori] = (categories[peralatan.kategori] ?? 0) + 1;
      locations[peralatan.lokasi] = (locations[peralatan.lokasi] ?? 0) + 1;
      
      if (peralatan.harga < minPrice) minPrice = peralatan.harga;
      if (peralatan.harga > maxPrice) maxPrice = peralatan.harga;
      
      if (peralatan.stok > 0) availableCount++;
    }
    
    return {
      'hasResults': true,
      'totalResults': results.length,
      'availableCount': availableCount,
      'categories': categories,
      'locations': locations,
      'priceRange': {
        'min': minPrice,
        'max': maxPrice,
      },
      'availability': (availableCount / results.length * 100).round(),
    };
  }

  // ============================================================================
  // SEARCH STATISTICS
  // ============================================================================

  /// Get search statistics
  static Future<Map<String, dynamic>> getSearchStats() async {
    try {
      final userId = UserService.getCurrentUserId();
      
      return {
        'userId': userId,
        'totalSearches': _searchHistory.length,
        'popularSearches': _popularSearches.take(10).toList(),
        'recentSearches': _getRecentSearches(),
        'suggestionsCount': _searchSuggestions.length,
        'lastSuggestionsUpdate': _lastSuggestionsUpdate?.toIso8601String(),
        'currentFilters': _currentFilters,
      };
    } catch (e) {
      print('❌ Error getting search stats: $e');
      return {};
    }
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Debug print search information
  static Future<void> printSearchDebug() async {
    try {
      print('🔍 === SEARCH SERVICE DEBUG ===');
      
      final stats = await getSearchStats();
      print('🔍 Stats: $stats');
      
      print('🔍 Search history (${_searchHistory.length}):');
      for (var search in _searchHistory.take(5)) {
        print('  - $search');
      }
      
      print('🔍 Popular searches (${_popularSearches.length}):');
      for (var search in _popularSearches.take(5)) {
        print('  - $search');
      }
      
      print('🔍 Current filters: $_currentFilters');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in search debug: $e');
    }
  }
}