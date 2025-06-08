// services/AppInitService.dart (SakuRimba) - FIXED
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../services/SettingsService.dart';
import '../services/NotificationService.dart';
import '../services/SensorService.dart';
import '../services/CurrencyService.dart';
import '../services/TimeZoneService.dart';

class AppInitService {
  /// Initialize the entire application
  static Future<bool> initializeApp() async {
    try {
      print('🚀 Starting SakuRimba app initialization...');
      
      // Step 1: Initialize Hive (database)
      print('📦 Initializing Hive database...');
      await HiveService.init();
      
      // Step 2: Initialize User Service
      print('👤 Initializing User Service...');
      await UserService.initCurrentUser();
      
      // Step 3: Initialize Settings Service
      print('⚙️ Initializing Settings Service...');
      await SettingsService.init();
      
      // Step 4: Initialize Notification Service
      print('🔔 Initializing Notification Service...');
      await NotificationService.init();
      
      // Step 5: Initialize Sensor Service (optional, can fail)
      print('📱 Initializing Sensor Service...');
      try {
        await SensorService.init();
      } catch (e) {
        print('⚠️ Sensor Service initialization failed (non-critical): $e');
      }
      
      // Step 6: Update expired rentals
      print('🔄 Checking for expired rentals...');
      try {
        final updatedCount = await HiveService.updateExpiredRentals();
        if (updatedCount > 0) {
          print('✅ Updated $updatedCount expired rentals');
        }
      } catch (e) {
        print('⚠️ Error updating expired rentals: $e');
      }
      
      // Step 7: Cleanup old data
      print('🧹 Performing maintenance tasks...');
      try {
        await _performMaintenanceTasks();
      } catch (e) {
        print('⚠️ Maintenance tasks failed (non-critical): $e');
      }
      
      // Step 8: Print initialization summary
      await _printInitializationSummary();
      
      print('✅ SakuRimba app initialization completed successfully!');
      return true;
      
    } catch (e) {
      print('❌ Critical error during app initialization: $e');
      return false;
    }
  }

  /// Perform maintenance tasks
  static Future<void> _performMaintenanceTasks() async {
    try {
      // Clean up old notifications (keep only last 500)
      await NotificationService.cleanupOldNotifications();
      
      // Clean up old rentals (keep only last 100 completed)
      // This is commented out as it's implemented in RentService
      // await RentService.cleanupOldRentals();
      
      // Clean up invalid favorites
      // This is commented out as it requires user login check
      // await FavoriteService.cleanupInvalidFavorites();
      
      print('✅ Maintenance tasks completed');
    } catch (e) {
      print('❌ Error in maintenance tasks: $e');
    }
  }

  /// Print initialization summary
  static Future<void> _printInitializationSummary() async {
    try {
      print('\n🔍 === SAKURIMBA INITIALIZATION SUMMARY ===');

      // User info
      if (UserService.isUserLoggedIn()) {
        final user = UserService.getCurrentUser();
        print(
          '👤 Logged in user: '
          '${user?.displayName ?? user?.username ?? 'Unknown'}'
        );
        print(
          '📊 Profile completion: '
          '${UserService.getUserProfileCompletion().toInt()}%'
        );
      } else {
        print('👤 No user logged in (guest mode)');
      }

      // Database stats
      final allUsers = await UserService.getAllUsers();
      print('👥 Total registered users: ${allUsers.length}');

      // Settings info - FIXED: Added proper null checking
      final settingsStatus = SettingsService.getServiceStatus();
      if (settingsStatus is Map<String, dynamic>) {
        final totalSettings = settingsStatus['totalSettings'] as int? ?? 0;
        print('⚙️ Settings: $totalSettings configured');
      } else {
        print('⚙️ Settings: Unable to retrieve settings count');
      }

      // Theme & Language
      print('🎨 Theme: ${SettingsService.getTheme()}');
      print('🌐 Language: ${SettingsService.getLanguage()}');

      // Notifications
      if (UserService.isUserLoggedIn()) {
        final unreadCount = await NotificationService.getUnreadCount();
        print('🔔 Unread notifications: $unreadCount');
      }

      // Sensors - FIXED: Added proper null checking
      final sensorStatus = SensorService.getSensorStatus();
      if (sensorStatus is Map<String, dynamic>) {
        final sensorsInited = sensorStatus['initialized'] as bool? ?? false;
        print('📱 Sensors initialized: $sensorsInited');
      } else {
        print('📱 Sensors initialized: false');
      }

      // App info
      print('📅 Initialization time: ${DateTime.now()}');
      print('🏷️ App version: 1.0.0');

      print('==========================================\n');
    } catch (e) {
      print('❌ Error printing initialization summary: $e');
    }
  }

