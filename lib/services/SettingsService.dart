// services/SettingsService.dart (SakuRimba)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../services/NotificationService.dart';
import '../services/CurrencyService.dart';
import '../services/TimeZoneService.dart';
import '../services/SensorService.dart';

class SettingsService {
  // Default settings
  static Map<String, dynamic> _defaultSettings = {
    // App Settings
    'app_language': 'id',
    'app_theme': 'light',
    'app_auto_update': true,
    
    // Notification Settings
    'notifications_enabled': true,
    'notifications_rental_reminders': true,
    'notifications_payment_alerts': true,
    'notifications_promotions': true,
    'notifications_system': true,
    'notifications_sound': true,
    'notifications_vibration': true,
    
    // Location Settings
    'location_enabled': true,
    'location_tracking': false,
    'location_auto_detect_camping': true,
    'location_nearby_radius': 50.0,
    
    // Currency Settings
    'currency_base': 'IDR',
    'currency_auto_convert': false,
    'currency_show_comparison': true,
    
    // Timezone Settings
    'timezone_default': 'WIB',
    'timezone_auto_detect': true,
    'timezone_show_multiple': false,
    
    // Sensor Settings
    'sensor_motion_detection': true,
    'sensor_altitude_estimation': true,
    'sensor_compass': true,
    'sensor_shake_threshold': 15.0,
    'sensor_tilt_threshold': 45.0,
    
    // Privacy Settings
    'privacy_analytics': true,
    'privacy_crash_reports': true,
    'privacy_location_data': true,
    'privacy_usage_data': false,
    
    // Display Settings
    'display_card_view': true,
    'display_show_prices': true,
    'display_show_availability': true,
    'display_items_per_page': 20,
    'display_image_quality': 'medium',
    
    // Search Settings
    'search_save_history': true,
    'search_auto_suggestions': true,
    'search_include_description': true,
    'search_fuzzy_matching': true,
    
    // Rental Settings
    'rental_auto_confirm_payment': true,
    'rental_reminder_hours': 24,
    'rental_default_duration': 3,
    'rental_require_phone_verification': false,
    
    // Cache Settings
    'cache_enabled': true,
    'cache_auto_clear': false,
    'cache_max_age_hours': 24,
    'cache_images': true,
  };

  // Current settings
  static Map<String, dynamic> _currentSettings = {};
  
  // Settings categories for UI organization
  static const Map<String, List<String>> _settingsCategories = {
    'general': [
      'app_language',
      'app_theme',
      'app_auto_update',
    ],
    'notifications': [
      'notifications_enabled',
      'notifications_rental_reminders',
      'notifications_payment_alerts',
      'notifications_promotions',
      'notifications_system',
      'notifications_sound',
      'notifications_vibration',
    ],
    'location': [
      'location_enabled',
      'location_tracking',
      'location_auto_detect_camping',
      'location_nearby_radius',
    ],
    'currency': [
      'currency_base',
      'currency_auto_convert',
      'currency_show_comparison',
    ],
    'timezone': [
      'timezone_default',
      'timezone_auto_detect',
      'timezone_show_multiple',
    ],
    'sensors': [
      'sensor_motion_detection',
      'sensor_altitude_estimation',
      'sensor_compass',
      'sensor_shake_threshold',
      'sensor_tilt_threshold',
    ],
    'privacy': [
      'privacy_analytics',
      'privacy_crash_reports',
      'privacy_location_data',
      'privacy_usage_data',
    ],
    'display': [
      'display_card_view',
      'display_show_prices',
      'display_show_availability',
      'display_items_per_page',
      'display_image_quality',
    ],
    'search': [
      'search_save_history',
      'search_auto_suggestions',
      'search_include_description',
      'search_fuzzy_matching',
    ],
    'rental': [
      'rental_auto_confirm_payment',
      'rental_reminder_hours',
      'rental_default_duration',
      'rental_require_phone_verification',
    ],
    'cache': [
      'cache_enabled',
      'cache_auto_clear',
      'cache_max_age_hours',
      'cache_images',
    ],
  };

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize settings service
  static Future<void> init() async {
    try {
      print('⚙️ Initializing SettingsService...');
      
      // Load user settings
      await _loadSettings();
      
      // Apply settings to other services
      await _applySettingsToServices();
      
      print('✅ SettingsService initialized');
    } catch (e) {
      print('❌ Error initializing SettingsService: $e');
    }
  }

