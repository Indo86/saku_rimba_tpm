import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/SettingsService.dart';
import '../services/UserService.dart';
import '../services/NotificationService.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Settings values
  String _currentTheme = 'light';
  String _currentLanguage = 'id';
  bool _notificationsEnabled = true;
  bool _rentalReminders = true;
  bool _paymentAlerts = true;
  bool _promotions = true;
  bool _analyticsEnabled = true;
  bool _locationEnabled = true;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load current settings
      _currentTheme = SettingsService.getTheme();
      _currentLanguage = SettingsService.getLanguage();
      _notificationsEnabled = SettingsService.areNotificationsEnabled();
      _rentalReminders = SettingsService.isNotificationTypeEnabled('rental_reminders');
      _paymentAlerts = SettingsService.isNotificationTypeEnabled('payment_alerts');
      _promotions = SettingsService.isNotificationTypeEnabled('promotions');
      _analyticsEnabled = SettingsService.areAnalyticsEnabled();
      _locationEnabled = SettingsService.isLocationDataEnabled();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat pengaturan: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await SettingsService.setSetting(key, value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengaturan berhasil disimpan',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan pengaturan: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(
              'Reset Pengaturan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SettingsService.resetAllSettings();
              await _loadSettings();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Semua pengaturan telah direset',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Pengaturan',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.teal[800],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          onPressed: _showResetConfirmation,
          tooltip: 'Reset ke Default',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        indicatorColor: Colors.white,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Umum'),
          Tab(text: 'Notifikasi'),
          Tab(text: 'Privasi'),
          Tab(text: 'Lainnya'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGeneralSettings(),
        _buildNotificationSettings(),
        _buildPrivacySettings(),
        _buildOtherSettings(),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildSettingsHeader('Tampilan'),
            _buildThemeSelector(),
            _buildLanguageSelector(),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard([
            _buildSettingsHeader('Lokasi'),
            _buildSwitchTile(
              'Izinkan Akses Lokasi',
              'Untuk fitur pencarian berdasarkan lokasi',
              Icons.location_on,
              _locationEnabled,
              (value) async {
                setState(() {
                  _locationEnabled = value;
                });
                await _updateSetting('location_enabled', value);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildSettingsHeader('Notifikasi Umum'),
            _buildSwitchTile(
              'Aktifkan Notifikasi',
              'Terima semua notifikasi dari aplikasi',
              Icons.notifications,
              _notificationsEnabled,
              (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _updateSetting('notifications_enabled', value);
              },
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard([
            _buildSettingsHeader('Jenis Notifikasi'),
            _buildSwitchTile(
              'Pengingat Sewa',
              'Notifikasi tentang jadwal penyewaan',
              Icons.schedule,
              _rentalReminders && _notificationsEnabled,
              _notificationsEnabled ? (value) async {
                setState(() {
                  _rentalReminders = value;
                });
                await _updateSetting('notifications_rental_reminders', value);
              } : null,
            ),
            _buildSwitchTile(
              'Alert Pembayaran',
              'Notifikasi tentang status pembayaran',
              Icons.payment,
              _paymentAlerts && _notificationsEnabled,
              _notificationsEnabled ? (value) async {
                setState(() {
                  _paymentAlerts = value;
                });
                await _updateSetting('notifications_payment_alerts', value);
              } : null,
            ),
            _buildSwitchTile(
              'Promosi & Penawaran',
              'Notifikasi tentang promo dan diskon',
              Icons.local_offer,
              _promotions && _notificationsEnabled,
              _notificationsEnabled ? (value) async {
                setState(() {
                  _promotions = value;
                });
                await _updateSetting('notifications_promotions', value);
              } : null,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildSettingsHeader('Data & Analytics'),
            _buildSwitchTile(
              'Analytics',
              'Bantu kami meningkatkan aplikasi',
              Icons.analytics,
              _analyticsEnabled,
              (value) async {
                setState(() {
                  _analyticsEnabled = value;
                });
                await _updateSetting('privacy_analytics', value);
              },
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard([
            _buildSettingsHeader('Informasi Akun'),
            _buildActionTile(
              'Ubah Password',
              'Ganti password akun Anda',
              Icons.lock,
              () => _showChangePasswordDialog(),
            ),
            if (UserService.isUserLoggedIn())
              _buildActionTile(
                'Hapus Akun',
                'Hapus permanen akun Anda',
                Icons.delete_forever,
                () => _showDeleteAccountDialog(),
                isDestructive: true,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildOtherSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard([
            _buildSettingsHeader('Aplikasi'),
            _buildActionTile(
              'Bersihkan Cache',
              'Hapus data cache aplikasi',
              Icons.clear_all,
              () => _clearCache(),
            ),
            _buildActionTile(
              'Laporan Bug',
              'Laporkan masalah atau bug',
              Icons.bug_report,
              () => _showBugReportDialog(),
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard([
            _buildSettingsHeader('Informasi'),
            _buildActionTile(
              'Syarat & Ketentuan',
              'Baca syarat penggunaan aplikasi',
              Icons.description,
              () => _showTermsDialog(),
            ),
            _buildActionTile(
              'Kebijakan Privasi',
              'Pelajari kebijakan privasi kami',
              Icons.privacy_tip,
              () => _showPrivacyDialog(),
            ),
            _buildActionTile(
              'Tentang Aplikasi',
              'Informasi versi dan developer',
              Icons.info,
              () => _showAboutDialog(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal[700],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: onChanged != null ? Colors.teal[600] : Colors.grey[400],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: onChanged != null ? Colors.grey[800] : Colors.grey[400],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: onChanged != null ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal[600],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red[600] : Colors.teal[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red[600] : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector() {
    return ListTile(
      leading: Icon(Icons.palette, color: Colors.teal[600]),
      title: Text(
        'Tema',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _currentTheme == 'light' ? 'Terang' : 'Gelap',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: DropdownButton<String>(
        value: _currentTheme,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 'light',
            child: Text('Terang', style: GoogleFonts.poppins()),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: Text('Gelap', style: GoogleFonts.poppins()),
          ),
        ],
        onChanged: (value) async {
          if (value != null) {
            setState(() {
              _currentTheme = value;
            });
            await _updateSetting('app_theme', value);
          }
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      leading: Icon(Icons.language, color: Colors.teal[600]),
      title: Text(
        'Bahasa',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _currentLanguage == 'id' ? 'Bahasa Indonesia' : 'English',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: DropdownButton<String>(
        value: _currentLanguage,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 'id',
            child: Text('Bahasa Indonesia', style: GoogleFonts.poppins()),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text('English', style: GoogleFonts.poppins()),
          ),
        ],
        onChanged: (value) async {
          if (value != null) {
            setState(() {
              _currentLanguage = value;
            });
            await _updateSetting('app_language', value);
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscureOld = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Ubah Password',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: isObscureOld,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    labelStyle: GoogleFonts.poppins(),
                    suffixIcon: IconButton(
                      icon: Icon(isObscureOld ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isObscureOld = !isObscureOld),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password lama diperlukan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: isObscureNew,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    labelStyle: GoogleFonts.poppins(),
                    suffixIcon: IconButton(
                      icon: Icon(isObscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isObscureNew = !isObscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru diperlukan';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: isObscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    labelStyle: GoogleFonts.poppins(),
                    suffixIcon: IconButton(
                      icon: Icon(isObscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isObscureConfirm = !isObscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final success = await UserService.changePassword(
                      oldPasswordController.text,
                      newPasswordController.text,
                    );
                    
                    Navigator.pop(context);
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password berhasil diubah',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Password lama tidak benar',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal mengubah password: $e',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Ubah',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            Text(
              'Hapus Akun',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Tindakan ini akan menghapus permanen akun Anda beserta semua data. Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fitur hapus akun akan segera tersedia',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Bersihkan Cache',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua data cache aplikasi?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cache berhasil dibersihkan',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Bersihkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Laporan Bug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deskripsikan masalah atau bug yang Anda temukan:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Jelaskan masalah yang Anda alami...',
                hintStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Laporan berhasil dikirim. Terima kasih!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Kirim',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Syarat & Ketentuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Dengan menggunakan aplikasi SakuRimba, Anda menyetujui syarat dan ketentuan berikut:

1. Aplikasi ini digunakan untuk keperluan penyewaan peralatan camping yang sah.

2. Pengguna bertanggung jawab atas peralatan yang disewa dan harus mengembalikan dalam kondisi baik.

3. Pembayaran harus dilakukan sesuai dengan ketentuan yang telah disepakati.

4. SakuRimba berhak membatalkan pesanan jika melanggar ketentuan.

5. Pengguna wajib memberikan informasi yang akurat saat mendaftar.

Syarat dan ketentuan dapat berubah sewaktu-waktu tanpa pemberitahuan sebelumnya.''',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Kebijakan Privasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''SakuRimba berkomitmen melindungi privasi pengguna:

1. Data Pribadi: Kami mengumpulkan nama, email, nomor telepon, dan alamat untuk keperluan layanan.

2. Penggunaan Data: Data digunakan untuk memproses pesanan, komunikasi, dan meningkatkan layanan.

3. Keamanan: Data disimpan dengan aman dan tidak dibagikan kepada pihak ketiga tanpa izin.

4. Cookies: Aplikasi menggunakan cookies untuk meningkatkan pengalaman pengguna.

5. Hak Pengguna: Anda dapat mengakses, memperbarui, atau menghapus data pribadi Anda.

6. Perubahan Kebijakan: Kebijakan dapat berubah dan pengguna akan diberitahu melalui aplikasi.

Untuk pertanyaan tentang privasi, hubungi tim support kami.''',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.backpack, color: Colors.teal[600]),
            const SizedBox(width: 8),
            Text(
              'SakuRimba',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Alat Camping',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi mobile yang memfasilitasi pengguna dalam menyewa alat-alat camping dan outdoor dengan cepat, aman, dan fleksibel.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Versi: 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Build: 2025.06.08',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '© 2025 SakuRimba Team',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.teal[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}