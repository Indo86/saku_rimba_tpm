// services/TimeZoneService.dart (SakuRimba)
import 'package:intl/intl.dart';

class TimeZoneService {
  static String _defaultTimeZone = 'WIB';
  
  // Indonesian time zones
  static const Map<String, Map<String, dynamic>> _timeZones = {
    'WIB': {
      'name': 'Waktu Indonesia Barat',
      'full_name': 'Western Indonesia Time',
      'offset': '+07:00',
      'offset_hours': 7,
      'cities': ['Jakarta', 'Bandung', 'Medan', 'Palembang', 'Semarang'],
    },
    'WITA': {
      'name': 'Waktu Indonesia Tengah',
      'full_name': 'Central Indonesia Time',
      'offset': '+08:00',
      'offset_hours': 8,
      'cities': ['Denpasar', 'Makassar', 'Balikpapan', 'Banjarmasin'],
    },
    'WIT': {
      'name': 'Waktu Indonesia Timur',
      'full_name': 'Eastern Indonesia Time',
      'offset': '+09:00',
      'offset_hours': 9,
      'cities': ['Jayapura', 'Ambon', 'Manokwari'],
    },
  };

  /// Get current default timezone
  static String getDefaultTimeZone() {
    return _defaultTimeZone;
  }

  /// Set default timezone
  static Future<void> setDefaultTimeZone(String timeZone) async {
    try {
      if (_timeZones.containsKey(timeZone)) {
        _defaultTimeZone = timeZone;
        print('✅ Default timezone set to: $timeZone');
      } else {
        throw Exception('Unsupported timezone: $timeZone');
      }
    } catch (e) {
      print('❌ Error setting default timezone: $e');
      rethrow;
    }
  }

  /// Check if timezone is supported
  static bool isTimeZoneSupported(String timeZone) {
    return _timeZones.containsKey(timeZone);
  }

  /// Get all supported timezones
  static List<Map<String, dynamic>> getSupportedTimeZones() {
    return _timeZones.entries.map((entry) {
      return {
        'code': entry.key,
        'name': entry.value['name'],
        'full_name': entry.value['full_name'],
        'offset': entry.value['offset'],
        'cities': entry.value['cities'],
      };
    }).toList();
  }

  /// Get current time in specific timezone
  static DateTime getCurrentTime({String? timeZone}) {
    try {
      final targetTimeZone = timeZone ?? _defaultTimeZone;
      
      if (!_timeZones.containsKey(targetTimeZone)) {
        throw Exception('Unsupported timezone: $targetTimeZone');
      }

      final utcNow = DateTime.now().toUtc();
      final offsetHours = _timeZones[targetTimeZone]!['offset_hours'] as int;
      
      return utcNow.add(Duration(hours: offsetHours));
    } catch (e) {
      print('❌ Error getting current time: $e');
      return DateTime.now();
    }
  }

  /// Convert time between timezones
  static DateTime convertTime(DateTime dateTime, String fromTimeZone, String toTimeZone) {
    try {
      if (!_timeZones.containsKey(fromTimeZone) || !_timeZones.containsKey(toTimeZone)) {
        throw Exception('Unsupported timezone');
      }

      if (fromTimeZone == toTimeZone) {
        return dateTime;
      }

      final fromOffset = _timeZones[fromTimeZone]!['offset_hours'] as int;
      final toOffset = _timeZones[toTimeZone]!['offset_hours'] as int;
      
      // Convert to UTC first, then to target timezone
      final utcTime = dateTime.subtract(Duration(hours: fromOffset));
      return utcTime.add(Duration(hours: toOffset));
    } catch (e) {
      print('❌ Error converting time: $e');
      return dateTime;
    }
  }

  /// Format time with timezone
  static String formatTimeWithTimeZone(DateTime dateTime, {String? timeZone, String? pattern}) {
    try {
      final targetTimeZone = timeZone ?? _defaultTimeZone;
      final timePattern = pattern ?? 'HH:mm:ss';
      
      final formatter = DateFormat(timePattern);
      final timeString = formatter.format(dateTime);
      
      return '$timeString $targetTimeZone';
    } catch (e) {
      print('❌ Error formatting time: $e');
      return dateTime.toString();
    }
  }

  /// Format date with timezone
  static String formatDateWithTimeZone(DateTime dateTime, {String? timeZone, String? pattern}) {
    try {
      final targetTimeZone = timeZone ?? _defaultTimeZone;
      final datePattern = pattern ?? 'dd/MM/yyyy HH:mm';
      
      final formatter = DateFormat(datePattern);
      final dateString = formatter.format(dateTime);
      
      return '$dateString $targetTimeZone';
    } catch (e) {
      print('❌ Error formatting date: $e');
      return dateTime.toString();
    }
  }

  /// Get timezone offset
  static String getTimeZoneOffset(String timeZone) {
    return _timeZones[timeZone]?['offset'] ?? '+07:00';
  }

  /// Get timezone name
  static String getTimeZoneName(String timeZone) {
    return _timeZones[timeZone]?['name'] ?? timeZone;
  }

  /// Get timezone cities
  static List<String> getTimeZoneCities(String timeZone) {
    final cities = _timeZones[timeZone]?['cities'];
    return cities != null ? List<String>.from(cities) : [];
  }

