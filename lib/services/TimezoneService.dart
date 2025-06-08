// services/TimeZoneService.dart (SakuRimba)
import '../services/HiveService.dart';

class TimeZoneService {
  // Supported time zones with their UTC offsets
  static const Map<String, Map<String, dynamic>> supportedTimeZones = {
    'WIB': {
      'name': 'Waktu Indonesia Barat',
      'fullName': 'Western Indonesia Time',
      'utcOffset': 7,
      'description': 'Jakarta, Pontianak, Palembang',
      'countries': ['Indonesia (Barat)'],
    },
    'WITA': {
      'name': 'Waktu Indonesia Tengah',
      'fullName': 'Central Indonesia Time',
      'utcOffset': 8,
      'description': 'Denpasar, Makassar, Balikpapan',
      'countries': ['Indonesia (Tengah)'],
    },
    'WIT': {
      'name': 'Waktu Indonesia Timur',
      'fullName': 'Eastern Indonesia Time',
      'utcOffset': 9,
      'description': 'Jayapura, Ambon, Ternate',
      'countries': ['Indonesia (Timur)'],
    },
    'GMT': {
      'name': 'Greenwich Mean Time',
      'fullName': 'Greenwich Mean Time / UTC',
      'utcOffset': 0,
      'description': 'London (Winter), Dublin, Reykjavik',
      'countries': ['United Kingdom (Winter)', 'Ireland', 'Iceland'],
    },
    'BST': {
      'name': 'British Summer Time',
      'fullName': 'British Summer Time',
      'utcOffset': 1,
      'description': 'London (Summer), Edinburgh',
      'countries': ['United Kingdom (Summer)'],
    },
    'CET': {
      'name': 'Central European Time',
      'fullName': 'Central European Time',
      'utcOffset': 1,
      'description': 'Paris, Berlin, Rome',
      'countries': ['France', 'Germany', 'Italy'],
    },
    'JST': {
      'name': 'Japan Standard Time',
      'fullName': 'Japan Standard Time',
      'utcOffset': 9,
      'description': 'Tokyo, Osaka, Kyoto',
      'countries': ['Japan'],
    },
    'SGT': {
      'name': 'Singapore Time',
      'fullName': 'Singapore Standard Time',
      'utcOffset': 8,
      'description': 'Singapore, Kuala Lumpur',
      'countries': ['Singapore', 'Malaysia'],
    },
    'EST': {
      'name': 'Eastern Standard Time',
      'fullName': 'Eastern Standard Time (US)',
      'utcOffset': -5,
      'description': 'New York, Washington DC, Miami',
      'countries': ['United States (East Coast)'],
    },
    'PST': {
      'name': 'Pacific Standard Time',
      'fullName': 'Pacific Standard Time (US)',
      'utcOffset': -8,
      'description': 'Los Angeles, San Francisco, Seattle',
      'countries': ['United States (West Coast)'],
    },
  };

  // Default time zone for Indonesian users
  static String _defaultTimeZone = 'WIB';

  // ============================================================================
  // TIME ZONE CONVERSION
  // ============================================================================

  /// Initialize timezone service
  static Future<void> init() async {
    try {
      print('🕐 Initializing TimeZoneService...');
      
      // Load user's preferred timezone
      final savedTimeZone = await HiveService.getSetting<String>('default_timezone');
      if (savedTimeZone != null && supportedTimeZones.containsKey(savedTimeZone)) {
        _defaultTimeZone = savedTimeZone;
      }
      
      print('✅ TimeZoneService initialized with default: $_defaultTimeZone');
    } catch (e) {
      print('❌ Error initializing TimeZoneService: $e');
    }
  }

  /// Convert time from one timezone to another
  static DateTime convertTime({
    required DateTime dateTime,
    required String fromTimeZone,
    required String toTimeZone,
  }) {
    try {
      if (!supportedTimeZones.containsKey(fromTimeZone) ||
          !supportedTimeZones.containsKey(toTimeZone)) {
        throw Exception('Unsupported timezone');
      }

      final fromOffset = supportedTimeZones[fromTimeZone]!['utcOffset'] as int;
      final toOffset = supportedTimeZones[toTimeZone]!['utcOffset'] as int;

      // Convert to UTC first
      final utcTime = dateTime.subtract(Duration(hours: fromOffset));
      
      // Then convert to target timezone
      final targetTime = utcTime.add(Duration(hours: toOffset));

      return targetTime;
    } catch (e) {
      print('❌ Error converting time: $e');
      return dateTime; // Return original time if conversion fails
    }
  }