  /// Load settings from storage
  static Future<void> _loadSettings() async {
    try {
      final userId = UserService.getCurrentUserId();
      final settingsKey = userId != null ? 'user_settings_$userId' : 'app_settings';
      
      final savedSettings = await HiveService.getSetting<Map<dynamic, dynamic>>(settingsKey);
      
      if (savedSettings != null) {
        _currentSettings = Map<String, dynamic>.from(savedSettings);
      } else {
        _currentSettings = Map.from(_defaultSettings);
      }
      
      // Ensure all default settings are present
      for (var entry in _defaultSettings.entries) {
        if (!_currentSettings.containsKey(entry.key)) {
          _currentSettings[entry.key] = entry.value;
        }
      }
      
      print('✅ Settings loaded for ${userId ?? 'guest'}');
    } catch (e) {
      print('❌ Error loading settings: $e');
      _currentSettings = Map.from(_defaultSettings);
    }
  }

  /// Save settings to storage
  static Future<void> _saveSettings() async {
    try {
      final userId = UserService.getCurrentUserId();
      final settingsKey = userId != null ? 'user_settings_$userId' : 'app_settings';
      
      await HiveService.saveSetting(settingsKey, _currentSettings);
      print('✅ Settings saved');
    } catch (e) {
      print('❌ Error saving settings: $e');
    }
  }

  // ============================================================================
  // SETTINGS GETTERS AND SETTERS
  // ============================================================================

