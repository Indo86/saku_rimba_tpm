// services/CurrencyService.dart (SakuRimba)
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/HiveService.dart';

class CurrencyService {
  // API endpoint untuk exchange rates (gunakan API gratis seperti exchangerate-api.com)
  static const String _apiKey = 'YOUR_API_KEY'; // Ganti dengan API key yang sebenarnya
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  
  // Supported currencies
  static const Map<String, String> supportedCurrencies = {
    'IDR': 'Indonesian Rupiah',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'AUD': 'Australian Dollar',
  };

  // Cache untuk exchange rates
  static Map<String, dynamic>? _cachedRates;
  static DateTime? _lastUpdate;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Base currency (default: IDR)
  static String _baseCurrency = 'IDR';

  // ============================================================================
  // CURRENCY CONVERSION
  // ============================================================================

  /// Initialize currency service
  static Future<void> init() async {
    try {
      print('💱 Initializing CurrencyService...');
      
      // Load cached rates and settings
      await _loadCachedData();
      
      // Update rates if cache is old or empty
      if (_shouldUpdateRates()) {
        await updateExchangeRates();
      }
      
      print('✅ CurrencyService initialized');
    } catch (e) {
      print('❌ Error initializing CurrencyService: $e');
      // Use fallback rates if API fails
      _setFallbackRates();
    }
  }

  /// Update exchange rates from API
  static Future<bool> updateExchangeRates() async {
    try {
      print('🔄 Updating exchange rates...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/$_baseCurrency'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _cachedRates = {
          'base': data['base'],
          'rates': data['rates'],
          'lastUpdate': DateTime.now().toIso8601String(),
        };
        
        _lastUpdate = DateTime.now();
        
        // Save to cache
        await _saveCachedData();
        
        print('✅ Exchange rates updated successfully');
        return true;
      } else {
        print('❌ API request failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating exchange rates: $e');
      // Use fallback rates if API fails
      _setFallbackRates();
      return false;
    }
  }

  /// Convert amount from one currency to another
  static double convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    try {
      if (_cachedRates == null || _cachedRates!['rates'] == null) {
        print('⚠️ No exchange rates available, using fallback');
        return _convertWithFallbackRates(amount, fromCurrency, toCurrency);
      }

      final rates = _cachedRates!['rates'] as Map<String, dynamic>;
      
      // If converting from base currency
      if (fromCurrency == _baseCurrency) {
        final toRate = rates[toCurrency]?.toDouble() ?? 1.0;
        return amount * toRate;
      }
      
      // If converting to base currency
      if (toCurrency == _baseCurrency) {
        final fromRate = rates[fromCurrency]?.toDouble() ?? 1.0;
        return amount / fromRate;
      }
      
      // Converting between two non-base currencies
      final fromRate = rates[fromCurrency]?.toDouble() ?? 1.0;
      final toRate = rates[toCurrency]?.toDouble() ?? 1.0;
      
      // Convert to base currency first, then to target currency
      final baseAmount = amount / fromRate;
      return baseAmount * toRate;
    } catch (e) {
      print('❌ Error converting currency: $e');
      return _convertWithFallbackRates(amount, fromCurrency, toCurrency);
    }
  }