  /// Convert current time to different timezones
  static Map<String, DateTime> getCurrentTimeInAllZones() {
    final now = DateTime.now();
    Map<String, DateTime> times = {};

    for (String timeZone in supportedTimeZones.keys) {
      times[timeZone] = convertTime(
        dateTime: now,
        fromTimeZone: _defaultTimeZone,
        toTimeZone: timeZone,
      );
    }

    return times;
  }

  /// Get current time in specific timezone
  static DateTime getCurrentTimeInZone(String timeZone) {
    if (!supportedTimeZones.containsKey(timeZone)) {
      throw Exception('Unsupported timezone: $timeZone');
    }

    return convertTime(
      dateTime: DateTime.now(),
      fromTimeZone: _defaultTimeZone,
      toTimeZone: timeZone,
    );
  }

  /// Convert UTC time to specific timezone
  static DateTime convertFromUTC({
    required DateTime utcDateTime,
    required String toTimeZone,
  }) {
    if (!supportedTimeZones.containsKey(toTimeZone)) {
      throw Exception('Unsupported timezone: $toTimeZone');
    }

    final offset = supportedTimeZones[toTimeZone]!['utcOffset'] as int;
    return utcDateTime.add(Duration(hours: offset));
  }

  /// Convert specific timezone to UTC
  static DateTime convertToUTC({
    required DateTime dateTime,
    required String fromTimeZone,
  }) {
    if (!supportedTimeZones.containsKey(fromTimeZone)) {
      throw Exception('Unsupported timezone: $fromTimeZone');
    }

    final offset = supportedTimeZones[fromTimeZone]!['utcOffset'] as int;
    return dateTime.subtract(Duration(hours: offset));
  }

  // ============================================================================
  // INDONESIA-SPECIFIC FUNCTIONS
  // ============================================================================

  /// Get current time in all Indonesian time zones
  static Map<String, DateTime> getIndonesianTimes() {
    final now = DateTime.now();
    return {
      'WIB': convertTime(
        dateTime: now,
        fromTimeZone: _defaultTimeZone,
        toTimeZone: 'WIB',
      ),
      'WITA': convertTime(
        dateTime: now,
        fromTimeZone: _defaultTimeZone,
        toTimeZone: 'WITA',
      ),
      'WIT': convertTime(
        dateTime: now,
        fromTimeZone: _defaultTimeZone,
        toTimeZone: 'WIT',
      ),
    };
  }

  /// Convert between Indonesian time zones
  static DateTime convertBetweenIndonesianZones({
    required DateTime dateTime,
    required String fromZone,
    required String toZone,
  }) {
    final indonesianZones = ['WIB', 'WITA', 'WIT'];
    
    if (!indonesianZones.contains(fromZone) || !indonesianZones.contains(toZone)) {
      throw Exception('Invalid Indonesian timezone');
    }

    return convertTime(
      dateTime: dateTime,
      fromTimeZone: fromZone,
      toTimeZone: toZone,
    );
  }

  /// Get time difference between Indonesian zones
  static String getIndonesianTimeDifference(String zone1, String zone2) {
    final offset1 = supportedTimeZones[zone1]!['utcOffset'] as int;
    final offset2 = supportedTimeZones[zone2]!['utcOffset'] as int;
    final diff = offset2 - offset1;
    
    if (diff == 0) return 'Sama';
    if (diff > 0) return '+$diff jam';
    return '$diff jam';
  }

  // ============================================================================
  // RENTAL-SPECIFIC FUNCTIONS
  // ============================================================================

  /// Convert rental booking time to user's timezone
  static DateTime convertRentalTimeToUserZone({
    required DateTime rentalTime,
    required String rentalTimeZone,
  }) {
    return convertTime(
      dateTime: rentalTime,
      fromTimeZone: rentalTimeZone,
      toTimeZone: _defaultTimeZone,
    );
  }

