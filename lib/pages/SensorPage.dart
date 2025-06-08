import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/SensorService.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage>
    with TickerProviderStateMixin {
  
  // Sensor data
  Map<String, double> _accelerometerData = {'x': 0, 'y': 0, 'z': 0};
  Map<String, double> _gyroscopeData = {'x': 0, 'y': 0, 'z': 0};
  Map<String, double> _magnetometerData = {'x': 0, 'y': 0, 'z': 0};
  double _pressure = 1013.25; // Standard atmospheric pressure
  double _altitude = 0.0;
  String _compassDirection = 'N';
  double _compassDegree = 0.0;
  
  // UI State
  bool _isRecording = false;
  bool _sensorsAvailable = false;
  
  // Animation controllers
  late AnimationController _compassController;
  late AnimationController _levelController;
  late Animation<double> _compassAnimation;
  late Animation<double> _levelAnimation;
  
  // Timers
  Timer? _sensorTimer;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkSensorAvailability();
    _startSensorSimulation();
  }

  void _initializeAnimations() {
    _compassController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _compassAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _compassController,
      curve: Curves.easeInOut,
    ));

    _levelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelController,
      curve: Curves.elasticOut,
    ));

    _compassController.repeat();
    _levelController.forward();
  }

  Future<void> _checkSensorAvailability() async {
    try {
      final status = SensorService.getSensorStatus();
      setState(() {
        _sensorsAvailable = status['initialized'] ?? false;
      });
    } catch (e) {
      setState(() {
        _sensorsAvailable = false;
      });
    }
  }

  void _startSensorSimulation() {
    // Simulate sensor data updates
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        _updateSimulatedSensorData();
      }
    });
  }

  void _updateSimulatedSensorData() {
    final random = math.Random();
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    setState(() {
      // Simulate accelerometer (gravity + movement)
      _accelerometerData = {
        'x': math.sin(time * 0.5) * 2 + (random.nextDouble() - 0.5) * 0.5,
        'y': math.cos(time * 0.3) * 1.5 + (random.nextDouble() - 0.5) * 0.3,
        'z': 9.81 + math.sin(time * 0.8) * 0.5,
      };
      
      // Simulate gyroscope (rotation)
      _gyroscopeData = {
        'x': math.sin(time * 0.4) * 0.3,
        'y': math.cos(time * 0.6) * 0.2,
        'z': math.sin(time * 0.2) * 0.1,
      };
      
      // Simulate magnetometer (compass)
      _magnetometerData = {
        'x': math.cos(time * 0.1) * 50 + random.nextDouble() * 5,
        'y': math.sin(time * 0.1) * 50 + random.nextDouble() * 5,
        'z': -30 + random.nextDouble() * 10,
      };
      
      // Calculate compass direction
      _compassDegree = (math.atan2(_magnetometerData['y']!, _magnetometerData['x']!) * 180 / math.pi + 360) % 360;
      _compassDirection = _getCompassDirection(_compassDegree);
      
      // Simulate barometer
      _pressure = 1013.25 + math.sin(time * 0.05) * 10 + random.nextDouble() * 2;
      _altitude = _calculateAltitude(_pressure);
    });
  }

  String _getCompassDirection(double degree) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degree + 22.5) / 45).floor() % 8;
    return directions[index];
  }


