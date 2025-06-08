// services/SensorService.dart (SakuRimba)
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  // Sensor settings
  static bool _enableMotionDetection = true;
  static bool _enableAltitudeEstimation = true;
  static bool _enableCompass = true;
  static double _shakeThreshold = 15.0;
  static double _tiltThreshold = 45.0;
  
  // Sensor streams
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  
  // Sensor data
  static AccelerometerEvent? _lastAccelerometerEvent;
  static GyroscopeEvent? _lastGyroscopeEvent;
  static MagnetometerEvent? _lastMagnetometerEvent;
  
  // Callbacks
  static Function(String)? _onShakeDetected;
  static Function(double)? _onTiltChanged;
  static Function(double)? _onCompassChanged;
  
  // State
  static bool _isInitialized = false;
  static DateTime? _lastShakeTime;

  /// Initialize sensor service
  static Future<void> init() async {
    try {
      if (_isInitialized) return;
      
      print('🔧 Initializing SensorService...');
      
      // Check if sensors are available
      final sensorsAvailable = await _checkSensorAvailability();
      
      if (sensorsAvailable) {
        await _startSensorListening();
        _isInitialized = true;
        print('✅ SensorService initialized successfully');
      } else {
        print('⚠️ Sensors not available on this device');
        _isInitialized = true; // Mark as initialized but without sensors
      }
    } catch (e) {
      print('❌ Error initializing SensorService: $e');
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }

  /// Check sensor availability
  static Future<bool> _checkSensorAvailability() async {
    try {
      // Try to get one reading from each sensor to check availability
      bool accelerometerAvailable = false;
      bool gyroscopeAvailable = false;
      bool magnetometerAvailable = false;
      
      // Test accelerometer
      try {
        await accelerometerEvents.first.timeout(Duration(seconds: 2));
        accelerometerAvailable = true;
      } catch (e) {
        print('⚠️ Accelerometer not available: $e');
      }
      
      // Test gyroscope
      try {
        await gyroscopeEvents.first.timeout(Duration(seconds: 2));
        gyroscopeAvailable = true;
      } catch (e) {
        print('⚠️ Gyroscope not available: $e');
      }
      
      // Test magnetometer
      try {
        await magnetometerEvents.first.timeout(Duration(seconds: 2));
        magnetometerAvailable = true;
      } catch (e) {
        print('⚠️ Magnetometer not available: $e');
      }
      
      print('📱 Sensor availability:');
      print('  Accelerometer: $accelerometerAvailable');
      print('  Gyroscope: $gyroscopeAvailable');
      print('  Magnetometer: $magnetometerAvailable');
      
      return accelerometerAvailable || gyroscopeAvailable || magnetometerAvailable;
    } catch (e) {
      print('❌ Error checking sensor availability: $e');
      return false;
    }
  }

  /// Start listening to sensors
  static Future<void> _startSensorListening() async {
    try {
      // Listen to accelerometer
      if (_enableMotionDetection) {
        _accelerometerSubscription = accelerometerEvents.listen(
          _onAccelerometerEvent,
          onError: (e) => print('⚠️ Accelerometer error: $e'),
        );
      }
      
      // Listen to gyroscope
      _gyroscopeSubscription = gyroscopeEvents.listen(
        _onGyroscopeEvent,
        onError: (e) => print('⚠️ Gyroscope error: $e'),
      );
      
      // Listen to magnetometer
      if (_enableCompass) {
        _magnetometerSubscription = magnetometerEvents.listen(
          _onMagnetometerEvent,
          onError: (e) => print('⚠️ Magnetometer error: $e'),
        );
      }
      
      print('🎧 Started listening to sensors');
    } catch (e) {
      print('❌ Error starting sensor listening: $e');
    }
  }

  /// Handle accelerometer events
  static void _onAccelerometerEvent(AccelerometerEvent event) {
    _lastAccelerometerEvent = event;
    
    if (_enableMotionDetection) {
      _detectShake(event);
      _detectTilt(event);
    }
  }

  /// Handle gyroscope events
  static void _onGyroscopeEvent(GyroscopeEvent event) {
    _lastGyroscopeEvent = event;
    // Can be used for rotation detection in future
  }

  /// Handle magnetometer events
  static void _onMagnetometerEvent(MagnetometerEvent event) {
    _lastMagnetometerEvent = event;
    
    if (_enableCompass) {
      _calculateCompass(event);
    }
  }

  /// Detect shake gesture
  static void _detectShake(AccelerometerEvent event) {
    try {
      final double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Remove gravity (approximately 9.8 m/s²)
      final double netAcceleration = magnitude - 9.8;
      
      if (netAcceleration.abs() > _shakeThreshold) {
        final now = DateTime.now();
        
        // Prevent multiple shake detections within 1 second
        if (_lastShakeTime == null || 
            now.difference(_lastShakeTime!).inMilliseconds > 1000) {
          _lastShakeTime = now;
          _onShakeDetected?.call('Device shaken with force: ${netAcceleration.toStringAsFixed(2)}');
          print('📳 Shake detected: ${netAcceleration.toStringAsFixed(2)} m/s²');
        }
      }
    } catch (e) {
      print('❌ Error detecting shake: $e');
    }
  }

  /// Detect tilt
  static void _detectTilt(AccelerometerEvent event) {
    try {
      // Calculate tilt angle from vertical
      final double tiltAngle = atan2(
        sqrt(event.x * event.x + event.y * event.y),
        event.z.abs()
      ) * 180 / pi;
      
      if (tiltAngle > _tiltThreshold) {
        _onTiltChanged?.call(tiltAngle);
      }
    } catch (e) {
      print('❌ Error detecting tilt: $e');
    }
  }

  /// Calculate compass direction
  static void _calculateCompass(MagnetometerEvent event) {
    try {
      // Calculate compass heading (simplified)
      final double heading = atan2(event.y, event.x) * 180 / pi;
      final double normalizedHeading = (heading + 360) % 360;
      
      _onCompassChanged?.call(normalizedHeading);
    } catch (e) {
      print('❌ Error calculating compass: $e');
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
    try {
      bool needsRestart = false;
      
      if (enableMotionDetection != null && enableMotionDetection != _enableMotionDetection) {
        _enableMotionDetection = enableMotionDetection;
        needsRestart = true;
      }
      
      if (enableAltitudeEstimation != null) {
        _enableAltitudeEstimation = enableAltitudeEstimation;
      }
      
      if (enableCompass != null && enableCompass != _enableCompass) {
        _enableCompass = enableCompass;
        needsRestart = true;
      }
      
      if (shakeThreshold != null) {
        _shakeThreshold = shakeThreshold;
      }
      
      if (tiltThreshold != null) {
        _tiltThreshold = tiltThreshold;
      }
      
      // Restart sensors if needed
      if (needsRestart && _isInitialized) {
        await _stopSensorListening();
        await _startSensorListening();
      }
      
      print('✅ Sensor settings updated');
    } catch (e) {
      print('❌ Error updating sensor settings: $e');
    }
  }

  /// Stop sensor listening
  static Future<void> _stopSensorListening() async {
    try {
      await _accelerometerSubscription?.cancel();
      await _gyroscopeSubscription?.cancel();
      await _magnetometerSubscription?.cancel();
      
      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _magnetometerSubscription = null;
      
      print('🔇 Stopped listening to sensors');
    } catch (e) {
      print('❌ Error stopping sensor listening: $e');
    }
  }

  /// Set callbacks
  static void setShakeCallback(Function(String) callback) {
    _onShakeDetected = callback;
  }

  static void setTiltCallback(Function(double) callback) {
    _onTiltChanged = callback;
  }

  static void setCompassCallback(Function(double) callback) {
    _onCompassChanged = callback;
  }

  /// Get current sensor readings
  static Map<String, dynamic> getCurrentReadings() {
    return {
      'accelerometer': _lastAccelerometerEvent != null ? {
        'x': _lastAccelerometerEvent!.x,
        'y': _lastAccelerometerEvent!.y,
        'z': _lastAccelerometerEvent!.z,
        'magnitude': sqrt(
          _lastAccelerometerEvent!.x * _lastAccelerometerEvent!.x +
          _lastAccelerometerEvent!.y * _lastAccelerometerEvent!.y +
          _lastAccelerometerEvent!.z * _lastAccelerometerEvent!.z
        ),
      } : null,
      'gyroscope': _lastGyroscopeEvent != null ? {
        'x': _lastGyroscopeEvent!.x,
        'y': _lastGyroscopeEvent!.y,
        'z': _lastGyroscopeEvent!.z,
      } : null,
      'magnetometer': _lastMagnetometerEvent != null ? {
        'x': _lastMagnetometerEvent!.x,
        'y': _lastMagnetometerEvent!.y,
        'z': _lastMagnetometerEvent!.z,
      } : null,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Get estimated altitude (simplified calculation)
  static double? getEstimatedAltitude() {
    if (!_enableAltitudeEstimation || _lastAccelerometerEvent == null) {
      return null;
    }
    
    try {
      // Simplified altitude estimation based on accelerometer
      // In reality, this would require barometric pressure sensor
      final double verticalAccel = _lastAccelerometerEvent!.z;
      
      // This is a very rough estimation and not accurate
      // Real altitude estimation requires proper barometric sensor
      final double estimatedAltitude = (9.8 - verticalAccel.abs()) * 100;
      
      return estimatedAltitude.clamp(0, 5000); // Clamp to reasonable range
    } catch (e) {
      print('❌ Error estimating altitude: $e');
      return null;
    }
  }

  /// Get compass direction string
  static String getCompassDirection(double heading) {
    const directions = [
      'Utara', 'Timur Laut', 'Timur', 'Tenggara',
      'Selatan', 'Barat Daya', 'Barat', 'Barat Laut'
    ];
    
    final int index = ((heading + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Get sensor status
  static Map<String, dynamic> getSensorStatus() {
    return {
      'initialized': _isInitialized,
      'motion_detection': _enableMotionDetection,
      'altitude_estimation': _enableAltitudeEstimation,
      'compass': _enableCompass,
      'shake_threshold': _shakeThreshold,
      'tilt_threshold': _tiltThreshold,
      'active_subscriptions': {
        'accelerometer': _accelerometerSubscription != null,
        'gyroscope': _gyroscopeSubscription != null,
        'magnetometer': _magnetometerSubscription != null,
      },
      'last_readings': getCurrentReadings(),
      'estimated_altitude': getEstimatedAltitude(),
    };
  }

  /// Dispose sensor service
  static Future<void> dispose() async {
    try {
      await _stopSensorListening();
      _isInitialized = false;
      
      // Clear callbacks
      _onShakeDetected = null;
      _onTiltChanged = null;
      _onCompassChanged = null;
      
      // Clear last events
      _lastAccelerometerEvent = null;
      _lastGyroscopeEvent = null;
      _lastMagnetometerEvent = null;
      
      print('🗑️ SensorService disposed');
    } catch (e) {
      print('❌ Error disposing SensorService: $e');
    }
  }

  /// Calibrate sensors (placeholder)
  static Future<void> calibrateSensors() async {
    try {
      print('🔄 Calibrating sensors...');
      
      // In a real implementation, this would perform sensor calibration
      // For now, just reset thresholds to default values
      _shakeThreshold = 15.0;
      _tiltThreshold = 45.0;
      
      await Future.delayed(Duration(seconds: 2)); // Simulate calibration time
      
      print('✅ Sensor calibration completed');
    } catch (e) {
      print('❌ Error calibrating sensors: $e');
    }
  }

  /// Test sensors
  static Future<Map<String, bool>> testSensors() async {
    try {
      print('🧪 Testing sensors...');
      
      final results = <String, bool>{};
      
      // Test accelerometer
      try {
        await accelerometerEvents.first.timeout(Duration(seconds: 3));
        results['accelerometer'] = true;
      } catch (e) {
        results['accelerometer'] = false;
      }
      
      // Test gyroscope
      try {
        await gyroscopeEvents.first.timeout(Duration(seconds: 3));
        results['gyroscope'] = true;
      } catch (e) {
        results['gyroscope'] = false;
      }
      
      // Test magnetometer
      try {
        await magnetometerEvents.first.timeout(Duration(seconds: 3));
        results['magnetometer'] = true;
      } catch (e) {
        results['magnetometer'] = false;
      }
      
      print('✅ Sensor test completed: $results');
      return results;
    } catch (e) {
      print('❌ Error testing sensors: $e');
      return {};
    }
  }

  /// Debug method
  static void printSensorDebug() {
    try {
      print('🔍 === SENSOR SERVICE DEBUG ===');
      
      final status = getSensorStatus();
      print('Initialized: ${status['initialized']}');
      print('Motion Detection: ${status['motion_detection']}');
      print('Altitude Estimation: ${status['altitude_estimation']}');
      print('Compass: ${status['compass']}');
      print('Shake Threshold: ${status['shake_threshold']}');
      print('Tilt Threshold: ${status['tilt_threshold']}');
      
      final subscriptions = status['active_subscriptions'] as Map<String, dynamic>;
      print('Active Subscriptions:');
      subscriptions.forEach((sensor, active) {
        print('  $sensor: $active');
      });
      
      final readings = getCurrentReadings();
      if (readings['accelerometer'] != null) {
        final accel = readings['accelerometer'] as Map<String, dynamic>;
        print('Accelerometer: x=${accel['x']?.toStringAsFixed(2)}, y=${accel['y']?.toStringAsFixed(2)}, z=${accel['z']?.toStringAsFixed(2)}');
      }
      
      final altitude = getEstimatedAltitude();
      if (altitude != null) {
        print('Estimated Altitude: ${altitude.toStringAsFixed(2)}m');
      }
      
      print('==============================');
    } catch (e) {
      print('❌ Error in sensor debug: $e');
    }
  }
}