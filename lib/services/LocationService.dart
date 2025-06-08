// services/LocationService.dart (SakuRimba)
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../services/HiveService.dart';
import '../services/NotificationService.dart';

class LocationService {
  // Current location data
  static Position? _currentPosition;
  static Placemark? _currentPlacemark;
  static String? _currentAddress;

  // Location settings
  static bool _isLocationEnabled = false;
  static bool _isTrackingEnabled = false;
  static LocationSettings? _locationSettings;

  // Location stream
  static StreamSubscription<Position>? _positionStream;

  // Nearby camping spots cache
  static List<Map<String, dynamic>> _nearbyCampingSpots = [];
  static DateTime? _lastCampingSpotsUpdate;

  // Location history
  static List<Map<String, dynamic>> _locationHistory = [];
  static int _maxHistoryEntries = 100;

  // Geofencing
  static List<Map<String, dynamic>> _geofences = [];
  static final Set<String> _triggeredGeofences = {};

  // Weather API (optional - for camping weather info)
  static const String _weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String _weatherApiUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // ============================================================================
  // INITIALIZATION AND PERMISSIONS
  // ============================================================================

  /// Initialize location service
  static Future<void> init() async {
    try {
      print('📍 Initializing LocationService...');
      
      // Load settings
      await _loadSettings();
      
      // Check and request permissions
      final hasPermission = await checkAndRequestPermission();
      
      if (hasPermission) {
        // Configure location settings
        _locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        );
        
        // Get initial location
        await getCurrentLocation();
        
        // Load camping spots and geofences
        await _loadCampingSpots();
        await _loadGeofences();
        
        print('✅ LocationService initialized');
      } else {
        print('⚠️ Location permission not granted');
      }
    } catch (e) {
      print('❌ Error initializing LocationService: $e');
    }
  }

  /// Check and request location permission
  static Future<bool> checkAndRequestPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return false;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return false;
      }

      _isLocationEnabled = true;
      print('✅ Location permission granted');
      return true;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  // ============================================================================
  // LOCATION TRACKING
  // ============================================================================

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      if (!_isLocationEnabled) {
        throw Exception('Location not enabled');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        await _updateLocationInfo(_currentPosition!);
        _logLocationHistory(_currentPosition!);
      }

      print('✅ Current location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      return _currentPosition;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Start location tracking
  static Future<void> startLocationTracking() async {
    try {
      if (!_isLocationEnabled || _isTrackingEnabled) return;

      _positionStream = Geolocator.getPositionStream(
        locationSettings: _locationSettings!,
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          print('❌ Location tracking error: $error');
          _isTrackingEnabled = false;
        },
      );

      _isTrackingEnabled = true;
      print('✅ Location tracking started');
    } catch (e) {
      print('❌ Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isTrackingEnabled = false;
      print('✅ Location tracking stopped');
    } catch (e) {
      print('❌ Error stopping location tracking: $e');
    }
  }

  /// Handle location updates
  static void _onLocationUpdate(Position position) {
    _currentPosition = position;
    _updateLocationInfo(position);
    _logLocationHistory(position);
    _checkGeofences(position);
    
    print('📍 Location updated: ${position.latitude}, ${position.longitude}');
  }

  /// Update location information (address, placemark)
  static Future<void> _updateLocationInfo(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        _currentPlacemark = placemarks.first;
        _currentAddress = _formatAddress(_currentPlacemark!);
      }
    } catch (e) {
      print('❌ Error updating location info: $e');
    }
  }

  /// Format address from placemark
  static String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street?.isNotEmpty == true) addressParts.add(placemark.street!);
    if (placemark.subLocality?.isNotEmpty == true) addressParts.add(placemark.subLocality!);
    if (placemark.locality?.isNotEmpty == true) addressParts.add(placemark.locality!);
    if (placemark.subAdministrativeArea?.isNotEmpty == true) addressParts.add(placemark.subAdministrativeArea!);
    if (placemark.administrativeArea?.isNotEmpty == true) addressParts.add(placemark.administrativeArea!);
    
    return addressParts.join(', ');
  }

  // ============================================================================
  // CAMPING SPOTS AND POINTS OF INTEREST
  // ============================================================================

  /// Find nearby camping spots
static Future<List<Map<String, dynamic>>> findNearbyCampingSpots({
  double? latitude,
  double? longitude,
  double radiusKm = 50.0,
}) async {
  final lat = latitude ?? _currentPosition?.latitude;
  final lon = longitude ?? _currentPosition?.longitude;
  if (lat == null || lon == null) {
    throw Exception('Location not available');
  }

  // … (membangun daftar _nearbyCampingSpots seperti sebelumnya) …

  // **Filter by radius** dengan null-check:
  _nearbyCampingSpots = _nearbyCampingSpots.where((spot) {
    final distance = spot['distance'] as double?;
    return distance != null && distance <= radiusKm;
  }).toList();

  // **Sort by distance**—pastikan juga cast aman:
  _nearbyCampingSpots.sort((a, b) {
    final da = a['distance'] as double? ?? double.infinity;
    final db = b['distance'] as double? ?? double.infinity;
    return da.compareTo(db);
  });

  _lastCampingSpotsUpdate = DateTime.now();
  return _nearbyCampingSpots;
}

  /// Get camping spot details
  static Map<String, dynamic>? getCampingSpotDetails(String spotId) {
    try {
      return _nearbyCampingSpots.firstWhere(
        (spot) => spot['id'] == spotId,
        orElse: () => {},
      );
    } catch (e) {
      print('❌ Error getting camping spot details: $e');
      return null;
    }
  }

