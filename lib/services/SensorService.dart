// services/SensorService.dart (SakuRimba)
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/HiveService.dart';
import '../services/NotificationService.dart';

class SensorService {
  // Sensor data streams
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  static StreamSubscription<BarometerEvent>? _barometerSubscription;

  // Current sensor data
  static AccelerometerEvent? _currentAccelerometerData;
  static GyroscopeEvent? _currentGyroscopeData;
  static MagnetometerEvent? _currentMagnetometerData;
  static BarometerEvent? _currentBarometerData;

  // Sensor status
  static bool _isAccelerometerActive = false;
  static bool _isGyroscopeActive = false;
  static bool _isMagnetometerActive = false;
  static bool _isBarometerActive = false;

  // Sensor settings
  static Duration _sensorUpdateInterval = Duration(milliseconds: 100);
  static bool _enableMotionDetection = true;
  static bool _enableAltitudeEstimation = true;
  static bool _enableCompass = true;

  // Motion detection thresholds
  static double _shakeThreshold = 15.0;
  static double _tiltThreshold = 45.0;
  static DateTime? _lastShakeTime;
  static DateTime? _lastTiltTime;

  // Altitude estimation
  static double _seaLevelPressure = 1013.25; // hPa
  static double? _currentAltitude;

  // Compass
  static double? _currentBearing;
  static String? _currentDirection;

  // Data logging
  static List<Map<String, dynamic>> _sensorLog = [];
  static int _maxLogEntries = 1000;

  // ============================================================================
  // INITIALIZATION AND LIFECYCLE
  // ============================================================================

  /// Initialize sensor service
  static Future<void> init() async {
    try {
      print('📱 Initializing SensorService...');
      
      // Load settings from Hive
      await _loadSettings();
      
      // Start default sensors
      await startAccelerometer();
      await startMagnetometer();
      
      // Try to start barometer if available
      try {
        await startBarometer();
      } catch (e) {
        print('⚠️ Barometer not available: $e');
      }
      
      print('✅ SensorService initialized');
    } catch (e) {
      print('❌ Error initializing SensorService: $e');
    }
  }

  /// Dispose all sensor subscriptions
  static Future<void> dispose() async {
    try {
      await stopAllSensors();
      print('✅ SensorService disposed');
    } catch (e) {
      print('❌ Error disposing SensorService: $e');
    }
  }

  // ============================================================================
  // ACCELEROMETER
  // ============================================================================