  /// Get setting value
  static T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final value = _currentSettings[key];
      if (value is T) {
        return value;
      } else if (defaultValue != null) {
        return defaultValue;
      } else if (_defaultSettings.containsKey(key)) {
        return _defaultSettings[key] as T?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting setting $key: $e');
      return defaultValue;
    }
  }

  /// Set setting value
  static Future<void> setSetting<T>(String key, T value) async {
    try {
      _currentSettings[key] = value;
      await _saveSettings();
      
      // Apply setting to relevant service
      await _applySettingToService(key, value);
      
      print('✅ Setting updated: $key = $value');
    } catch (e) {
      print('❌ Error setting $key: $e');
    }
  }

  /// Get multiple settings
  static Map<String, dynamic> getSettings(List<String> keys) {
    final result = <String, dynamic>{};
    for (var key in keys) {
      result[key] = getSetting(key);
    }
    return result;
  }

  /// Set multiple settings
  static Future<void> setSettings(Map<String, dynamic> settings) async {
    try {
      _currentSettings.addAll(settings);
      await _saveSettings();
      
      // Apply settings to services
      for (var entry in settings.entries) {
        await _applySettingToService(entry.key, entry.value);
      }
      
      print('✅ Multiple settings updated: ${settings.keys.join(', ')}');
    } catch (e) {
      print('❌ Error setting multiple settings: $e');
    }
  }

  /// Reset setting to default
  static Future<void> resetSetting(String key) async {
    try {
      if (_defaultSettings.containsKey(key)) {
        await setSetting(key, _defaultSettings[key]);
        print('✅ Setting reset to default: $key');
      }
    } catch (e) {
      print('❌ Error resetting setting $key: $e');
    }
  }

  /// Reset all settings to default
  static Future<void> resetAllSettings() async {
    try {
      _currentSettings = Map.from(_defaultSettings);
      await _saveSettings();
      await _applySettingsToServices();
      
      print('✅ All settings reset to default');
    } catch (e) {
      print('❌ Error resetting all settings: $e');
    }
  }

  // ============================================================================
  // SETTINGS BY CATEGORY
  // ============================================================================

  /// Get settings by category
  static Map<String, dynamic> getSettingsByCategory(String category) {
    final keys = _settingsCategories[category] ?? [];
    return getSettings(keys);
  }

  /// Set settings by category
  static Future<void> setSettingsByCategory(String category, Map<String, dynamic> settings) async {
    try {
      final categoryKeys = _settingsCategories[category] ?? [];
      final filteredSettings = <String, dynamic>{};
      
      for (var entry in settings.entries) {
        if (categoryKeys.contains(entry.key)) {
          filteredSettings[entry.key] = entry.value;
        }
      }
      
      await setSettings(filteredSettings);
    } catch (e) {
      print('❌ Error setting category settings: $e');
    }
  }

  /// Get all categories
  static List<String> getCategories() {
    return _settingsCategories.keys.toList();
  }

  /// Get category keys
  static List<String> getCategoryKeys(String category) {
    return _settingsCategories[category] ?? [];
  }

  // ============================================================================
  // APPLY SETTINGS TO SERVICES
  // ============================================================================

  /// Apply all settings to relevant services
  static Future<void> _applySettingsToServices() async {
    try {
      // Currency settings
      if (_currentSettings['currency_base'] != null) {
        await CurrencyService.setBaseCurrency(_currentSettings['currency_base']);
      }
      
      // Timezone settings
      if (_currentSettings['timezone_default'] != null) {
        await TimeZoneService.setDefaultTimeZone(_currentSettings['timezone_default']);
      }
      
      // Sensor settings
      await SensorService.updateSettings(
        enableMotionDetection: _currentSettings['sensor_motion_detection'],
        enableAltitudeEstimation: _currentSettings['sensor_altitude_estimation'],
        enableCompass: _currentSettings['sensor_compass'],
        shakeThreshold: _currentSettings['sensor_shake_threshold']?.toDouble(),
        tiltThreshold: _currentSettings['sensor_tilt_threshold']?.toDouble(),
      );
      
      print('✅ Settings applied to all services');
    } catch (e) {
      print('❌ Error applying settings to services: $e');
    }
  }

  /// Apply single setting to relevant service
  static Future<void> _applySettingToService(String key, dynamic value) async {
    try {
      switch (key) {
        // Currency settings
        case 'currency_base':
          await CurrencyService.setBaseCurrency(value);
          break;
          
        // Timezone settings
        case 'timezone_default':
          await TimeZoneService.setDefaultTimeZone(value);
          break;
          
        // Sensor settings
        case 'sensor_motion_detection':
        case 'sensor_altitude_estimation':
        case 'sensor_compass':
        case 'sensor_shake_threshold':
        case 'sensor_tilt_threshold':
          await SensorService.updateSettings(
            enableMotionDetection: getSetting('sensor_motion_detection'),
            enableAltitudeEstimation: getSetting('sensor_altitude_estimation'),
            enableCompass: getSetting('sensor_compass'),
            shakeThreshold: getSetting<double>('sensor_shake_threshold'),
            tiltThreshold: getSetting<double>('sensor_tilt_threshold'),
          );
          break;
          
        // Notification settings
        case 'notifications_enabled':
          if (!value) {
            await NotificationService.cancelAllNotifications();
          }
          break;
      }
    } catch (e) {
      print('❌ Error applying setting $key to service: $e');
    }
  }

  // ============================================================================
  // THEME AND APPEARANCE
  // ============================================================================

  /// Get current theme
  static String getTheme() {
    return getSetting<String>('app_theme', defaultValue: 'light') ?? 'light';
  }

  /// Set theme
  static Future<void> setTheme(String theme) async {
    await setSetting('app_theme', theme);
  }

  /// Toggle theme
  static Future<void> toggleTheme() async {
    final currentTheme = getTheme();
    final newTheme = currentTheme == 'light' ? 'dark' : 'light';
    await setTheme(newTheme);
  }

  /// Check if dark theme is enabled
  static bool isDarkTheme() {
    return getTheme() == 'dark';
  }

  // ============================================================================
  // LANGUAGE SETTINGS
  // ============================================================================

  /// Get current language
  static String getLanguage() {
    return getSetting<String>('app_language', defaultValue: 'id') ?? 'id';
  }

  /// Set language
  static Future<void> setLanguage(String language) async {
    await setSetting('app_language', language);
  }

  /// Get supported languages
  static List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'id', 'name': 'Bahasa Indonesia'},
      {'code': 'en', 'name': 'English'},
    ];
  }

  // ============================================================================
  // NOTIFICATION PREFERENCES
  // ============================================================================

  /// Check if notifications are enabled
  static bool areNotificationsEnabled() {
    return getSetting<bool>('notifications_enabled', defaultValue: true) ?? true;
  }

  /// Enable/disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await setSetting('notifications_enabled', enabled);
  }

  /// Check specific notification type
  static bool isNotificationTypeEnabled(String type) {
    return getSetting<bool>('notifications_$type', defaultValue: true) ?? true;
  }

  /// Set specific notification type
  static Future<void> setNotificationTypeEnabled(String type, bool enabled) async {
    await setSetting('notifications_$type', enabled);
  }

  // ============================================================================
  // PRIVACY SETTINGS
  // ============================================================================

  /// Check if analytics are enabled
  static bool areAnalyticsEnabled() {
    return getSetting<bool>('privacy_analytics', defaultValue: true) ?? true;
  }

  /// Enable/disable analytics
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    await setSetting('privacy_analytics', enabled);
  }

  /// Check if location data is enabled
  static bool isLocationDataEnabled() {
    return getSetting<bool>('privacy_location_data', defaultValue: true) ?? true;
  }

  /// Enable/disable location data
  static Future<void> setLocationDataEnabled(bool enabled) async {
    await setSetting('privacy_location_data', enabled);
  }

  // ============================================================================
  // EXPORT AND IMPORT
  // ============================================================================

  /// Export settings
  static Map<String, dynamic> exportSettings() {
    return {
      'settings': Map.from(_currentSettings),
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'userId': UserService.getCurrentUserId(),
    };
  }

  /// Import settings
  static Future<bool> importSettings(Map<String, dynamic> data) async {
    try {
      if (data['settings'] is Map<String, dynamic>) {
        final importedSettings = data['settings'] as Map<String, dynamic>;
        
        // Validate settings
        final validSettings = <String, dynamic>{};
        for (var entry in importedSettings.entries) {
          if (_defaultSettings.containsKey(entry.key)) {
            validSettings[entry.key] = entry.value;
          }
        }
        
        await setSettings(validSettings);
        print('✅ Settings imported successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error importing settings: $e');
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get all current settings
  static Map<String, dynamic> getAllSettings() {
    return Map.from(_currentSettings);
  }

  /// Get default settings
  static Map<String, dynamic> getDefaultSettings() {
    return Map.from(_defaultSettings);
  }

  /// Check if setting has been modified from default
  static bool isSettingModified(String key) {
    return _currentSettings[key] != _defaultSettings[key];
  }

  /// Get modified settings
  static Map<String, dynamic> getModifiedSettings() {
    final modified = <String, dynamic>{};
    for (var entry in _currentSettings.entries) {
      if (entry.value != _defaultSettings[entry.key]) {
        modified[entry.key] = entry.value;
      }
    }
    return modified;
  }

  /// Validate setting value
  static bool validateSetting(String key, dynamic value) {
    // Add validation logic based on setting type
    switch (key) {
      case 'app_language':
        return ['id', 'en'].contains(value);
      case 'app_theme':
        return ['light', 'dark', 'auto'].contains(value);
      case 'currency_base':
        return CurrencyService.isCurrencySupported(value);
      case 'timezone_default':
        return TimeZoneService.isTimeZoneSupported(value);
      case 'location_nearby_radius':
        return value is num && value > 0 && value <= 200;
      case 'sensor_shake_threshold':
      case 'sensor_tilt_threshold':
        return value is num && value > 0 && value <= 100;
      case 'display_items_per_page':
        return value is int && value > 0 && value <= 100;
      case 'rental_reminder_hours':
        return value is int && value >= 1 && value <= 168; // Max 1 week
      case 'cache_max_age_hours':
        return value is int && value >= 1 && value <= 720; // Max 30 days
      default:
        return true; // Allow other values
    }
  }

  // ============================================================================
  // DEBUG AND STATUS
  // ============================================================================

  /// Get settings service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'totalSettings': _currentSettings.length,
      'modifiedSettings': getModifiedSettings().length,
      'currentUser': UserService.getCurrentUserId(),
      'categories': _settingsCategories.length,
      'theme': getTheme(),
      'language': getLanguage(),
      'notificationsEnabled': areNotificationsEnabled(),
    };
  }

  /// Debug print settings information
  static Future<void> printSettingsDebug() async {
    try {
      print('🔍 === SETTINGS SERVICE DEBUG ===');
      
      final status = getServiceStatus();
      print('🔍 Status: $status');
      
      print('🔍 Current settings:');
      _currentSettings.forEach((key, value) {
        final isModified = isSettingModified(key) ? '*' : '';
        print('  $key$isModified: $value');
      });
      
      print('🔍 Modified settings: ${getModifiedSettings().keys.join(', ')}');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in settings debug: $e');
    }
  }
}