import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class TimeConverterPage extends StatefulWidget {
  const TimeConverterPage({super.key});

  @override
  State<TimeConverterPage> createState() => _TimeConverterPageState();
}

class _TimeConverterPageState extends State<TimeConverterPage>
    with TickerProviderStateMixin {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String _selectedTimezone = 'WIB';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _clockController;
  late Animation<double> _clockAnimation;

  final Map<String, Map<String, dynamic>> _timezones = {
    'WIB': {
      'name': 'Waktu Indonesia Barat',
      'offset': 7,
      'cities': ['Jakarta', 'Bandung', 'Medan', 'Palembang'],
      'flag': '🇮🇩',
      'color': Colors.blue[600],
    },
    'WITA': {
      'name': 'Waktu Indonesia Tengah',
      'offset': 8,
      'cities': ['Makassar', 'Denpasar', 'Balikpapan', 'Banjarmasin'],
      'flag': '🇮🇩',
      'color': Colors.green[600],
    },
    'WIT': {
      'name': 'Waktu Indonesia Timur',
      'offset': 9,
      'cities': ['Jayapura', 'Ambon', 'Manokwari', 'Sorong'],
      'flag': '🇮🇩',
      'color': Colors.orange[600],
    },
    'London': {
      'name': 'London Time (GMT/BST)',
      'offset': 0, // GMT in winter, +1 in summer
      'cities': ['London', 'Manchester', 'Edinburgh', 'Birmingham'],
      'flag': '🇬🇧',
      'color': Colors.purple[600],
    },
    'Tokyo': {
      'name': 'Japan Standard Time',
      'offset': 9,
      'cities': ['Tokyo', 'Osaka', 'Kyoto', 'Yokohama'],
      'flag': '🇯🇵',
      'color': Colors.red[600],
    },
    'Singapore': {
      'name': 'Singapore Standard Time',
      'offset': 8,
      'cities': ['Singapore'],
      'flag': '🇸🇬',
      'color': Colors.teal[600],
    },
    'New York': {
      'name': 'Eastern Time (EST/EDT)',
      'offset': -5, // EST in winter, -4 in summer
      'cities': ['New York', 'Boston', 'Washington DC', 'Atlanta'],
      'flag': '🇺🇸',
      'color': Colors.indigo[600],
    },
    'Dubai': {
      'name': 'Gulf Standard Time',
      'offset': 4,
      'cities': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Riyadh'],
      'flag': '🇦🇪',
      'color': Colors.amber[600],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _clockController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _clockAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _clockController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _clockController.repeat();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  DateTime _getTimeForTimezone(String timezone) {
    final now = DateTime.now().toUtc();
    final offset = _timezones[timezone]!['offset'] as int;
    
    // Handle daylight saving time for London and New York
    if (timezone == 'London') {
      final isDST = _isDaylightSavingTime(now, 'London');
      return now.add(Duration(hours: isDST ? 1 : 0));
    } else if (timezone == 'New York') {
      final isDST = _isDaylightSavingTime(now, 'New York');
      return now.add(Duration(hours: offset + (isDST ? 1 : 0)));
    }
    
    return now.add(Duration(hours: offset));
  }

  bool _isDaylightSavingTime(DateTime utc, String location) {
    // Simplified DST calculation - in real app, use proper timezone library
    final year = utc.year;
    
    if (location == 'London') {
      // BST: Last Sunday in March to Last Sunday in October
      final marchLastSunday = _getLastSunday(year, 3);
      final octoberLastSunday = _getLastSunday(year, 10);
      return utc.isAfter(marchLastSunday) && utc.isBefore(octoberLastSunday);
    } else if (location == 'New York') {
      // EDT: Second Sunday in March to First Sunday in November
      final marchSecondSunday = _getSecondSunday(year, 3);
      final novemberFirstSunday = _getFirstSunday(year, 11);
      return utc.isAfter(marchSecondSunday) && utc.isBefore(novemberFirstSunday);
    }
    
    return false;
  }

  DateTime _getLastSunday(int year, int month) {
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysFromSunday = lastDayOfMonth.weekday % 7;
    return DateTime(year, month, lastDayOfMonth.day - daysFromSunday);
  }

  DateTime _getSecondSunday(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);
    final firstSunday = DateTime(year, month, 1 + (7 - firstOfMonth.weekday) % 7);
    return firstSunday.add(const Duration(days: 7));
  }

  DateTime _getFirstSunday(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);
    return DateTime(year, month, 1 + (7 - firstOfMonth.weekday) % 7);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatDate(DateTime time) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    
    final dayName = days[time.weekday - 1];
    final day = time.day;
    final month = months[time.month - 1];
    final year = time.year;
    
    return '$dayName, $day $month $year';
  }

  String _getTimeDifference(String fromTimezone, String toTimezone) {
    final fromTime = _getTimeForTimezone(fromTimezone);
    final toTime = _getTimeForTimezone(toTimezone);
    final difference = toTime.difference(fromTime).inHours;
    
    if (difference == 0) return 'Sama';
    if (difference > 0) return '+$difference jam';
    return '$difference jam';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _clockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Konversi Waktu',
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
          icon: const Icon(Icons.access_time, color: Colors.white),
          onPressed: () {},
          tooltip: 'Waktu Real-time',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Current Time Display
          _buildCurrentTimeDisplay(),
          
          // Time Zone Selector
          _buildTimezoneSelector(),
          
          // World Clock Grid
          _buildWorldClockGrid(),
          
          // Time Difference Calculator
          _buildTimeDifferenceCalculator(),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeDisplay() {
    final selectedTime = _getTimeForTimezone(_selectedTimezone);
    final selectedData = _timezones[_selectedTimezone]!;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selectedData['color'] as Color,
            (selectedData['color'] as Color).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (selectedData['color'] as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selectedData['flag'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTimezone,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      selectedData['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Digital Clock
          AnimatedBuilder(
            animation: _clockAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(selectedTime),
                  style: GoogleFonts.orbitron(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _formatDate(selectedTime),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cities
          Wrap(
            spacing: 8,
            children: (selectedData['cities'] as List<String>).map((city) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  city,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimezoneSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _timezones.length,
        itemBuilder: (context, index) {
          final timezone = _timezones.keys.elementAt(index);
          final data = _timezones[timezone]!;
          final isSelected = timezone == _selectedTimezone;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimezone = timezone;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? data['color'] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: (data['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['flag'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timezone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorldClockGrid() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waktu Dunia',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _timezones.length,
            itemBuilder: (context, index) {
              final timezone = _timezones.keys.elementAt(index);
              final data = _timezones[timezone]!;
              final time = _getTimeForTimezone(timezone);
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: timezone == _selectedTimezone 
                        ? data['color'] as Color
                        : Colors.grey[200]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['flag'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timezone,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: data['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _formatTime(time),
                      style: GoogleFonts.orbitron(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${time.day}/${time.month}/${time.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      _getTimeDifference('WIB', timezone),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: data['color'],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDifferenceCalculator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalkulator Perbedaan Waktu',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Perbedaan waktu dari Indonesia:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Column(
            children: _timezones.entries.map((entry) {
              if (entry.key.startsWith('WI')) return const SizedBox.shrink();
              
              final timezone = entry.key;
              final data = entry.value;
              final difference = _getTimeDifference('WIB', timezone);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      data['flag'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        timezone,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        difference,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waktu ditampilkan secara real-time dengan mempertimbangkan Daylight Saving Time',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}