double _calculateAltitude(double pressure) {
  // Barometric formula for altitude calculation
  const double seaLevelPressure = 1013.25;

  // math.pow mengembalikan num, jadi kita ubah .toDouble()
  final double ratio = pressure / seaLevelPressure;
  final double exponent = math.pow(ratio, 0.1903).toDouble();

  return 44330.0 * (1 - exponent);
}


  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    if (_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sensors, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Mulai merekam data sensor',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _stopRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stop, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Berhenti merekam data sensor',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _compassController.dispose();
    _levelController.dispose();
    _sensorTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Sensor Monitor',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isRecording ? Icons.stop : Icons.fiber_manual_record,
            color: _isRecording ? Colors.red : Colors.white,
          ),
          onPressed: _toggleRecording,
          tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Card
          _buildStatusCard(),
          
          const SizedBox(height: 16),
          
          // Compass Card
          _buildCompassCard(),
          
          const SizedBox(height: 16),
          
          // Level Card
          _buildLevelCard(),
          
          const SizedBox(height: 16),
          
          // Sensor Data Cards
          Row(
            children: [
              Expanded(child: _buildAccelerometerCard()),
              const SizedBox(width: 8),
              Expanded(child: _buildGyroscopeCard()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildMagnetometerCard()),
              const SizedBox(width: 8),
              Expanded(child: _buildBarometerCard()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Camping Tips Card
          _buildCampingTipsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _sensorsAvailable 
              ? [Colors.green[600]!, Colors.green[800]!]
              : [Colors.orange[600]!, Colors.orange[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _sensorsAvailable ? Icons.sensors : Icons.sensors_off,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sensorsAvailable ? 'Sensor Aktif' : 'Mode Simulasi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _sensorsAvailable 
                      ? 'Semua sensor berfungsi normal'
                      : 'Menggunakan data simulasi untuk demo',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_isRecording) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'REC',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Kompas Digital',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Compass
          AnimatedBuilder(
            animation: _compassAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_compassDegree * math.pi / 180,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        Colors.grey[100]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // North marker
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 0,
                            height: 0,
                            child: CustomPaint(
                              painter: CompassNeedlePainter(),
                            ),
                          ),
                        ),
                      ),
                      // Direction labels
                      Positioned(
                        top: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'N',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'S',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'W',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'E',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Arah',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _compassDirection,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Derajat',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_compassDegree.toStringAsFixed(1)}°',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    // Calculate tilt from accelerometer
    final tiltX = math.atan2(_accelerometerData['x']!, _accelerometerData['z']!) * 180 / math.pi;
    final tiltY = math.atan2(_accelerometerData['y']!, _accelerometerData['z']!) * 180 / math.pi;
    final isLevel = tiltX.abs() < 5 && tiltY.abs() < 5;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Water Level (Waterpass)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Level indicator
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isLevel ? Colors.green[600]! : Colors.orange[600]!,
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                // Center point
                Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Bubble
                AnimatedBuilder(
                  animation: _levelAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 100 + tiltX * 2 - 10,
                      top: 100 + tiltY * 2 - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isLevel ? Colors.green[600] : Colors.orange[600],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Tilt X',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${tiltX.toStringAsFixed(1)}°',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Tilt Y',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${tiltY.toStringAsFixed(1)}°',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(
                    isLevel ? Icons.check_circle : Icons.warning,
                    color: isLevel ? Colors.green[600] : Colors.orange[600],
                  ),
                  Text(
                    isLevel ? 'Level' : 'Tidak Level',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLevel ? Colors.green[600] : Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerometerCard() {
    return _buildSensorCard(
      title: 'Accelerometer',
      icon: Icons.speed,
      color: Colors.blue[600]!,
      data: _accelerometerData,
      unit: 'm/s²',
    );
  }

  Widget _buildGyroscopeCard() {
    return _buildSensorCard(
      title: 'Gyroscope',
      icon: Icons.threed_rotation_rounded,
      color: Colors.green[600]!,
      data: _gyroscopeData,
      unit: 'rad/s',
    );
  }

  Widget _buildMagnetometerCard() {
    return _buildSensorCard(
      title: 'Magnetometer',
      icon: Icons.explore,
      color: Colors.purple[600]!,
      data: _magnetometerData,
      unit: 'µT',
    );
  }

  Widget _buildBarometerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Barometer',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '${_pressure.toStringAsFixed(1)} hPa',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[600],
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Alt: ${_altitude.toStringAsFixed(0)}m',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, double> data,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Column(
            children: data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.toUpperCase()}:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(2)} $unit',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCampingTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[50]!,
            Colors.blue[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green[600]),
              const SizedBox(width: 8),
              Text(
                'Tips Camping dengan Sensor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '🧭 Kompas: Pastikan jauh dari benda logam untuk akurasi maksimal\n'
            '📏 Water Level: Gunakan untuk meratakan tenda dan peralatan\n'
            '🌡️ Barometer: Pantau perubahan cuaca mendadak\n'
            '📱 Gyroscope: Deteksi getaran untuk keamanan area camping',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.green[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    
    // Draw compass needle pointing north
    final path = Path()
      ..moveTo(0, -60)
      ..lineTo(-5, -40)
      ..lineTo(0, -45)
      ..lineTo(5, -40)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Draw south part of needle
    paint.color = Colors.grey[600]!;
    final southPath = Path()
      ..moveTo(0, 60)
      ..lineTo(-5, 40)
      ..lineTo(0, 45)
      ..lineTo(5, 40)
      ..close();
    
    canvas.drawPath(southPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}