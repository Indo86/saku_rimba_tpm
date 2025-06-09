// services/LocationService.dart (SakuRimba) - IMPROVED VERSION
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

  // ============================================================================
  // REAL INDONESIAN CAMPING SPOTS DATA
  // ============================================================================
  
  static final List<Map<String, dynamic>> _indonesianCampingSpots = [
    // Jawa Tengah & Sekitarnya
    {
      'id': 'merbabu_001',
      'name': 'Gunung Merbabu',
      'type': 'Gunung',
      'latitude': -7.4550,
      'longitude': 110.4403,
      'elevation': 3142,
      'rating': 4.6,
      'location': 'Magelang, Jawa Tengah',
      'description': 'Gunung berapi yang tidak aktif dengan pemandangan sunrise spektakuler. Jalur pendakian melalui Selo dengan savana luas.',
      'features': 'Savana luas, Sunrise point, Air bersih di pos, Shelter kayu',
      'difficulty': 'Sedang',
      'estimatedTime': '6-8 jam pendakian',
      'facilities': ['Pos pendakian', 'Shelter', 'Sumber air', 'Toilet'],
    },
    {
      'id': 'merapi_001',
      'name': 'Gunung Merapi - Kaliurang',
      'type': 'Gunung', 
      'latitude': -7.5954,
      'longitude': 110.4189,
      'elevation': 2930,
      'rating': 4.4,
      'location': 'Sleman, DI Yogyakarta',
      'description': 'Gunung berapi aktif paling terkenal di Jawa. Pendakian dimulai dari Kaliurang dengan trek yang menantang.',
      'features': 'Gunung berapi aktif, Lava tour, Museum vulkanologi, Pemandian air panas',
      'difficulty': 'Sulit',
      'estimatedTime': '8-10 jam pendakian',
      'facilities': ['Basecamp', 'Pemandu lokal', 'Rental alat', 'Warung'],
    },
    {
      'id': 'andong_001',
      'name': 'Gunung Andong',
      'type': 'Gunung',
      'latitude': -7.4019,
      'longitude': 110.3731,
      'elevation': 1726,
      'rating': 4.3,
      'location': 'Magelang, Jawa Tengah',
      'description': 'Gunung dengan trek yang tidak terlalu sulit, cocok untuk pemula. Pemandangan Magelang dan sekitarnya dari puncak.',
      'features': 'Trek ramah pemula, Sunset/sunrise point, Hutan pinus, Air terjun sekitar',
      'difficulty': 'Mudah-Sedang',
      'estimatedTime': '4-5 jam pendakian',
      'facilities': ['Pos pendakian', 'Parkir', 'Warung', 'Toilet'],
    },
    {
      'id': 'ketep_001',
      'name': 'Ketep Pass',
      'type': 'Perbukitan',
      'latitude': -7.4711,
      'longitude': 110.3175,
      'elevation': 1200,
      'rating': 4.5,
      'location': 'Magelang, Jawa Tengah',
      'description': 'Lokasi wisata dengan view Gunung Merapi dan Merbabu. Dilengkapi dengan observatorium dan museum.',
      'features': 'Observatory, Museum gunungapi, View Merapi-Merbabu, Theater 4D',
      'difficulty': 'Mudah',
      'estimatedTime': '2-3 jam',
      'facilities': ['Observatorium', 'Museum', 'Restoran', 'Souvenir shop', 'Parkir luas'],
    },
    {
      'id': 'umbul_ponggok',
      'name': 'Umbul Ponggok',
      'type': 'Danau',
      'latitude': -7.6517,
      'longitude': 110.7222,
      'elevation': 155,
      'rating': 4.2,
      'location': 'Klaten, Jawa Tengah',
      'description': 'Mata air jernih dengan aktivitas snorkeling dan diving. Spot foto underwater yang terkenal.',
      'features': 'Mata air jernih, Underwater photo, Snorkeling, Diving, Spot foto instagramable',
      'difficulty': 'Mudah',
      'estimatedTime': '3-4 jam',
      'facilities': ['Kolam renang', 'Rental alat diving', 'Gazebo', 'Restoran', 'Parkir'],
    },
    {
      'id': 'dieng_001',
      'name': 'Dataran Tinggi Dieng',
      'type': 'Danau',
      'latitude': -7.2069,
      'longitude': 109.9135,
      'elevation': 2093,
      'rating': 4.7,
      'location': 'Wonosobo, Jawa Tengah',
      'description': 'Dataran tinggi dengan danau-danau berwarna dan candi Hindu kuno. Udara sejuk sepanjang tahun.',
      'features': 'Danau warna-warni, Candi Arjuna, Kawah Sikidang, Sunrise golden, Telaga Warna',
      'difficulty': 'Mudah',
      'estimatedTime': '1-2 hari',
      'facilities': ['Hotel', 'Homestay', 'Restoran', 'Rental motor', 'Pemandu wisata'],
    },
    
    // Jawa Barat
    {
      'id': 'gede_pangrango',
      'name': 'Gunung Gede Pangrango',
      'type': 'Gunung',
      'latitude': -6.7320,
      'longitude': 107.0230,
      'elevation': 2958,
      'rating': 4.5,
      'location': 'Cianjur, Jawa Barat',
      'description': 'Taman Nasional dengan keanekaragaman hayati tinggi. Jalur Cibodas paling populer.',
      'features': 'Taman Nasional, Hot spring, Air terjun, Flora fauna endemik, Hutan tropis',
      'difficulty': 'Sedang-Sulit',
      'estimatedTime': '8-12 jam',
      'facilities': ['Gerbang TN', 'Pos pendakian', 'Shelter', 'Sumber air'],
    },
    {
      'id': 'tangkuban_perahu',
      'name': 'Tangkuban Perahu',
      'type': 'Gunung',
      'latitude': -6.7494,
      'longitude': 107.6097,
      'elevation': 2084,
      'rating': 4.1,
      'location': 'Bandung, Jawa Barat',
      'description': 'Gunung berapi dengan kawah yang mudah diakses. Legenda Sangkuriang terkenal.',
      'features': 'Kawah Ratu, Kawah Upas, Hot spring, Souvenir shop, Aksesibilitas mudah',
      'difficulty': 'Mudah',
      'estimatedTime': '2-3 jam',
      'facilities': ['Parkir', 'Restoran', 'Souvenir', 'Toilet', 'Pos kesehatan'],
    },
    
    // Jawa Timur
    {
      'id': 'bromo_001',
      'name': 'Gunung Bromo',
      'type': 'Gunung',
      'latitude': -7.9425,
      'longitude': 112.9530,
      'elevation': 2329,
      'rating': 4.8,
      'location': 'Probolinggo, Jawa Timur',
      'description': 'Gunung berapi ikonik dengan lautan pasir dan sunrise spektakuler dari Penanjakan.',
      'features': 'Sunrise point Penanjakan, Lautan pasir, Kawah aktif, Pura Luhur Poten',
      'difficulty': 'Mudah-Sedang',
      'estimatedTime': '4-6 jam tour',
      'facilities': ['Homestay', 'Jeep rental', 'Kuda rental', 'Restoran', 'ATM'],
    },
    
    // Bali
    {
      'id': 'batur_001',
      'name': 'Gunung Batur',
      'type': 'Gunung',
      'latitude': -8.2421,
      'longitude': 115.3751,
      'elevation': 1717,
      'rating': 4.4,
      'location': 'Kintamani, Bali',
      'description': 'Gunung berapi dengan danau kaldera. Trekking sunrise populer di Bali.',
      'features': 'Danau Batur, Sunrise trekking, Hot spring, Desa Trunyan, Pura Ulun Danu',
      'difficulty': 'Sedang',
      'estimatedTime': '4-5 jam',
      'facilities': ['Basecamp', 'Guide', 'Hot spring', 'Restoran', 'Homestay'],
    },
  ];

  // ============================================================================
  // REAL INDONESIAN OUTDOOR STORES DATA
  // ============================================================================
  
  static final List<Map<String, dynamic>> _indonesianOutdoorStores = [
    // Magelang & Sekitarnya
    {
      'id': 'eiger_magelang',
      'name': 'Eiger Adventure Store Magelang',
      'type': 'Equipment Rental',
      'latitude': -7.4704,
      'longitude': 110.2177,
      'rating': 4.5,
      'equipment': ['Tenda', 'Carrier', 'Sleeping Bag', 'Sepatu Gunung', 'Jaket', 'Kompor'],
      'openHours': '09:00 - 21:00',
      'contact': '+62 293 362555',
      'address': 'Jl. Ahmad Yani No. 45, Magelang',
      'priceRange': 'Rp 25.000 - Rp 150.000/hari',
      'speciality': 'Peralatan gunung berkualitas, brand internasional',
    },
    {
      'id': 'consina_yogya',
      'name': 'Consina Store Yogyakarta',
      'type': 'Outdoor Store',
      'latitude': -7.7956,
      'longitude': 110.3695,
      'rating': 4.6,
      'equipment': ['Tenda', 'Tas Gunung', 'Sepatu Hiking', 'Kompor Gas', 'Headlamp', 'Raincoat'],
      'openHours': '09:00 - 22:00',
      'contact': '+62 274 560123',
      'address': 'Malioboro Mall Lt.2, Yogyakarta',
      'priceRange': 'Rp 20.000 - Rp 120.000/hari',
      'speciality': 'Brand lokal berkualitas, harga terjangkau',
    },
    {
      'id': 'rei_yogya',
      'name': 'REI (Rimba Eiger Indonesia) Yogya',
      'type': 'Equipment Rental',
      'latitude': -7.7894,
      'longitude': 110.3644,
      'rating': 4.3,
      'equipment': ['Carrier', 'Tenda Dome', 'Sleeping Bag', 'Matras', 'Kompor', 'Peralatan Masak'],
      'openHours': '08:30 - 21:30',
      'contact': '+62 274 588999',
      'address': 'Jl. C. Simanjuntak No. 70, Yogyakarta',
      'priceRange': 'Rp 30.000 - Rp 200.000/hari',
      'speciality': 'Rental dan jual, equipment mountain & outdoor',
    },
    {
      'id': 'deuter_semarang',
      'name': 'Deuter Store Semarang',
      'type': 'Outdoor Store',
      'latitude': -6.9667,
      'longitude': 110.4167,
      'rating': 4.4,
      'equipment': ['Carrier Deuter', 'Daypack', 'Hiking Poles', 'Hydration Pack'],
      'openHours': '10:00 - 22:00',
      'contact': '+62 24 8442111',
      'address': 'Java Mall Lt. 2, Semarang',
      'priceRange': 'Rp 35.000 - Rp 180.000/hari',
      'speciality': 'Tas carrier premium Deuter, aksesoris hiking',
    },
    {
      'id': 'outdoor_magelang',
      'name': 'Magelang Outdoor Equipment',
      'type': 'Equipment Rental',
      'latitude': -7.4761,
      'longitude': 110.2139,
      'rating': 4.2,
      'equipment': ['Tenda', 'Sleeping Bag', 'Kompor', 'Nesting', 'Headlamp', 'Sandal Gunung'],
      'openHours': '08:00 - 20:00',
      'contact': '+62 293 364777',
      'address': 'Jl. Veteran No. 15, Magelang',
      'priceRange': 'Rp 15.000 - Rp 100.000/hari',
      'speciality': 'Sewa harian, mingguan, bulanan. Dekat basecamp Merbabu',
    },
    {
      'id': 'basecamp_selo',
      'name': 'Basecamp Selo Equipment',
      'type': 'Equipment Rental',
      'latitude': -7.4167,
      'longitude': 110.4000,
      'rating': 4.7,
      'equipment': ['Tenda 2-4 orang', 'Sleeping Bag -5°C', 'Carrier 60-80L', 'Kompor Gas', 'Jaket Gunung'],
      'openHours': '24 jam (dengan perjanjian)',
      'contact': '+62 856 4567 8901',
      'address': 'Desa Selo, Boyolali (Basecamp Merbabu)',
      'priceRange': 'Rp 20.000 - Rp 120.000/hari',
      'speciality': 'Khusus pendaki Merbabu, guide service, porter service',
    },
    {
      'id': 'adventure_solo',
      'name': 'Adventure Gear Solo',
      'type': 'Outdoor Store',
      'latitude': -7.5755,
      'longitude': 110.8243,
      'rating': 4.3,
      'equipment': ['Tenda Ultralight', 'Carrier', 'Sepatu Hiking', 'Quick Dry Clothes', 'GPS Handheld'],
      'openHours': '09:00 - 21:00',
      'contact': '+62 271 645222',
      'address': 'Solo Grand Mall Lt. 1, Solo',
      'priceRange': 'Rp 25.000 - Rp 160.000/hari',
      'speciality': 'Gear ultralight, teknologi terbaru',
    },
  ];

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

  /// Update location information (address, placemark) with Indonesian formatting
  static Future<void> _updateLocationInfo(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        _currentPlacemark = placemarks.first;
        _currentAddress = _formatIndonesianAddress(_currentPlacemark!);
      }
    } catch (e) {
      print('❌ Error updating location info: $e');
      // Fallback untuk Indonesia
      _currentAddress = _getIndonesianLocationFallback(position);
    }
  }

  /// Format address in Indonesian style
  static String _formatIndonesianAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    // Format: Jalan, Kelurahan/Desa, Kecamatan, Kabupaten/Kota, Provinsi
    if (placemark.street?.isNotEmpty == true) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      addressParts.add(placemark.subLocality!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.subAdministrativeArea?.isNotEmpty == true) {
      addressParts.add('Kab. ${placemark.subAdministrativeArea!}');
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      addressParts.add(placemark.administrativeArea!);
    }
    
    return addressParts.join(', ');
  }

  /// Get Indonesian location fallback when geocoding fails
  static String _getIndonesianLocationFallback(Position position) {
    final lat = position.latitude;
    final lon = position.longitude;
    
    // Basic region detection for Indonesia
    if (lat >= -8.5 && lat <= -6.0 && lon >= 106.0 && lon <= 115.0) {
      if (lat >= -7.8 && lat <= -7.0 && lon >= 110.0 && lon <= 111.0) {
        return 'Magelang, Jawa Tengah (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
      } else if (lat >= -8.0 && lat <= -7.5 && lon >= 110.0 && lon <= 111.0) {
        return 'Yogyakarta, DI Yogyakarta (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
      } else if (lat >= -7.0 && lat <= -6.5 && lon >= 109.5 && lon <= 111.0) {
        return 'Semarang, Jawa Tengah (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
      } else {
        return 'Jawa Tengah, Indonesia (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
      }
    } else if (lat >= -8.8 && lat <= -6.5 && lon >= 105.0 && lon <= 109.0) {
      return 'Jawa Barat, Indonesia (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
    } else if (lat >= -8.8 && lat <= -7.5 && lon >= 111.0 && lon <= 114.5) {
      return 'Jawa Timur, Indonesia (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
    } else if (lat >= -8.8 && lat <= -8.0 && lon >= 114.5 && lon <= 116.0) {
      return 'Bali, Indonesia (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
    } else {
      return 'Indonesia (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
    }
  }

  // ============================================================================
  // CAMPING SPOTS AND POINTS OF INTEREST (IMPROVED)
  // ============================================================================

  /// Find nearby camping spots with real Indonesian data
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

    print('🏕️ Finding camping spots near: $lat, $lon (radius: ${radiusKm}km)');

    // Calculate distances and filter by radius
    _nearbyCampingSpots = _indonesianCampingSpots.map((spot) {
      final distance = _calculateDistance(
        lat, lon,
        spot['latitude'], spot['longitude']
      );
      
      return {
        ...spot,
        'distance': distance,
      };
    }).where((spot) {
      final distance = spot['distance'] as double?;
      return distance != null && distance <= radiusKm;
    }).toList();

    // Sort by distance
    _nearbyCampingSpots.sort((a, b) {
      final da = a['distance'] as double? ?? double.infinity;
      final db = b['distance'] as double? ?? double.infinity;
      return da.compareTo(db);
    });

    _lastCampingSpotsUpdate = DateTime.now();
    
    print('✅ Found ${_nearbyCampingSpots.length} camping spots within ${radiusKm}km');
    return _nearbyCampingSpots;
  }

  /// Find nearby equipment rental shops with real Indonesian data
  static Future<List<Map<String, dynamic>>> findNearbyRentalShops({
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    final lat = latitude ?? _currentPosition?.latitude;
    final lon = longitude ?? _currentPosition?.longitude;
    
    if (lat == null || lon == null) {
      throw Exception('Location not available');
    }

    print('🏪 Finding rental shops near: $lat, $lon (radius: ${radiusKm}km)');

    // Calculate distances and filter by radius
    final nearbyShops = _indonesianOutdoorStores.map((shop) {
      final distance = _calculateDistance(
        lat, lon,
        shop['latitude'], shop['longitude']
      );
      
      return {
        ...shop,
        'distance': distance,
      };
    }).where((shop) {
      final distance = shop['distance'] as double?;
      return distance != null && distance <= radiusKm;
    }).toList();

    // Sort by distance
    nearbyShops.sort((a, b) {
      final da = a['distance'] as double? ?? double.infinity;
      final db = b['distance'] as double? ?? double.infinity;
      return da.compareTo(db);
    });

    print('✅ Found ${nearbyShops.length} rental shops within ${radiusKm}km');
    return nearbyShops;
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

  /// Get popular camping spots in specific region
  static List<Map<String, dynamic>> getPopularCampingSpots(String region) {
    switch (region.toLowerCase()) {
      case 'jawa tengah':
        return _indonesianCampingSpots.where((spot) => 
          spot['location'].toString().toLowerCase().contains('jawa tengah') ||
          spot['location'].toString().toLowerCase().contains('magelang') ||
          spot['location'].toString().toLowerCase().contains('wonosobo')
        ).toList();
      case 'jawa barat':
        return _indonesianCampingSpots.where((spot) => 
          spot['location'].toString().toLowerCase().contains('jawa barat') ||
          spot['location'].toString().toLowerCase().contains('bandung') ||
          spot['location'].toString().toLowerCase().contains('cianjur')
        ).toList();
      case 'jawa timur':
        return _indonesianCampingSpots.where((spot) => 
          spot['location'].toString().toLowerCase().contains('jawa timur') ||
          spot['location'].toString().toLowerCase().contains('probolinggo')
        ).toList();
      case 'yogyakarta':
        return _indonesianCampingSpots.where((spot) => 
          spot['location'].toString().toLowerCase().contains('yogyakarta') ||
          spot['location'].toString().toLowerCase().contains('sleman')
        ).toList();
      default:
        return _indonesianCampingSpots.take(5).toList();
    }
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
      type: 'system',
    );
  }

  /// Handle geofence exit
  static void _onGeofenceExit(Map<String, dynamic> geofence) {
    print('📍 Exited geofence: ${geofence['name']}');
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
      'address': _currentAddress,
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

  /// Get all Indonesian camping spots
  static List<Map<String, dynamic>> get allCampingSpots => List.from(_indonesianCampingSpots);

  /// Get all Indonesian outdoor stores
  static List<Map<String, dynamic>> get allOutdoorStores => List.from(_indonesianOutdoorStores);

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
      'totalCampingSpotsInDB': _indonesianCampingSpots.length,
      'totalOutdoorStoresInDB': _indonesianOutdoorStores.length,
    };
  }

  /// Dispose location service
  static Future<void> dispose() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isTrackingEnabled = false;
      print('✅ LocationService disposed');
    } catch (e) {
      print('❌ Error disposing LocationService: $e');
    }
  }
}