  /// Start accelerometer monitoring
  static Future<void> startAccelerometer() async {
    try {
      if (_isAccelerometerActive) return;

      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: _sensorUpdateInterval,
      ).listen(
        _onAccelerometerData,
        onError: (error) {
          print('❌ Accelerometer error: $error');
          _isAccelerometerActive = false;
        },
        cancelOnError: false,
      );

      _isAccelerometerActive = true;
      print('✅ Accelerometer started');
    } catch (e) {
      print('❌ Error starting accelerometer: $e');
    }
  }

  /// Stop accelerometer monitoring
  static Future<void> stopAccelerometer() async {
    try {
      await _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _isAccelerometerActive = false;
      print('✅ Accelerometer stopped');
    } catch (e) {
      print('❌ Error stopping accelerometer: $e');
    }
  }

  /// Handle accelerometer data
  static void _onAccelerometerData(AccelerometerEvent event) {
    _currentAccelerometerData = event;
    
    if (_enableMotionDetection) {
      _detectMotion(event);
    }
    
    _logSensorData('accelerometer', {
      'x': event.x,
      'y': event.y,
      'z': event.z,
      'magnitude': _calculateMagnitude(event.x, event.y, event.z),
    });
  }

  /// Detect motion patterns (shake, tilt)
  static void _detectMotion(AccelerometerEvent event) {
    final magnitude = _calculateMagnitude(event.x, event.y, event.z);
    
    // Shake detection
    if (magnitude > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null || 
          now.difference(_lastShakeTime!).inMilliseconds > 1000) {
        _lastShakeTime = now;
        _onShakeDetected(magnitude);
      }
    }
    
    // Tilt detection
    final tiltAngle = _calculateTiltAngle(event.x, event.y, event.z);
    if (tiltAngle > _tiltThreshold) {
      final now = DateTime.now();
      if (_lastTiltTime == null || 
          now.difference(_lastTiltTime!).inMilliseconds > 2000) {
        _lastTiltTime = now;
        _onTiltDetected(tiltAngle);
      }
    }
  }

  /// Calculate magnitude of acceleration vector
  static double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  /// Calculate tilt angle in degrees
  static double _calculateTiltAngle(double x, double y, double z) {
    final magnitude = _calculateMagnitude(x, y, z);
    if (magnitude == 0) return 0;
    
    final tiltRadians = acos(z.abs() / magnitude);
    return tiltRadians * 180 / pi;
  }

  /// Handle shake detection
  static void _onShakeDetected(double intensity) {
    print('🤳 Shake detected with intensity: $intensity');
    
    // Trigger camping equipment recommendation based on shake
    _triggerMotionBasedRecommendation('shake', intensity);
  }

  /// Handle tilt detection
  static void _onTiltDetected(double angle) {
    print('📐 Tilt detected with angle: $angle°');
    
    // Trigger camping safety notification
    _triggerMotionBasedRecommendation('tilt', angle);
  }

  // ============================================================================
  // GYROSCOPE
  // ============================================================================

  /// Start gyroscope monitoring
  static Future<void> startGyroscope() async {
    try {
      if (_isGyroscopeActive) return;

      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: _sensorUpdateInterval,
      ).listen(
        _onGyroscopeData,
        onError: (error) {
          print('❌ Gyroscope error: $error');
          _isGyroscopeActive = false;
        },
        cancelOnError: false,
      );

      _isGyroscopeActive = true;
      print('✅ Gyroscope started');
    } catch (e) {
      print('❌ Error starting gyroscope: $e');
    }
  }

  /// Stop gyroscope monitoring
  static Future<void> stopGyroscope() async {
    try {
      await _gyroscopeSubscription?.cancel();
      _gyroscopeSubscription = null;
      _isGyroscopeActive = false;
      print('✅ Gyroscope stopped');
    } catch (e) {
      print('❌ Error stopping gyroscope: $e');
    }
  }

  /// Handle gyroscope data
  static void _onGyroscopeData(GyroscopeEvent event) {
    _currentGyroscopeData = event;
    
    _logSensorData('gyroscope', {
      'x': event.x,
      'y': event.y,
      'z': event.z,
      'angularVelocity': _calculateMagnitude(event.x, event.y, event.z),
    });
  }

  // ============================================================================
  // MAGNETOMETER / COMPASS
  // ============================================================================

  /// Start magnetometer monitoring
  static Future<void> startMagnetometer() async {
    try {
      if (_isMagnetometerActive) return;

      _magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: _sensorUpdateInterval,
      ).listen(
        _onMagnetometerData,
        onError: (error) {
          print('❌ Magnetometer error: $error');
          _isMagnetometerActive = false;
        },
        cancelOnError: false,
      );

      _isMagnetometerActive = true;
      print('✅ Magnetometer started');
    } catch (e) {
      print('❌ Error starting magnetometer: $e');
    }
  }

  /// Stop magnetometer monitoring
  static Future<void> stopMagnetometer() async {
    try {
      await _magnetometerSubscription?.cancel();
      _magnetometerSubscription = null;
      _isMagnetometerActive = false;
      print('✅ Magnetometer stopped');
    } catch (e) {
      print('❌ Error stopping magnetometer: $e');
    }
  }

  /// Handle magnetometer data
  static void _onMagnetometerData(MagnetometerEvent event) {
    _currentMagnetometerData = event;
    
    if (_enableCompass) {
      _updateCompass(event);
    }
    
    _logSensorData('magnetometer', {
      'x': event.x,
      'y': event.y,
      'z': event.z,
      'magnitude': _calculateMagnitude(event.x, event.y, event.z),
    });
  }

  /// Update compass bearing and direction
  static void _updateCompass(MagnetometerEvent event) {
    // Calculate bearing (0-360 degrees)
    _currentBearing = atan2(event.y, event.x) * 180 / pi;
    if (_currentBearing! < 0) {
      _currentBearing = _currentBearing! + 360;
    }
    
    // Determine cardinal direction
    _currentDirection = _getCardinalDirection(_currentBearing!);
  }

  /// Get cardinal direction from bearing
  static String _getCardinalDirection(double bearing) {
    const directions = [
      'Utara', 'Timur Laut', 'Timur', 'Tenggara',
      'Selatan', 'Barat Daya', 'Barat', 'Barat Laut'
    ];
    
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  // ============================================================================
  // BAROMETER / ALTITUDE
  // ============================================================================

  /// Start barometer monitoring (if available)
  static Future<void> startBarometer() async {
    try {
      if (_isBarometerActive) return;

      // Note: sensors_plus doesn't have barometer, 
      // this is a placeholder for when it's available
      // You might need to use a specific barometer plugin
      
      _isBarometerActive = true;
      print('✅ Barometer started (simulated)');
      
      // Simulate barometer data for demo
      Timer.periodic(_sensorUpdateInterval, (timer) {
        if (!_isBarometerActive) {
          timer.cancel();
          return;
        }
        
        // Simulate pressure reading (around sea level)
        final pressure = _seaLevelPressure + (Random().nextDouble() - 0.5) * 10;
        _onBarometerData(pressure);
      });
      
    } catch (e) {
      print('❌ Error starting barometer: $e');
    }
  }

  /// Stop barometer monitoring
  static Future<void> stopBarometer() async {
    try {
      await _barometerSubscription?.cancel();
      _barometerSubscription = null;
      _isBarometerActive = false;
      print('✅ Barometer stopped');
    } catch (e) {
      print('❌ Error stopping barometer: $e');
    }
  }

  /// Handle barometer data (simulated)
  static void _onBarometerData(double pressure) {
    // _currentBarometerData = BarometerEvent(pressure);
    
    if (_enableAltitudeEstimation) {
      _updateAltitude(pressure);
    }
    
    _logSensorData('barometer', {
      'pressure': pressure,
      'altitude': _currentAltitude,
    });
  }

  /// Update altitude estimation based on pressure
  static void _updateAltitude(double pressure) {
    // Barometric formula for altitude estimation
    _currentAltitude = 44330 * (1 - pow(pressure / _seaLevelPressure, 1/5.255));
  }

  // ============================================================================
  // CAMPING-SPECIFIC FEATURES
  // ============================================================================

  /// Trigger motion-based equipment recommendations
  static void _triggerMotionBasedRecommendation(String motionType, double intensity) {
    switch (motionType) {
      case 'shake':
        if (intensity > 20) {
          NotificationService.createSystemNotification(
            userId: 'current_user', // Should get from UserService
            title: 'Gerakan Terdeteksi!',
            message: 'Apakah Anda sedang berkemah? Coba lihat rekomendasi peralatan terbaru kami!',
          );
        }
        break;
      
      case 'tilt':
        if (intensity > 60) {
          NotificationService.createSystemNotification(
            userId: 'current_user',
            title: 'Kemiringan Terdeteksi',
            message: 'Pastikan peralatan camping Anda aman dan seimbang!',
          );
        }
        break;
    }
  }

  /// Get camping weather conditions based on sensors
  static Map<String, dynamic> getCampingConditions() {
    Map<String, dynamic> conditions = {};
    
    // Motion analysis
    if (_currentAccelerometerData != null) {
      final motion = _calculateMagnitude(
        _currentAccelerometerData!.x,
        _currentAccelerometerData!.y,
        _currentAccelerometerData!.z,
      );
      
      conditions['motionLevel'] = motion > 12 ? 'High' : motion > 8 ? 'Medium' : 'Low';
      conditions['recommendation'] = motion > 15 
          ? 'Kondisi berangin, gunakan tenda yang kuat'
          : 'Kondisi relatif tenang untuk camping';
    }
    
    // Compass direction for camp setup
    if (_currentDirection != null) {
      conditions['direction'] = _currentDirection;
      conditions['compassAdvice'] = _getCompassAdvice(_currentBearing!);
    }
    
    // Altitude information
    if (_currentAltitude != null) {
      conditions['altitude'] = _currentAltitude!.round();
      conditions['altitudeAdvice'] = _getAltitudeAdvice(_currentAltitude!);
    }
    
    return conditions;
  }

  /// Get compass advice for camping
  static String _getCompassAdvice(double bearing) {
    if (bearing >= 315 || bearing < 45) {
      return 'Menghadap utara - bagus untuk menghindari angin selatan';
    } else if (bearing >= 45 && bearing < 135) {
      return 'Menghadap timur - mendapat sinar matahari pagi';
    } else if (bearing >= 135 && bearing < 225) {
      return 'Menghadap selatan - terlindung dari angin utara';
    } else {
      return 'Menghadap barat - hindari sinar matahari sore yang panas';
    }
  }

  /// Get altitude advice for camping
  static String _getAltitudeAdvice(double altitude) {
    if (altitude < 500) {
      return 'Dataran rendah - suhu hangat, bawa peralatan anti nyamuk';
    } else if (altitude < 1500) {
      return 'Dataran menengah - suhu sejuk, ideal untuk camping';
    } else if (altitude < 2500) {
      return 'Dataran tinggi - suhu dingin, bawa jaket dan sleeping bag hangat';
    } else {
      return 'Pegunungan tinggi - suhu sangat dingin, butuh peralatan khusus';
    }
  }

  // ============================================================================
  // DATA LOGGING AND ANALYSIS
  // ============================================================================

  /// Log sensor data
  static void _logSensorData(String sensorType, Map<String, dynamic> data) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'sensorType': sensorType,
      'data': data,
    };
    
    _sensorLog.add(entry);
    
    // Keep only latest entries
    if (_sensorLog.length > _maxLogEntries) {
      _sensorLog.removeAt(0);
    }
  }

  /// Get sensor data history
  static List<Map<String, dynamic>> getSensorHistory({
    String? sensorType,
    int? lastMinutes,
  }) {
    var filtered = _sensorLog;
    
    if (sensorType != null) {
      filtered = filtered.where((entry) => entry['sensorType'] == sensorType).toList();
    }
    
    if (lastMinutes != null) {
      final cutoff = DateTime.now().subtract(Duration(minutes: lastMinutes));
      filtered = filtered.where((entry) {
        final timestamp = DateTime.parse(entry['timestamp']);
        return timestamp.isAfter(cutoff);
      }).toList();
    }
    
    return filtered;
  }

  /// Analyze motion patterns
  static Map<String, dynamic> analyzeMotionPatterns() {
    final accelerometerData = getSensorHistory(
      sensorType: 'accelerometer',
      lastMinutes: 10,
    );
    
    if (accelerometerData.isEmpty) {
      return {'status': 'No data available'};
    }
    
    final magnitudes = accelerometerData.map((entry) {
      final data = entry['data'] as Map<String, dynamic>;
      return data['magnitude'] as double;
    }).toList();
    
    final average = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final max = magnitudes.reduce((a, b) => a > b ? a : b);
    final min = magnitudes.reduce((a, b) => a < b ? a : b);
    
    return {
      'averageMotion': average,
      'maxMotion': max,
      'minMotion': min,
      'variance': _calculateVariance(magnitudes, average),
      'activityLevel': average > 12 ? 'High' : average > 8 ? 'Medium' : 'Low',
    };
  }

  static double _calculateVariance(List<double> values, double mean) {
    final squaredDiffs = values.map((value) => pow(value - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  // ============================================================================
  // SETTINGS AND CONFIGURATION
  // ============================================================================

  /// Load settings from Hive
  static Future<void> _loadSettings() async {
    try {
      _enableMotionDetection = await HiveService.getSetting<bool>('sensor_motion_detection', defaultValue: true) ?? true;
      _enableAltitudeEstimation = await HiveService.getSetting<bool>('sensor_altitude_estimation', defaultValue: true) ?? true;
      _enableCompass = await HiveService.getSetting<bool>('sensor_compass', defaultValue: true) ?? true;
      _shakeThreshold = await HiveService.getSetting<double>('sensor_shake_threshold', defaultValue: 15.0) ?? 15.0;
      _tiltThreshold = await HiveService.getSetting<double>('sensor_tilt_threshold', defaultValue: 45.0) ?? 45.0;
      
      print('✅ Sensor settings loaded');
    } catch (e) {
      print('❌ Error loading sensor settings: $e');
    }
  }

  /// Save settings to Hive
  static Future<void> _saveSettings() async {
    try {
      await HiveService.saveSetting('sensor_motion_detection', _enableMotionDetection);
      await HiveService.saveSetting('sensor_altitude_estimation', _enableAltitudeEstimation);
      await HiveService.saveSetting('sensor_compass', _enableCompass);
      await HiveService.saveSetting('sensor_shake_threshold', _shakeThreshold);
      await HiveService.saveSetting('sensor_tilt_threshold', _tiltThreshold);
      
      print('✅ Sensor settings saved');
    } catch (e) {
      print('❌ Error saving sensor settings: $e');
    }
  }

  /// Update sensor settings
  static Future<void> updateSettings({
    bool? enableMotionDetection,
    bool? enableAltitudeEstimation,
    bool? enableCompass,
    double? shakeThreshold,
    double? tiltThreshold,
  }) async {
    if (enableMotionDetection != null) _enableMotionDetection = enableMotionDetection;
    if (enableAltitudeEstimation != null) _enableAltitudeEstimation = enableAltitudeEstimation;
    if (enableCompass != null) _enableCompass = enableCompass;
    if (shakeThreshold != null) _shakeThreshold = shakeThreshold;
    if (tiltThreshold != null) _tiltThreshold = tiltThreshold;
    
    await _saveSettings();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Stop all sensors
  static Future<void> stopAllSensors() async {
    await stopAccelerometer();
    await stopGyroscope();
    await stopMagnetometer();
    await stopBarometer();
  }

  /// Get current sensor data
  static Map<String, dynamic> getCurrentSensorData() {
    return {
      'accelerometer': _currentAccelerometerData != null ? {
        'x': _currentAccelerometerData!.x,
        'y': _currentAccelerometerData!.y,
        'z': _currentAccelerometerData!.z,
      } : null,
      'gyroscope': _currentGyroscopeData != null ? {
        'x': _currentGyroscopeData!.x,
        'y': _currentGyroscopeData!.y,
        'z': _currentGyroscopeData!.z,
      } : null,
      'magnetometer': _currentMagnetometerData != null ? {
        'x': _currentMagnetometerData!.x,
        'y': _currentMagnetometerData!.y,
        'z': _currentMagnetometerData!.z,
      } : null,
      'compass': {
        'bearing': _currentBearing,
        'direction': _currentDirection,
      },
      'altitude': _currentAltitude,
    };
  }

  /// Get sensor status
  static Map<String, dynamic> getSensorStatus() {
    return {
      'accelerometer': _isAccelerometerActive,
      'gyroscope': _isGyroscopeActive,
      'magnetometer': _isMagnetometerActive,
      'barometer': _isBarometerActive,
      'updateInterval': _sensorUpdateInterval.inMilliseconds,
      'settings': {
        'motionDetection': _enableMotionDetection,
        'altitudeEstimation': _enableAltitudeEstimation,
        'compass': _enableCompass,
        'shakeThreshold': _shakeThreshold,
        'tiltThreshold': _tiltThreshold,
      },
    };
  }

  /// Debug print sensor information
  static Future<void> printSensorDebug() async {
    try {
      print('🔍 === SENSOR SERVICE DEBUG ===');
      
      final status = getSensorStatus();
      print('🔍 Status: $status');
      
      final currentData = getCurrentSensorData();
      print('🔍 Current data: $currentData');
      
      final campingConditions = getCampingConditions();
      print('🔍 Camping conditions: $campingConditions');
      
      final motionAnalysis = analyzeMotionPatterns();
      print('🔍 Motion analysis: $motionAnalysis');
      
      print('🔍 Data log entries: ${_sensorLog.length}');
      
      print('==============================');
    } catch (e) {
      print('❌ Error in sensor debug: $e');
    }
  }
}