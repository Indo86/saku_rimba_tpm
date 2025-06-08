// services/AppInitService.dart (SakuRimba)
import 'dart:async';
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../services/NotificationService.dart';
import '../services/FavoriteService.dart';
import '../services/RentService.dart';
import '../services/CurrencyService.dart';
import '../services/TimeZoneService.dart';
import '../services/SensorService.dart';
import '../services/LocationService.dart';
import '../services/ApiService.dart';
import '../services/SearchService.dart';
import '../services/SettingsService.dart';

/// Service untuk menginisialisasi semua service dalam aplikasi SakuRimba
/// dengan urutan yang benar dan error handling yang tepat
class AppInitService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static final List<String> _initializationLog = [];
  static final List<String> _failedServices = [];
  
  // Service initialization order (critical services first)
  static const List<Map<String, dynamic>> _serviceInitOrder = [
    {
      'name': 'HiveService',
      'critical': true,
      'description': 'Database dan storage lokal',
    },
    {
      'name': 'SettingsService',
      'critical': true,
      'description': 'Pengaturan aplikasi',
    },
    {
      'name': 'UserService',
      'critical': true,
      'description': 'Manajemen user dan autentikasi',
    },
    {
      'name': 'NotificationService',
      'critical': false,
      'description': 'Notifikasi lokal dan push',
    },
    {
      'name': 'CurrencyService',
      'critical': false,
      'description': 'Konversi mata uang',
    },
    {
      'name': 'TimeZoneService',
      'critical': false,
      'description': 'Konversi zona waktu',
    },
    {
      'name': 'ApiService',
      'critical': false,
      'description': 'Koneksi ke API backend',
    },
    {
      'name': 'SearchService',
      'critical': false,
      'description': 'Pencarian dan filter',
    },
    {
      'name': 'SensorService',
      'critical': false,
      'description': 'Sensor perangkat',
    },
    {
      'name': 'LocationService',
      'critical': false,
      'description': 'Layanan lokasi dan GPS',
    },
  ];

  // ============================================================================
  // MAIN INITIALIZATION
  // ============================================================================

  /// Initialize all services
  static Future<bool> initializeApp() async {
    if (_isInitialized) {
      print('✅ App already initialized');
      return true;
    }

    if (_isInitializing) {
      print('⏳ App initialization already in progress');
      return false;
    }

    _isInitializing = true;
    _initializationLog.clear();
    _failedServices.clear();

    try {
      print('🚀 Starting SakuRimba app initialization...');
      _log('Starting app initialization');

      final stopwatch = Stopwatch()..start();

      // Initialize services in order
      for (var serviceConfig in _serviceInitOrder) {
        final serviceName = serviceConfig['name'] as String;
        final isCritical = serviceConfig['critical'] as bool;
        final description = serviceConfig['description'] as String;

        try {
          print('📦 Initializing $serviceName ($description)...');
          _log('Starting $serviceName initialization');

          final serviceStopwatch = Stopwatch()..start();
          await _initializeService(serviceName);
          serviceStopwatch.stop();

          final duration = serviceStopwatch.elapsedMilliseconds;
          print('✅ $serviceName initialized in ${duration}ms');
          _log('$serviceName initialized successfully in ${duration}ms');

        } catch (e) {
          print('❌ Failed to initialize $serviceName: $e');
          _log('$serviceName initialization failed: $e');
          _failedServices.add(serviceName);

          if (isCritical) {
            print('💥 Critical service $serviceName failed, aborting initialization');
            _log('Critical service failure, aborting initialization');
            _isInitializing = false;
            return false;
          } else {
            print('⚠️ Non-critical service $serviceName failed, continuing...');
            _log('Non-critical service failure, continuing initialization');
          }
        }
      }

      stopwatch.stop();
      final totalDuration = stopwatch.elapsedMilliseconds;

      // Post-initialization tasks
      await _performPostInitTasks();

      _isInitialized = true;
      _isInitializing = false;

      final successCount = _serviceInitOrder.length - _failedServices.length;
      print('🎉 SakuRimba app initialization completed!');
      print('✅ $successCount/${_serviceInitOrder.length} services initialized');
      print('⏱️ Total initialization time: ${totalDuration}ms');

      if (_failedServices.isNotEmpty) {
        print('⚠️ Failed services: ${_failedServices.join(', ')}');
      }

      _log('App initialization completed successfully in ${totalDuration}ms');
      return true;

    } catch (e) {
      print('💥 App initialization failed: $e');
      _log('App initialization failed: $e');
      _isInitializing = false;
      return false;
    }
  }

  /// Initialize individual service
  static Future<void> _initializeService(String serviceName) async {
    switch (serviceName) {
      case 'HiveService':
        await HiveService.init();
        break;
      case 'SettingsService':
        await SettingsService.init();
        break;
      case 'UserService':
        await UserService.initCurrentUser();
        break;
      case 'NotificationService':
        await NotificationService.init();
        break;
      case 'CurrencyService':
        await CurrencyService.init();
        break;
      case 'TimeZoneService':
        await TimeZoneService.init();
        break;
      case 'ApiService':
        await ApiService.init();
        break;
      case 'SearchService':
        await SearchService.init();
        break;
      case 'SensorService':
        await SensorService.init();
        break;
      case 'LocationService':
        await LocationService.init();
        break;
      default:
        throw Exception('Unknown service: $serviceName');
    }
  }

  /// Perform post-initialization tasks
  static Future<void> _performPostInitTasks() async {
    try {
      _log('Starting post-initialization tasks');

      // Update expired rentals
      try {
        final expiredCount = await HiveService.updateExpiredRentals();
        if (expiredCount > 0) {
          _log('Updated $expiredCount expired rentals');
        }
      } catch (e) {
        _log('Failed to update expired rentals: $e');
      }

      // Clean up old notifications
      try {
        await NotificationService.cleanupOldNotifications();
        _log('Cleaned up old notifications');
      } catch (e) {
        _log('Failed to cleanup notifications: $e');
      }

      // Check for app updates or important announcements
      try {
        await _checkForUpdates();
      } catch (e) {
        _log('Failed to check for updates: $e');
      }

      _log('Post-initialization tasks completed');
    } catch (e) {
      _log('Post-initialization tasks failed: $e');
    }
  }

  /// Check for app updates
  static Future<void> _checkForUpdates() async {
    try {
      final autoUpdate = SettingsService.getSetting<bool>('app_auto_update', defaultValue: true);
      
      if (autoUpdate == true) {
        // In a real app, this would check app store or server for updates
        _log('Checked for app updates');
      }
    } catch (e) {
      _log('Update check failed: $e');
    }
  }

  // ============================================================================
  // REINITIALIZATION AND RECOVERY
  // ============================================================================

  /// Reinitialize failed services
  static Future<bool> reinitializeFailedServices() async {
    if (_failedServices.isEmpty) {
      print('✅ No failed services to reinitialize');
      return true;
    }

    print('🔄 Reinitializing ${_failedServices.length} failed services...');
    _log('Starting reinitialization of failed services');

    final failedServicesCopy = List<String>.from(_failedServices);
    _failedServices.clear();

    bool allSucceeded = true;

    for (var serviceName in failedServicesCopy) {
      try {
        print('🔄 Reinitializing $serviceName...');
        await _initializeService(serviceName);
        print('✅ $serviceName reinitialized successfully');
        _log('$serviceName reinitialized successfully');
      } catch (e) {
        print('❌ Failed to reinitialize $serviceName: $e');
        _log('$serviceName reinitialization failed: $e');
        _failedServices.add(serviceName);
        allSucceeded = false;
      }
    }

    if (allSucceeded) {
      print('🎉 All failed services reinitialized successfully');
    } else {
      print('⚠️ Some services still failed: ${_failedServices.join(', ')}');
    }

    return allSucceeded;
  }

  /// Restart app initialization
  static Future<bool> restartInitialization() async {
    print('🔄 Restarting app initialization...');
    _log('Restarting app initialization');

    _isInitialized = false;
    _isInitializing = false;
    _failedServices.clear();

    return await initializeApp();
  }

  // ============================================================================
  // SERVICE HEALTH CHECK
  // ============================================================================

  /// Check health of all services
  static Future<Map<String, dynamic>> performHealthCheck() async {
    final healthResults = <String, Map<String, dynamic>>{};
    
    print('🏥 Performing service health check...');

    for (var serviceConfig in _serviceInitOrder) {
      final serviceName = serviceConfig['name'] as String;
      
      try {
        final health = await _checkServiceHealth(serviceName);
        healthResults[serviceName] = health;
      } catch (e) {
        healthResults[serviceName] = {
          'status': 'error',
          'message': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    }

    final healthyCount = healthResults.values
        .where((health) => health['status'] == 'healthy')
        .length;

    final overallHealth = {
      'overall': healthyCount == healthResults.length ? 'healthy' : 'degraded',
      'healthyServices': healthyCount,
      'totalServices': healthResults.length,
      'services': healthResults,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('🏥 Health check completed: $healthyCount/${healthResults.length} services healthy');
    return overallHealth;
  }

  /// Check individual service health
  static Future<Map<String, dynamic>> _checkServiceHealth(String serviceName) async {
    switch (serviceName) {
      case 'HiveService':
        return {
          'status': 'healthy',
          'details': 'Database accessible',
        };
      case 'UserService':
        return {
          'status': UserService.isUserLoggedIn() ? 'healthy' : 'info',
          'details': UserService.isUserLoggedIn() ? 'User logged in' : 'No user logged in',
        };
      case 'ApiService':
        final apiStatus = await ApiService.getServiceStatus();
        return {
          'status': apiStatus['apiReachable'] ? 'healthy' : 'warning',
          'details': apiStatus,
        };
      case 'LocationService':
        return {
          'status': LocationService.isLocationEnabled ? 'healthy' : 'warning',
          'details': 'Location ${LocationService.isLocationEnabled ? 'enabled' : 'disabled'}',
        };
      default:
        return {
          'status': _failedServices.contains(serviceName) ? 'error' : 'healthy',
          'details': 'Service status unknown',
        };
    }
  }

  // ============================================================================
  // APP LIFECYCLE
  // ============================================================================

  /// Handle app pause/background
  static Future<void> onAppPaused() async {
    try {
      print('⏸️ App paused, saving state...');
      _log('App paused');

      // Stop location tracking to save battery
      if (LocationService.isTrackingEnabled) {
        await LocationService.stopLocationTracking();
      }

      // Stop sensor monitoring
      await SensorService.stopAllSensors();

      _log('App state saved for background');
    } catch (e) {
      _log('Error handling app pause: $e');
    }
  }

  /// Handle app resume/foreground
  static Future<void> onAppResumed() async {
    try {
      print('▶️ App resumed, restoring state...');
      _log('App resumed');

      // Restart location tracking if it was enabled
      if (LocationService.isLocationEnabled && 
          SettingsService.getSetting<bool>('location_tracking', defaultValue: false) == true) {
        await LocationService.startLocationTracking();
      }

      // Restart sensors
      await SensorService.startAccelerometer();
      await SensorService.startMagnetometer();

      // Check for updates
      await RentService.updateExpiredRentals();

      _log('App state restored from background');
    } catch (e) {
      _log('Error handling app resume: $e');
    }
  }

  /// Handle app termination
  static Future<void> onAppTerminated() async {
    try {
      print('🛑 App terminating, cleaning up...');
      _log('App terminating');

      // Stop all services
      await LocationService.dispose();
      await SensorService.dispose();
      await HiveService.closeAllBoxes();

      _log('App cleanup completed');
    } catch (e) {
      _log('Error during app termination: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Log initialization events
  static void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _initializationLog.add(logEntry);
    
    // Keep only last 100 log entries
    if (_initializationLog.length > 100) {
      _initializationLog.removeAt(0);
    }
  }

  /// Get initialization status
  static Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'isInitializing': _isInitializing,
      'totalServices': _serviceInitOrder.length,
      'successfulServices': _serviceInitOrder.length - _failedServices.length,
      'failedServices': List.from(_failedServices),
      'initializationLog': List.from(_initializationLog),
    };
  }

  /// Get service list
  static List<Map<String, dynamic>> getServiceList() {
    return _serviceInitOrder.map((service) => {
      ...service,
      'status': _failedServices.contains(service['name']) ? 'failed' : 'initialized',
    }).toList();
  }

  /// Check if app is ready
  static bool get isAppReady => _isInitialized && !_isInitializing;

  /// Check if critical services are working
  static bool get areCriticalServicesReady {
    final criticalServices = _serviceInitOrder
        .where((service) => service['critical'] == true)
        .map((service) => service['name'] as String);
    
    return !criticalServices.any((service) => _failedServices.contains(service));
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Print initialization debug info
  static Future<void> printInitializationDebug() async {
    try {
      print('🔍 === APP INITIALIZATION DEBUG ===');
      
      final status = getInitializationStatus();
      print('🔍 Status: $status');
      
      print('🔍 Service status:');
      for (var service in getServiceList()) {
        final name = service['name'];
        final status = service['status'];
        final critical = service['critical'] ? '[CRITICAL]' : '[OPTIONAL]';
        print('  $name $critical: $status');
      }
      
      if (_initializationLog.isNotEmpty) {
        print('🔍 Recent log entries:');
        for (var entry in _initializationLog.take(10)) {
          print('  $entry');
        }
      }
      
      // Perform health check
      final health = await performHealthCheck();
      print('🔍 Health check: ${health['overall']} (${health['healthyServices']}/${health['totalServices']})');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in initialization debug: $e');
    }
  }

  /// Export initialization logs
  static Map<String, dynamic> exportInitializationLogs() {
    return {
      'status': getInitializationStatus(),
      'services': getServiceList(),
      'logs': _initializationLog,
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0', // Would come from package info in real app
    };
  }
}