  /// Check app health after initialization
  static Future<Map<String, dynamic>> checkAppHealth() async {
    try {
      // FIXED: Create properly typed nested maps
      final services = <String, dynamic>{};
      final database = <String, dynamic>{};
      final user = <String, dynamic>{};
      
      final health = {
        'overall_status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'services': services,
        'database': database,
        'user': user,
      };
      
      // Check Hive service
      try {
        final allUsers = await UserService.getAllUsers();
        services['hive'] = 'healthy';
        database['total_users'] = allUsers.length;
      } catch (e) {
        services['hive'] = 'error: $e';
        health['overall_status'] = 'degraded';
      }
      
      // Check User service
      try {
        final isLoggedIn = UserService.isUserLoggedIn();
        services['user'] = 'healthy';
        user['logged_in'] = isLoggedIn;
        
        if (isLoggedIn) {
          final currentUser = UserService.getCurrentUser();
          user['username'] = currentUser?.username;
          user['profile_completion'] = UserService.getUserProfileCompletion();
        }
      } catch (e) {
        services['user'] = 'error: $e';
        health['overall_status'] = 'degraded';
      }
      
      // Check Settings service
      try {
        final settingsStatus = SettingsService.getServiceStatus();
        services['settings'] = 'healthy';
        health['settings'] = settingsStatus;
      } catch (e) {
        services['settings'] = 'error: $e';
        health['overall_status'] = 'degraded';
      }
      
      // Check Notification service
      try {
        if (UserService.isUserLoggedIn()) {
          final unreadCount = await NotificationService.getUnreadCount();
          services['notifications'] = 'healthy';
          health['notifications'] = {'unread_count': unreadCount};
        } else {
          services['notifications'] = 'not_applicable_guest_mode';
        }
      } catch (e) {
        services['notifications'] = 'error: $e';
        health['overall_status'] = 'degraded';
      }
      
      // Check Sensor service - FIXED: Added proper null checking
      try {
        final sensorStatus = SensorService.getSensorStatus();
        if (sensorStatus is Map<String, dynamic>) {
          final initialized = sensorStatus['initialized'] as bool? ?? false;
          services['sensors'] = initialized ? 'healthy' : 'disabled';
          health['sensors'] = sensorStatus;
        } else {
          services['sensors'] = 'disabled';
          health['sensors'] = {'initialized': false};
        }
      } catch (e) {
        services['sensors'] = 'error: $e';
        // Sensors are optional, don't degrade overall status
      }
      
      return health;
    } catch (e) {
      return {
        'overall_status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Restart app services (for recovery)
  static Future<bool> restartServices() async {
    try {
      print('🔄 Restarting SakuRimba services...');
      
      // Stop and restart critical services
      await NotificationService.cancelAllNotifications();
      await SensorService.dispose();
      
      // Reinitialize
      await NotificationService.init();
      await SensorService.init();
      
      print('✅ Services restarted successfully');
      return true;
    } catch (e) {
      print('❌ Error restarting services: $e');
      return false;
    }
  }

  /// Emergency shutdown
  static Future<void> emergencyShutdown() async {
    try {
      print('🚨 Emergency shutdown initiated...');
      
      // Cancel all notifications
      await NotificationService.cancelAllNotifications();
      
      // Dispose sensors
      await SensorService.dispose();
      
      // Close all Hive boxes
      await HiveService.closeAllBoxes();
      
      print('✅ Emergency shutdown completed');
    } catch (e) {
      print('❌ Error during emergency shutdown: $e');
    }
  }

  /// Get initialization report
  static Future<Map<String, dynamic>> getInitializationReport() async {
    try {
      // Pastikan tipe report adalah Map<String, dynamic>
      final Map<String, dynamic> report = {
        'app_name': 'SakuRimba',
        'version': '1.0.0',
        'initialization_time': DateTime.now().toIso8601String(),
        'status': 'initialized',
      };
      
      // Add health check (Map<String, dynamic>)
      final Map<String, dynamic> health = await checkAppHealth();
      report['health'] = health;
      
      // Add user stats (bisa Map atau primitive)
      if (UserService.isUserLoggedIn()) {
        final dynamic userStats = await UserService.getUserStats();
        report['user_stats'] = userStats;
      }
      
      return report;
    } catch (e) {
      // Juga kembalikan Map<String, dynamic>
      return <String, dynamic>{
        'app_name': 'SakuRimba',
        'status': 'error',
        'error': e.toString(),
        'initialization_time': DateTime.now().toIso8601String(),
      };
    }
  }


  /// Check if app needs reinitialization
  static Future<bool> needsReinitialization() async {
    try {
      // Check if critical services are working
      final health = await checkAppHealth();
      return health['overall_status'] == 'error';
    } catch (e) {
      return true;
    }
  }

  /// Perform app update migration (for future use)
  static Future<void> performMigration(String fromVersion, String toVersion) async {
    try {
      print('🔄 Performing migration from $fromVersion to $toVersion...');
      
      // Migration logic would go here
      // For example:
      // - Database schema updates
      // - Settings migration
      // - Data format changes
      
      print('✅ Migration completed successfully');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Debug method to print all service statuses
  static Future<void> printDebugInfo() async {
    try {
      print('\n🔍 === SAKURIMBA DEBUG INFO ===');
      
      // Print each service debug info
      await UserService.printUserDebug();
      await SettingsService.printSettingsDebug();
      await NotificationService.printNotificationDebug();
      SensorService.printSensorDebug();
      CurrencyService.printCurrencyDebug();
      TimeZoneService.printTimeZoneDebug();
      
      // Print health check
      final health = await checkAppHealth();
      print('🏥 App Health: ${health['overall_status']}');
      
      print('==============================\n');
    } catch (e) {
      print('❌ Error printing debug info: $e');
    }
  }
}