  /// Get rental time in multiple zones for confirmation
  static Map<String, String> getRentalTimeInMultipleZones({
    required DateTime rentalTime,
    required String originalTimeZone,
  }) {
    final zones = ['WIB', 'WITA', 'WIT', 'GMT'];
    Map<String, String> times = {};

    for (String zone in zones) {
      final convertedTime = convertTime(
        dateTime: rentalTime,
        fromTimeZone: originalTimeZone,
        toTimeZone: zone,
      );
      times[zone] = formatDateTime(convertedTime);
    }

    return times;
  }

  /// Calculate rental duration accounting for timezone differences
  static Duration calculateRentalDuration({
    required DateTime startTime,
    required String startTimeZone,
    required DateTime endTime,
    required String endTimeZone,
  }) {
    // Convert both times to the same timezone (UTC) for accurate calculation
    final startUTC = convertToUTC(
      dateTime: startTime,
      fromTimeZone: startTimeZone,
    );
    final endUTC = convertToUTC(
      dateTime: endTime,
      fromTimeZone: endTimeZone,
    );

    return endUTC.difference(startUTC);
  }

  // ============================================================================
  // FORMATTING AND DISPLAY
  // ============================================================================

  /// Format datetime with timezone info
  static String formatDateTime(DateTime dateTime, {String? timeZone}) {
    final tz = timeZone ?? _defaultTimeZone;
    final tzInfo = supportedTimeZones[tz];
    
    final formatted = '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$formatted $tz';
  }

  /// Format time only with timezone
  static String formatTimeOnly(DateTime dateTime, {String? timeZone}) {
    final tz = timeZone ?? _defaultTimeZone;
    
    final formatted = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$formatted $tz';
  }

  /// Get formatted time for all Indonesian zones
  static Map<String, String> getFormattedIndonesianTimes() {
    final times = getIndonesianTimes();
    Map<String, String> formatted = {};

    times.forEach((zone, dateTime) {
      formatted[zone] = formatTimeOnly(dateTime, timeZone: zone);
    });

    return formatted;
  }

  /// Get user-friendly timezone description
  static String getTimeZoneDescription(String timeZone) {
    final tzInfo = supportedTimeZones[timeZone];
    if (tzInfo == null) return timeZone;
    
    return '${tzInfo['name']} (${tzInfo['description']})';
  }

  /// Get timezone offset string
  static String getTimeZoneOffsetString(String timeZone) {
    final offset = supportedTimeZones[timeZone]?['utcOffset'] as int?;
    if (offset == null) return '';
    
    if (offset == 0) return 'UTC+0';
    if (offset > 0) return 'UTC+$offset';
    return 'UTC$offset';
  }

  // ============================================================================
  // WORLD CLOCK FUNCTIONALITY
  // ============================================================================

  /// Get world clock for popular locations
  static Map<String, Map<String, dynamic>> getWorldClock() {
    final now = DateTime.now();
    Map<String, Map<String, dynamic>> worldClock = {};

    for (String timeZone in supportedTimeZones.keys) {
      final timeInZone = convertTime(
        dateTime: now,
        fromTimeZone: _defaultTimeZone,
        toTimeZone: timeZone,
      );

      worldClock[timeZone] = {
        'time': timeInZone,
        'formattedTime': formatTimeOnly(timeInZone, timeZone: timeZone),
        'formattedDateTime': formatDateTime(timeInZone, timeZone: timeZone),
        'description': supportedTimeZones[timeZone]!['description'],
        'offset': getTimeZoneOffsetString(timeZone),
        'isNextDay': timeInZone.day != now.day,
      };
    }

    return worldClock;
  }

  /// Get business hours information for different zones
  static Map<String, Map<String, dynamic>> getBusinessHours() {
    final worldClock = getWorldClock();
    Map<String, Map<String, dynamic>> businessHours = {};

    worldClock.forEach((timeZone, info) {
      final dateTime = info['time'] as DateTime;
      final hour = dateTime.hour;
      
      bool isBusinessHours = hour >= 9 && hour < 17; // 9 AM to 5 PM
      bool isWeekend = dateTime.weekday >= 6; // Saturday = 6, Sunday = 7
      
      businessHours[timeZone] = {
        ...info,
        'isBusinessHours': isBusinessHours && !isWeekend,
        'isWeekend': isWeekend,
        'businessStatus': _getBusinessStatus(hour, isWeekend),
      };
    });

    return businessHours;
  }

