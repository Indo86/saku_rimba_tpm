import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../services/CurrencyService.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage>
    with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _result = 0.0;
  bool _isLoading = false;
  DateTime? _lastUpdate;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _swapController;
  late Animation<double> _swapAnimation;

  final Map<String, Map<String, dynamic>> _currencies = {
    'IDR': {
      'name': 'Indonesian Rupiah',
      'symbol': 'Rp',
      'flag': '🇮🇩',
      'rate': 1.0, // Base currency
    },
    'USD': {
      'name': 'US Dollar',
      'symbol': '\$',
      'flag': '🇺🇸',
      'rate': 0.000066, // 1 IDR = 0.000066 USD (approx)
    },
    'EUR': {
      'name': 'Euro',
      'symbol': '€',
      'flag': '🇪🇺',
      'rate': 0.000061, // 1 IDR = 0.000061 EUR (approx)
    },
    'GBP': {
      'name': 'British Pound',
      'symbol': '£',
      'flag': '🇬🇧',
      'rate': 0.000052, // 1 IDR = 0.000052 GBP (approx)
    },
    'JPY': {
      'name': 'Japanese Yen',
      'symbol': '¥',
      'flag': '🇯🇵',
      'rate': 0.0097, // 1 IDR = 0.0097 JPY (approx)
    },
    'SGD': {
      'name': 'Singapore Dollar',
      'symbol': 'S\$',
      'flag': '🇸🇬',
      'rate': 0.000088, // 1 IDR = 0.000088 SGD (approx)
    },
    'MYR': {
      'name': 'Malaysian Ringgit',
      'symbol': 'RM',
      'flag': '🇲🇾',
      'rate': 0.00030, // 1 IDR = 0.00030 MYR (approx)
    },
    'CNY': {
      'name': 'Chinese Yuan',
      'symbol': '¥',
      'flag': '🇨🇳',
      'rate': 0.00047, // 1 IDR = 0.00047 CNY (approx)
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _amountController.text = '1000000'; // Default 1 million IDR
    _calculateConversion();
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

    _swapController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _swapAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swapController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
  }

  void _calculateConversion() {
    if (_amountController.text.isEmpty) {
      setState(() {
        _result = 0.0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      
      // Convert to IDR first (base currency)
      double amountInIDR;
      if (_fromCurrency == 'IDR') {
        amountInIDR = amount;
      } else {
        final fromRate = _currencies[_fromCurrency]!['rate'] as double;
        amountInIDR = amount / fromRate;
      }
      
      // Convert from IDR to target currency
      if (_toCurrency == 'IDR') {
        _result = amountInIDR;
      } else {
        final toRate = _currencies[_toCurrency]!['rate'] as double;
        _result = amountInIDR * toRate;
      }
      
      setState(() {
        _isLoading = false;
        _lastUpdate = DateTime.now();
      });
    });
  }

  void _swapCurrencies() {
    _swapController.forward().then((_) {
      setState(() {
        final temp = _fromCurrency;
        _fromCurrency = _toCurrency;
        _toCurrency = temp;
      });
      _calculateConversion();
      _swapController.reset();
    });
  }

  void _copyResult() {
    final formattedResult = _formatCurrency(_result, _toCurrency);
    Clipboard.setData(ClipboardData(text: formattedResult));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Hasil disalin: $formattedResult',
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

  String _formatCurrency(double amount, String currency) {
    final symbol = _currencies[currency]!['symbol'] as String;
    
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount < 0.01 && amount > 0) {
      return '$symbol${amount.toStringAsFixed(6)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return value;
    
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _swapController.dispose();
    _amountController.dispose();
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
        'Konversi Mata Uang',
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
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _calculateConversion,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Exchange Rate Info
          _buildExchangeRateInfo(),
          
          const SizedBox(height: 24),
          
          // Input Section
          _buildInputSection(),
          
          const SizedBox(height: 24),
          
          // Swap Button
          _buildSwapButton(),
          
          const SizedBox(height: 24),
          
          // Result Section
          _buildResultSection(),
          
          const SizedBox(height: 32),
          
          // Quick Amount Buttons
          _buildQuickAmountButtons(),
          
          const SizedBox(height: 32),
          
          // Popular Currencies
          _buildPopularCurrencies(),
        ],
      ),
    );
  }

  Widget _buildExchangeRateInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal[600]!,
            Colors.teal[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kurs Mata Uang',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _lastUpdate != null 
                      ? 'Diperbarui ${_formatTime(_lastUpdate!)}'
                      : 'Belum diperbarui',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
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
            'Dari',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) {
                    _calculateConversion();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildCurrencyDropdown(_fromCurrency, (value) {
                  setState(() {
                    _fromCurrency = value!;
                  });
                  _calculateConversion();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return GestureDetector(
      onTap: _swapCurrencies,
      child: AnimatedBuilder(
        animation: _swapAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _swapAnimation.value * 2 * 3.14159,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ke',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              IconButton(
                onPressed: _copyResult,
                icon: Icon(Icons.copy, color: Colors.grey[600]),
                tooltip: 'Salin hasil',
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          _formatCurrency(_result, _toCurrency),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildCurrencyDropdown(_toCurrency, (value) {
                  setState(() {
                    _toCurrency = value!;
                  });
                  _calculateConversion();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          items: _currencies.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(
                    entry.value['flag'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    final amounts = [
      {'label': '100K', 'value': 100000},
      {'label': '500K', 'value': 500000},
      {'label': '1M', 'value': 1000000},
      {'label': '10M', 'value': 10000000},
    ];

    return Container(
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
            'Jumlah Cepat',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  _amountController.text = amount['value'].toString();
                  _calculateConversion();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Text(
                    amount['label'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCurrencies() {
    final popular = ['USD', 'EUR', 'SGD', 'JPY'];
    
    return Container(
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
            'Mata Uang Populer',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Column(
            children: popular.map((currency) {
              final currencyData = _currencies[currency]!;
              final rate = currencyData['rate'] as double;
              final oneUnitInIDR = 1 / rate;
              
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
                      currencyData['flag'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1 $currency',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            currencyData['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(oneUnitInIDR, 'IDR'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[700],
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return '${difference.inHours} jam lalu';
    }
  }
}