/// Find nearby equipment rental shops
static Future<List<Map<String, dynamic>>> findNearbyRentalShops({
  double? latitude,
  double? longitude,
  double radiusKm = 25.0,
}) async {
  // Pastikan kita punya koordinat
  final lat = latitude ?? _currentPosition?.latitude;
  final lon = longitude ?? _currentPosition?.longitude;
  if (lat == null || lon == null) {
    throw Exception('Location not available');
  }

  // Simulasi data shop (ganti dengan fetch API kalau sudah siap)
  final List<Map<String, dynamic>> shops = [
    {
      'id': 'shop_001',
      'name': 'Adventure Gear Rental',
      'type': 'Equipment Rental',
      'latitude': -6.2088,
      'longitude': 106.8456,
      'distance': _calculateDistance(lat, lon, -6.2088, 106.8456),
      'rating': 4.7,
      'equipment': ['Tenda', 'Sleeping Bag', 'Carrier', 'Kompor'],
      'openHours': '08:00 - 20:00',
      'contact': '+62-xxx-xxxx-xxxx',
      'address': 'Jl. Outdoor No. 123, Jakarta',
    },
    {
      'id': 'shop_002',
      'name': 'Mountain Equipment Store',
      'type': 'Outdoor Store',
      'latitude': -6.1745,
      'longitude': 106.8227,
      'distance': _calculateDistance(lat, lon, -6.1745, 106.8227),
      'rating': 4.5,
      'equipment': ['Tenda', 'Jaket', 'Sepatu Gunung', 'Headlamp'],
      'openHours': '09:00 - 21:00',
      'contact': '+62-xxx-xxxx-xxxx',
      'address': 'Mall Outdoor, Jakarta',
    },
  ];

  // Filter berdasarkan radius, dengan null-safety
  final nearbyShops = shops.where((shop) {
    final distance = shop['distance'] as double?;
    return distance != null && distance <= radiusKm;
  }).toList();

  // Urutkan berdasarkan jarak
  nearbyShops.sort((a, b) {
    final da = a['distance'] as double? ?? double.infinity;
    final db = b['distance'] as double? ?? double.infinity;
    return da.compareTo(db);
  });

  return nearbyShops;
}


  // ============================================================================
  // GEOFENCING
  // ============================================================================

  /// Add geofence
  static Future<void> addGeofence({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? description,
    String? action,
  }) async {
    try {
      final geofence = {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'description': description,
        'action': action,
        'created': DateTime.now().toIso8601String(),
      };

      _geofences.add(geofence);
      await _saveGeofences();
      
      print('✅ Geofence added: $name');
    } catch (e) {
      print('❌ Error adding geofence: $e');
    }
  }

  /// Remove geofence
  static Future<void> removeGeofence(String id) async {
    try {
      _geofences.removeWhere((geofence) => geofence['id'] == id);
      _triggeredGeofences.remove(id);
      await _saveGeofences();
      
      print('✅ Geofence removed: $id');
    } catch (e) {
      print('❌ Error removing geofence: $e');
    }
  }

  /// Check geofences for current location
  static void _checkGeofences(Position position) {
    for (var geofence in _geofences) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        geofence['latitude'],
        geofence['longitude'],
      ) * 1000; // Convert to meters

      final geofenceRadius = (geofence['radius'] as num?)?.toDouble() ?? 0.0;
      final isInside = distance <= geofenceRadius;
      final wasTriggered = _triggeredGeofences.contains(geofence['id']);

      if (isInside && !wasTriggered) {
        _onGeofenceEnter(geofence);
        _triggeredGeofences.add(geofence['id']);
      } else if (!isInside && wasTriggered) {
        _onGeofenceExit(geofence);
        _triggeredGeofences.remove(geofence['id']);
      }
    }
  }

  /// Handle geofence enter
 static Future<void> _onGeofenceEnter(Map<String, dynamic> geofence) async {
  print('📍 Entered geofence: ${geofence['name']}');

  await NotificationService.createNotification(
    userId: 'current_user',
    title: 'Area Camping Terdeteksi',
    message: 'Anda berada di dekat ${geofence['name']}. Cek peralatan yang tersedia!',
    type: 'system',    // notifikasi tipe “system”
  );
}
  /// Handle geofence exit
  static void _onGeofenceExit(Map<String, dynamic> geofence) {
    print('📍 Exited geofence: ${geofence['name']}');
  }

  // ============================================================================
  // WEATHER AND ENVIRONMENT
  // ============================================================================

  /// Get weather for current location
  static Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      if (_currentPosition == null) {
        await getCurrentLocation();
      }

      if (_currentPosition == null) {
        throw Exception('Location not available');
      }

      final response = await http.get(
        Uri.parse('$_weatherApiUrl?lat=${_currentPosition!.latitude}'
                 '&lon=${_currentPosition!.longitude}&appid=$_weatherApiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temperature': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'pressure': data['main']['pressure'],
          'visibility': data['visibility'],
          'cloudiness': data['clouds']['all'],
          'sunrise': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000),
          'sunset': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000),
        };
      } else {
        print('❌ Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting weather: $e');
      return _getFallbackWeather();
    }
  }

  /// Get fallback weather data when API is unavailable
  static Map<String, dynamic> _getFallbackWeather() {
    return {
      'temperature': 25.0,
      'description': 'Data cuaca tidak tersedia',
      'humidity': 70,
      'windSpeed': 5.0,
      'pressure': 1013,
      'visibility': 10000,
      'cloudiness': 50,
      'sunrise': DateTime.now().copyWith(hour: 6, minute: 0),
      'sunset': DateTime.now().copyWith(hour: 18, minute: 0),
    };
  }

  /// Get camping weather advice
  static Map<String, dynamic> getCampingWeatherAdvice() {
    // This would use weather data to provide camping advice
    return {
      'suitable': true,
      'advice': 'Cuaca cerah, cocok untuk camping',
      'warnings': [],
      'recommendations': [
        'Bawa topi dan sunscreen',
        'Pastikan cukup air minum',
        'Siapkan jaket untuk malam hari',
      ],
    };
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Calculate distance between two points in kilometers
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Log location to history
  static void _logLocationHistory(Position position) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
    };

    _locationHistory.add(entry);

    // Keep only recent entries
    if (_locationHistory.length > _maxHistoryEntries) {
      _locationHistory.removeAt(0);
    }
  }

  // ============================================================================
  // DATA PERSISTENCE
  // ============================================================================

  /// Load settings from Hive
  static Future<void> _loadSettings() async {
    try {
      // Load any location-related settings
      print('✅ Location settings loaded');
    } catch (e) {
      print('❌ Error loading location settings: $e');
    }
  }

  /// Load camping spots from cache
  static Future<void> _loadCampingSpots() async {
    try {
      final cachedSpots = await HiveService.getSetting<List<dynamic>>('cached_camping_spots');
      if (cachedSpots != null) {
        _nearbyCampingSpots = cachedSpots.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ Error loading cached camping spots: $e');
    }
  }

  /// Load geofences from Hive
  static Future<void> _loadGeofences() async {
    try {
      final geofences = await HiveService.getSetting<List<dynamic>>('geofences');
      if (geofences != null) {
        _geofences = geofences.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ Error loading geofences: $e');
    }
  }

  /// Save geofences to Hive
  static Future<void> _saveGeofences() async {
    try {
      await HiveService.saveSetting('geofences', _geofences);
    } catch (e) {
      print('❌ Error saving geofences: $e');
    }
  }

  // ============================================================================
  // PUBLIC GETTERS
  // ============================================================================

  /// Get current position
  static Position? get currentPosition => _currentPosition;

  /// Get current address
  static String? get currentAddress => _currentAddress;

  /// Get current placemark
  static Placemark? get currentPlacemark => _currentPlacemark;

  /// Get location tracking status
  static bool get isTrackingEnabled => _isTrackingEnabled;

  /// Get location permission status
  static bool get isLocationEnabled => _isLocationEnabled;

  /// Get location history
  static List<Map<String, dynamic>> get locationHistory => List.from(_locationHistory);

  /// Get active geofences
  static List<Map<String, dynamic>> get geofences => List.from(_geofences);

  // ============================================================================
  // DEBUG AND STATUS
  // ============================================================================

  /// Get location service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isLocationEnabled': _isLocationEnabled,
      'isTrackingEnabled': _isTrackingEnabled,
      'currentPosition': _currentPosition != null ? {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
      } : null,
      'currentAddress': _currentAddress,
      'nearbyCampingSpotsCount': _nearbyCampingSpots.length,
      'geofencesCount': _geofences.length,
      'locationHistoryCount': _locationHistory.length,
    };
  }

  /// Debug print location information
  static Future<void> printLocationDebug() async {
    try {
      print('🔍 === LOCATION SERVICE DEBUG ===');
      
      final status = getServiceStatus();
      print('🔍 Status: $status');
      
      if (_currentPosition != null) {
        print('🔍 Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        print('🔍 Current address: $_currentAddress');
      }
      
      print('🔍 Nearby camping spots: ${_nearbyCampingSpots.length}');
      for (var spot in _nearbyCampingSpots.take(3)) {
        print('  - ${spot['name']} (${spot['distance'].toStringAsFixed(2)} km)');
      }
      
      print('🔍 Active geofences: ${_geofences.length}');
      print('🔍 Triggered geofences: ${_triggeredGeofences.length}');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in location debug: $e');
    }
  }

  /// Dispose location service
  static Future<void> dispose() async {
    try {
      await stopLocationTracking();
      print('✅ LocationService disposed');
    } catch (e) {
      print('❌ Error disposing LocationService: $e');
    }
  }
}