  static String _getBusinessStatus(int hour, bool isWeekend) {
    if (isWeekend) return 'Weekend';
    if (hour < 9) return 'Before Business Hours';
    if (hour >= 17) return 'After Business Hours';
    return 'Business Hours';
  }

  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  /// Set default timezone
  static Future<void> setDefaultTimeZone(String timeZone) async {
    try {
      if (!supportedTimeZones.containsKey(timeZone)) {
        throw Exception('Unsupported timezone: $timeZone');
      }

      _defaultTimeZone = timeZone;
      await HiveService.saveSetting('default_timezone', timeZone);
      
      print('✅ Default timezone set to: $timeZone');
    } catch (e) {
      print('❌ Error setting default timezone: $e');
    }
  }

  /// Get default timezone
  static String getDefaultTimeZone() {
    return _defaultTimeZone;
  }

  /// Get all supported timezones
  static Map<String, Map<String, dynamic>> getSupportedTimeZones() {
    return Map.from(supportedTimeZones);
  }

  /// Check if timezone is supported
  static bool isTimeZoneSupported(String timeZone) {
    return supportedTimeZones.containsKey(timeZone);
  }

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  /// Auto-detect timezone based on device location (simplified)
  /// Note: In a real app, you'd use location services and timezone APIs
  static String detectTimeZone({String? locationHint}) {
    // Simplified detection based on hint
    if (locationHint != null) {
      final hint = locationHint.toLowerCase();
      
      if (hint.contains('jakarta') || hint.contains('pontianak') || 
          hint.contains('palembang') || hint.contains('medan')) {
        return 'WIB';
      } else if (hint.contains('denpasar') || hint.contains('makassar') || 
                 hint.contains('balikpapan') || hint.contains('banjarmasin')) {
        return 'WITA';
      } else if (hint.contains('jayapura') || hint.contains('ambon') || 
                 hint.contains('ternate')) {
        return 'WIT';
      } else if (hint.contains('london') || hint.contains('dublin')) {
        return 'GMT';
      } else if (hint.contains('tokyo') || hint.contains('japan')) {
        return 'JST';
      } else if (hint.contains('singapore') || hint.contains('kuala lumpur')) {
        return 'SGT';
      }
    }
    
    return 'WIB'; // Default to WIB for Indonesian users
  }

  /// Get timezone service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'defaultTimeZone': _defaultTimeZone,
      'supportedTimeZonesCount': supportedTimeZones.length,
      'currentTime': DateTime.now().toIso8601String(),
      'currentTimeInDefault': getCurrentTimeInZone(_defaultTimeZone).toIso8601String(),
    };
  }

  /// Debug print timezone information
  static Future<void> printTimeZoneDebug() async {
    try {
      print('🔍 === TIMEZONE SERVICE DEBUG ===');
      
      final status = getServiceStatus();
      print('🔍 Status: $status');
      
      print('🔍 Current times in all zones:');
      final worldClock = getWorldClock();
      worldClock.forEach((zone, info) {
        print('  $zone: ${info['formattedDateTime']} (${info['offset']})');
      });
      
      print('🔍 Indonesian times:');
      final indonesianTimes = getFormattedIndonesianTimes();
      indonesianTimes.forEach((zone, time) {
        print('  $zone: $time');
      });
      
      print('🔍 Business hours status:');
      final businessHours = getBusinessHours();
      businessHours.forEach((zone, info) {
        print('  $zone: ${info['businessStatus']} (${info['formattedTime']})');
      });
      
      print('==============================');
    } catch (e) {
      print('❌ Error in timezone debug: $e');
    }
  }

  /// Calculate time until next hour in different zones
  static Map<String, Duration> getTimeUntilNextHour() {
    Map<String, Duration> timeUntilHour = {};
    
    supportedTimeZones.keys.forEach((zone) {
      final currentTime = getCurrentTimeInZone(zone);
      final nextHour = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        currentTime.hour + 1,
        0,
        0,
      );
      
      timeUntilHour[zone] = nextHour.difference(currentTime);
    });
    
    return timeUntilHour;
  }
}