  /// Get exchange rate between two currencies
  static double getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) {
    return convertCurrency(
      amount: 1.0,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }

  /// Format currency with proper symbol and format
  static String formatCurrency({
    required double amount,
    required String currency,
    int decimalPlaces = 2,
  }) {
    try {
      final symbol = _getCurrencySymbol(currency);
      final formatted = amount.toStringAsFixed(decimalPlaces);
      
      // Format with thousand separators
      final parts = formatted.split('.');
      final wholePart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';
      
      // Add thousand separators
      String formattedWhole = '';
      for (int i = 0; i < wholePart.length; i++) {
        if (i > 0 && (wholePart.length - i) % 3 == 0) {
          formattedWhole += ',';
        }
        formattedWhole += wholePart[i];
      }
      
      final result = decimalPart.isNotEmpty 
          ? '$symbol$formattedWhole.$decimalPart'
          : '$symbol$formattedWhole';
      
      return result;
    } catch (e) {
      print('❌ Error formatting currency: $e');
      return '$amount $currency';
    }
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      case 'JPY':
        return '¥ ';
      case 'SGD':
        return 'S\$ ';
      case 'MYR':
        return 'RM ';
      case 'AUD':
        return 'A\$ ';
      default:
        return '$currency ';
    }
  }

  // ============================================================================
  // CONFIGURATION AND SETTINGS
  // ============================================================================

  /// Set base currency
  static Future<void> setBaseCurrency(String currency) async {
    try {
      if (!supportedCurrencies.containsKey(currency)) {
        throw Exception('Currency not supported: $currency');
      }
      
      _baseCurrency = currency;
      
      // Save to settings
      await HiveService.saveSetting('currency_base', currency);
      
      // Update rates with new base currency
      await updateExchangeRates();
      
      print('✅ Base currency set to: $currency');
    } catch (e) {
      print('❌ Error setting base currency: $e');
    }
  }

  /// Get current base currency
  static String getBaseCurrency() {
    return _baseCurrency;
  }

  /// Get all supported currencies
  static Map<String, String> getSupportedCurrencies() {
    return Map.from(supportedCurrencies);
  }

  /// Check if currency is supported
  static bool isCurrencySupported(String currency) {
    return supportedCurrencies.containsKey(currency);
  }

  /// Get currency name
  static String getCurrencyName(String currency) {
    return supportedCurrencies[currency] ?? currency;
  }

  // ============================================================================
  // POPULAR CONVERSION PAIRS
  // ============================================================================

  /// Get popular conversion pairs for Indonesian users
  static List<Map<String, String>> getPopularConversionPairs() {
    return [
      {'from': 'IDR', 'to': 'USD'},
      {'from': 'IDR', 'to': 'EUR'},
      {'from': 'IDR', 'to': 'SGD'},
      {'from': 'IDR', 'to': 'MYR'},
      {'from': 'USD', 'to': 'IDR'},
      {'from': 'EUR', 'to': 'IDR'},
      {'from': 'SGD', 'to': 'IDR'},
      {'from': 'GBP', 'to': 'IDR'},
    ];
  }

  /// Convert popular amounts for quick reference
  static Map<String, double> getQuickConversions({
    required String fromCurrency,
    required String toCurrency,
  }) {
    final commonAmounts = [1, 10, 100, 1000, 10000, 100000];
    Map<String, double> conversions = {};
    
    for (int amount in commonAmounts) {
      final converted = convertCurrency(
        amount: amount.toDouble(),
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
      conversions[amount.toString()] = converted;
    }
    
    return conversions;
  }

  // ============================================================================
  // RENTAL PRICING HELPERS
  // ============================================================================

  /// Convert rental price to different currencies
  static Map<String, double> convertRentalPrice({
    required double priceInIDR,
    List<String>? targetCurrencies,
  }) {
    final currencies = targetCurrencies ?? ['USD', 'EUR', 'SGD', 'MYR'];
    Map<String, double> convertedPrices = {};
    
    for (String currency in currencies) {
      if (currency != 'IDR') {
        convertedPrices[currency] = convertCurrency(
          amount: priceInIDR,
          fromCurrency: 'IDR',
          toCurrency: currency,
        );
      }
    }
    
    return convertedPrices;
  }

  /// Get rental price comparison
  static Map<String, String> getRentalPriceComparison({
    required double priceInIDR,
    List<String>? targetCurrencies,
  }) {
    final convertedPrices = convertRentalPrice(
      priceInIDR: priceInIDR,
      targetCurrencies: targetCurrencies,
    );
    
    Map<String, String> formattedPrices = {
      'IDR': formatCurrency(amount: priceInIDR, currency: 'IDR'),
    };
    
    convertedPrices.forEach((currency, amount) {
      formattedPrices[currency] = formatCurrency(
        amount: amount,
        currency: currency,
        decimalPlaces: currency == 'JPY' ? 0 : 2,
      );
    });
    
    return formattedPrices;
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Load cached data from Hive
  static Future<void> _loadCachedData() async {
    try {
      // Load cached rates
      final cachedRatesData = await HiveService.getSetting<Map<dynamic, dynamic>>('currency_rates');
      if (cachedRatesData != null) {
        _cachedRates = Map<String, dynamic>.from(cachedRatesData);
        
        final lastUpdateStr = _cachedRates?['lastUpdate'];
        if (lastUpdateStr != null) {
          _lastUpdate = DateTime.parse(lastUpdateStr);
        }
      }
      
      // Load base currency setting
      final baseCurrency = await HiveService.getSetting<String>('currency_base', defaultValue: 'IDR');
      if (baseCurrency != null) {
        _baseCurrency = baseCurrency;
      }
      
      print('✅ Cached currency data loaded');
    } catch (e) {
      print('❌ Error loading cached currency data: $e');
    }
  }

  /// Save cached data to Hive
  static Future<void> _saveCachedData() async {
    try {
      if (_cachedRates != null) {
        await HiveService.saveSetting('currency_rates', _cachedRates!);
      }
      await HiveService.saveSetting('currency_base', _baseCurrency);
      
      print('✅ Currency data cached');
    } catch (e) {
      print('❌ Error saving currency cache: $e');
    }
  }

  /// Check if rates should be updated
  static bool _shouldUpdateRates() {
    if (_cachedRates == null || _lastUpdate == null) return true;
    
    final now = DateTime.now();
    final timeSinceUpdate = now.difference(_lastUpdate!);
    
    return timeSinceUpdate > _cacheValidDuration;
  }

  /// Set fallback rates when API is unavailable
  static void _setFallbackRates() {
    _cachedRates = {
      'base': 'IDR',
      'rates': {
        'IDR': 1.0,
        'USD': 0.000067, // Approximate rate: 1 IDR = 0.000067 USD
        'EUR': 0.000062, // Approximate rate: 1 IDR = 0.000062 EUR
        'GBP': 0.000053, // Approximate rate: 1 IDR = 0.000053 GBP
        'JPY': 0.0098,   // Approximate rate: 1 IDR = 0.0098 JPY
        'SGD': 0.000090, // Approximate rate: 1 IDR = 0.000090 SGD
        'MYR': 0.000310, // Approximate rate: 1 IDR = 0.000310 MYR
        'AUD': 0.000102, // Approximate rate: 1 IDR = 0.000102 AUD
      },
      'lastUpdate': DateTime.now().toIso8601String(),
    };
    _lastUpdate = DateTime.now();
    
    print('⚠️ Using fallback exchange rates');
  }

  /// Convert using fallback rates
  static double _convertWithFallbackRates(double amount, String from, String to) {
    _setFallbackRates();
    return convertCurrency(amount: amount, fromCurrency: from, toCurrency: to);
  }

  // ============================================================================
  // UTILITY AND DEBUG
  // ============================================================================

  /// Get currency service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _cachedRates != null,
      'baseCurrency': _baseCurrency,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'cacheValid': !_shouldUpdateRates(),
      'supportedCurrenciesCount': supportedCurrencies.length,
      'hasRates': _cachedRates?['rates'] != null,
    };
  }

  /// Debug print currency information
  static Future<void> printCurrencyDebug() async {
    try {
      print('🔍 === CURRENCY SERVICE DEBUG ===');
      
      final status = getServiceStatus();
      print('🔍 Status: $status');
      
      if (_cachedRates != null) {
        final rates = _cachedRates!['rates'] as Map<String, dynamic>?;
        print('🔍 Available rates:');
        rates?.forEach((currency, rate) {
          if (supportedCurrencies.containsKey(currency)) {
            print('  $currency: $rate');
          }
        });
        
        // Test conversion
        print('🔍 Test conversions:');
        print('  1 USD = ${formatCurrency(amount: convertCurrency(amount: 1, fromCurrency: "USD", toCurrency: "IDR"), currency: "IDR")}');
        print('  100,000 IDR = ${formatCurrency(amount: convertCurrency(amount: 100000, fromCurrency: "IDR", toCurrency: "USD"), currency: "USD")}');
      }
      
      print('==============================');
    } catch (e) {
      print('❌ Error in currency debug: $e');
    }
  }

  /// Force refresh exchange rates
  static Future<bool> forceRefreshRates() async {
    try {
      print('🔄 Force refreshing exchange rates...');
      _cachedRates = null;
      _lastUpdate = null;
      
      return await updateExchangeRates();
    } catch (e) {
      print('❌ Error force refreshing rates: $e');
      return false;
    }
  }

  /// Clear cache
  static Future<void> clearCache() async {
    try {
      _cachedRates = null;
      _lastUpdate = null;
      
      // Remove from Hive
      final settingsBox = await HiveService.getSettingsBox();
      await settingsBox.delete('currency_rates');
      
      print('✅ Currency cache cleared');
    } catch (e) {
      print('❌ Error clearing currency cache: $e');
    }
  }
}