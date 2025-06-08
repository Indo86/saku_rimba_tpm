// FIXED: Editable Message & Review - EditProfilePage.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/UserService.dart';
import '../services/HiveService.dart'; // FIXED: Add HiveService for custom message storage
import '../models/user.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // FIXED: Add controllers for editable message and review
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();
  final _learningPointsController = TextEditingController();
  final _gratitudeController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  User? _currentUser;
  final ImagePicker _picker = ImagePicker();

  // FIXED: Default content
  String _defaultMessage = '';
  String _defaultReview = '';
  String _defaultLearningPoints = '';
  String _defaultGratitude = '';

  @override
  void initState() {
    super.initState();
    _initializeDefaultContent();
    _loadUserData();
    _loadCustomMessages();
  }

  void _initializeDefaultContent() {
    _defaultMessage = '''Mata kuliah Teknologi dan Pemrograman Mobile ini sangat menarik dan memberikan pemahaman mendalam tentang pengembangan aplikasi mobile modern. Melalui pembelajaran Flutter, saya dapat memahami konsep cross-platform development yang sangat efisien.

Flutter framework memberikan pengalaman development yang luar biasa dengan hot reload feature yang memungkinkan perubahan code langsung terlihat hasilnya. Dart sebagai bahasa pemrograman juga mudah dipelajari dengan syntax yang clean dan modern.''';

    _defaultReview = '''Pembelajaran mobile programming memberikan insight baru tentang:
• User Experience (UX) design yang responsive
• State management yang efektif
• Integration dengan berbagai API dan services
• Performance optimization untuk mobile apps
• Cross-platform development best practices

Setiap tugas dan project memberikan challenge yang berbeda, mulai dari UI design hingga complex business logic implementation.''';

    _defaultLearningPoints = '''• Dart Programming Language & Advanced Features
• Flutter Framework & Custom Widgets
• State Management (Provider, Bloc, Riverpod)
• API Integration & RESTful Web Services
• Local Database (Hive/SQLite) & Data Persistence
• Device Sensor Integration (GPS, Camera, etc.)
• Location-Based Services & Maps Integration
• Push Notifications & Background Processing
• App Performance Optimization
• Testing & Debugging Techniques''';

    _defaultGratitude = '''Terima kasih kepada dosen pengampu yang telah membimbing dengan sabar dan memberikan ilmu yang sangat bermanfaat! 

Pembelajaran ini tidak hanya memberikan skill teknis, tetapi juga mindset problem-solving yang akan berguna dalam karir development ke depan. Semoga ilmu yang didapat dapat diterapkan untuk menciptakan aplikasi yang bermanfaat bagi masyarakat.''';
  }

  void _loadUserData() {
    _currentUser = UserService.getCurrentUser();
    if (_currentUser != null) {
      _namaController.text = _currentUser!.nama;
      _usernameController.text = _currentUser!.username;
      _emailController.text = _currentUser!.email;
      _phoneController.text = _currentUser!.phone;
      _addressController.text = _currentUser!.alamat;
    }
  }

  // FIXED: Load custom messages from storage
  Future<void> _loadCustomMessages() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return;

      final customMessage = await HiveService.getSetting<String>('custom_message_$userId');
      final customReview = await HiveService.getSetting<String>('custom_review_$userId');
      final customLearningPoints = await HiveService.getSetting<String>('custom_learning_$userId');
      final customGratitude = await HiveService.getSetting<String>('custom_gratitude_$userId');

      setState(() {
        _messageController.text = customMessage ?? _defaultMessage;
        _reviewController.text = customReview ?? _defaultReview;
        _learningPointsController.text = customLearningPoints ?? _defaultLearningPoints;
        _gratitudeController.text = customGratitude ?? _defaultGratitude;
      });
    } catch (e) {
      print('❌ Error loading custom messages: $e');
      // Use default content if loading fails
      setState(() {
        _messageController.text = _defaultMessage;
        _reviewController.text = _defaultReview;
        _learningPointsController.text = _defaultLearningPoints;
        _gratitudeController.text = _defaultGratitude;
      });
    }
  }

  // FIXED: Save custom messages to storage
  Future<void> _saveCustomMessages() async {
    try {
      final userId = UserService.getCurrentUserId();
      if (userId == null) return;

      await HiveService.saveSetting('custom_message_$userId', _messageController.text.trim());
      await HiveService.saveSetting('custom_review_$userId', _reviewController.text.trim());
      await HiveService.saveSetting('custom_learning_$userId', _learningPointsController.text.trim());
      await HiveService.saveSetting('custom_gratitude_$userId', _gratitudeController.text.trim());

      print('✅ Custom messages saved successfully');
    } catch (e) {
      print('❌ Error saving custom messages: $e');
      throw Exception('Gagal menyimpan pesan kustom');
    }
  }

  // FIXED: Reset to default content
  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(
              'Reset ke Default',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan semua pesan dan kesan ke konten default?',
          style: GoogleFonts.poppins(
            color: Colors.grey[700],
          ),
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messageController.text = _defaultMessage;
                _reviewController.text = _defaultReview;
                _learningPointsController.text = _defaultLearningPoints;
                _gratitudeController.text = _defaultGratitude;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Konten telah direset ke default',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.orange[600],
                ),
              );
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memilih gambar: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil foto: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Sumber Gambar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      'Kamera',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      'Galeri',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      String? imageUrl = _selectedImage?.path ?? _currentUser!.profileImage;

      // Update user profile
      final updatedUser = _currentUser!.copyWith(
        nama: _namaController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        alamat: _addressController.text.trim(),
        profileImage: imageUrl,
      );

      final userSuccess = await UserService.updateUser(updatedUser);
      
      // FIXED: Save custom messages
      await _saveCustomMessages();

      if (userSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Profil dan pesan berhasil diperbarui',
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
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _messageController.dispose();
    _reviewController.dispose();
    _learningPointsController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Profil',
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
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Image Section
              _buildProfileImageSection(),
              
              const SizedBox(height: 32),
              
              // Form Fields
              _buildFormFields(),
              
              const SizedBox(height: 32),
              
              // FIXED: Editable Mobile Programming Message Section
              _buildEditableMobileProgrammingSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
        children: [
          Text(
            'Foto Profil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 20),
          
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.teal[200]!,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : _currentUser?.profileImage.isNotEmpty == true
                        ? Image.network(
                            _currentUser!.profileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextButton.icon(
            onPressed: _showImageSourceDialog,
            icon: Icon(Icons.camera_alt, color: Colors.teal[600]),
            label: Text(
              'Ubah Foto',
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildFormFields() {
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
            'Informasi Profil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _namaController,
            label: 'Nama Lengkap',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama lengkap diperlukan';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username diperlukan';
              }
              if (value.trim().length < 3) {
                return 'Username minimal 3 karakter';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email diperlukan';
              }
              if (!value.contains('@')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _phoneController,
            label: 'Nomor Telepon',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nomor telepon diperlukan';
              }
              if (value.trim().length < 10) {
                return 'Nomor telepon minimal 10 digit';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _addressController,
            label: 'Alamat',
            icon: Icons.location_on,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alamat diperlukan';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: Colors.teal[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.teal[600]!,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }

  // FIXED: Editable Mobile Programming Section
  Widget _buildEditableMobileProgrammingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.teal[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Colors.teal[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mata Kuliah Mobile Programming',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ),
              IconButton(
                onPressed: _resetToDefault,
                icon: Icon(Icons.refresh, color: Colors.orange[600]),
                tooltip: 'Reset ke Default',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // FIXED: Editable Message Section
          Text(
            '📱 Pesan & Kesan (Editable)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _messageController,
            maxLines: 6,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Tulis pesan dan kesan Anda tentang mata kuliah Mobile Programming...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // FIXED: Editable Review Section
          Text(
            '🎯 Review Pembelajaran (Editable)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _reviewController,
            maxLines: 5,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Review detail tentang pembelajaran yang telah dilalui...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // FIXED: Editable Learning Points
          Text(
            '📚 Yang Dipelajari (Editable)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _learningPointsController,
            maxLines: 8,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            decoration: InputDecoration(
              hintText: 'Daftar materi yang dipelajari (gunakan • untuk bullet points)...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // FIXED: Editable Gratitude Section
          Text(
            '💝 Ucapan Terima Kasih (Editable)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _gratitudeController,
            maxLines: 4,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.teal[700],
            ),
            decoration: InputDecoration(
              hintText: 'Ucapan terima kasih kepada dosen dan yang terlibat...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              fillColor: Colors.teal[25],
              filled: true,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Helper Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Anda dapat mengedit semua bagian sesuai pengalaman pribadi. Gunakan tombol refresh untuk kembali ke konten default.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
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