  /// Get all current times
  static Map<String, String> getAllCurrentTimes() {
    final Map<String, String> currentTimes = {};
    
    for (String timeZone in _timeZones.keys) {
      try {
        final currentTime = getCurrentTime(timeZone: timeZone);
        currentTimes[timeZone] = formatTimeWithTimeZone(currentTime, timeZone: timeZone);
      } catch (e) {
        print('⚠️ Error getting time for $timeZone: $e');
      }
    }
    
    return currentTimes;
  }

  /// Calculate time difference between timezones
  static Duration getTimeDifference(String fromTimeZone, String toTimeZone) {
    try {
      if (!_timeZones.containsKey(fromTimeZone) || !_timeZones.containsKey(toTimeZone)) {
        return Duration.zero;
      }

      final fromOffset = _timeZones[fromTimeZone]!['offset_hours'] as int;
      final toOffset = _timeZones[toTimeZone]!['offset_hours'] as int;
      
      return Duration(hours: toOffset - fromOffset);
    } catch (e) {
      print('❌ Error calculating time difference: $e');
      return Duration.zero;
    }
  }

  /// Check if it's daytime in specific timezone
  static bool isDaytime({String? timeZone}) {
    try {
      final currentTime = getCurrentTime(timeZone: timeZone);
      final hour = currentTime.hour;
      
      // Consider 6 AM to 6 PM as daytime
      return hour >= 6 && hour < 18;
    } catch (e) {
      print('❌ Error checking daytime: $e');
      return true;
    }
  }

  /// Get business hours status
  static Map<String, dynamic> getBusinessHoursStatus({String? timeZone}) {
    try {
      final currentTime = getCurrentTime(timeZone: timeZone);
      final hour = currentTime.hour;
      final minute = currentTime.minute;
      
      // Business hours: 9 AM to 5 PM, Monday to Friday
      final isWeekday = currentTime.weekday >= 1 && currentTime.weekday <= 5;
      final isBusinessHour = hour >= 9 && hour < 17;
      final isOpen = isWeekday && isBusinessHour;
      
      String status;
      String nextOpen = '';
      
      if (isOpen) {
        status = 'Buka';
        final closingTime = DateTime(currentTime.year, currentTime.month, currentTime.day, 17, 0);
        final timeUntilClose = closingTime.difference(currentTime);
        nextOpen = 'Tutup dalam ${timeUntilClose.inHours}j ${timeUntilClose.inMinutes % 60}m';
      } else {
        status = 'Tutup';
        
        if (isWeekday && hour < 9) {
          // Same day opening
          final openingTime = DateTime(currentTime.year, currentTime.month, currentTime.day, 9, 0);
          final timeUntilOpen = openingTime.difference(currentTime);
          nextOpen = 'Buka dalam ${timeUntilOpen.inHours}j ${timeUntilOpen.inMinutes % 60}m';
        } else {
          // Next business day
          int daysUntilNextBusinessDay = 1;
          int nextWeekday = (currentTime.weekday % 7) + 1;
          
          while (nextWeekday > 5) {
            daysUntilNextBusinessDay++;
            nextWeekday = (nextWeekday % 7) + 1;
          }
          
          nextOpen = 'Buka ${daysUntilNextBusinessDay == 1 ? 'besok' : 'dalam $daysUntilNextBusinessDay hari'} jam 09:00';
        }
      }
      
      return {
        'is_open': isOpen,
        'status': status,
        'next_open': nextOpen,
        'current_time': formatTimeWithTimeZone(currentTime, timeZone: timeZone),
      };
    } catch (e) {
      print('❌ Error getting business hours status: $e');
      return {
        'is_open': false,
        'status': 'Unknown',
        'next_open': '',
        'current_time': '',
      };
    }
  }

  /// Auto-detect timezone based on system timezone (simplified)
  static String autoDetectTimeZone() {
    try {
      final systemTimeZone = DateTime.now().timeZoneOffset;
      final offsetHours = systemTimeZone.inHours;
      
      // Map system offset to Indonesian timezone
      switch (offsetHours) {
        case 7:
          return 'WIB';
        case 8:
          return 'WITA';
        case 9:
          return 'WIT';
        default:
          // Default to WIB if can't determine
          return 'WIB';
      }
    } catch (e) {
      print('❌ Error auto-detecting timezone: $e');
      return 'WIB';
    }
  }

  /// Get timezone information
  static Map<String, dynamic> getTimeZoneInfo() {
    return {
      'default_timezone': _defaultTimeZone,
      'supported_timezones': _timeZones.length,
      'current_times': getAllCurrentTimes(),
      'business_hours': getBusinessHoursStatus(),
      'auto_detected': autoDetectTimeZone(),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Debug method
  static void printTimeZoneDebug() {
    try {
      print('🔍 === TIMEZONE SERVICE DEBUG ===');
      print('Default timezone: $_defaultTimeZone');
      print('Supported timezones: ${_timeZones.keys.join(', ')}');
      
      final currentTimes = getAllCurrentTimes();
      print('Current times:');
      currentTimes.forEach((tz, time) {
        print('  $tz: $time');
      });
      
      final businessHours = getBusinessHoursStatus();
      print('Business hours: ${businessHours['status']} - ${businessHours['next_open']}');
      
      print('Auto-detected timezone: ${autoDetectTimeZone()}');
      print('==============================');
    } catch (e) {
      print('❌ Error in timezone debug: $e');
    }
  }
}