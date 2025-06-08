// services/UserService.dart (SakuRimba)
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HiveService.dart';

class UserService {
  static const String _loggedInUserKey = 'logged_in_user_sakurimba';
   
  // Cache untuk current user (untuk akses synchronous)
  static String? _currentUsername;  
  static User? _currentUser;

  // Helper method untuk check essential boxes
  static bool _areEssentialBoxesOpen() {
    try {
      return Hive.isBoxOpen('users') && 
             Hive.isBoxOpen('user_objects') && 
             Hive.isBoxOpen('rentals') &&
             Hive.isBoxOpen('notifications');
    } catch (e) {
      print('❌ Error checking boxes: $e');
      return false;
    }
  }

  // Initialize current user dari SharedPreferences
  static Future<void> initCurrentUser() async {
    try {
      print('🚀 Initializing UserService for SakuRimba...');
      
      // Pastikan HiveService sudah terinisialisasi
      if (!_areEssentialBoxesOpen()) {
        print('📦 Essential boxes not open, initializing HiveService...');
        await HiveService.init();
      }

      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString(_loggedInUserKey);
      
      if (_currentUsername != null) {
        print('👤 Found saved username: $_currentUsername');
        
        // Load user dari Hive
        _currentUser = await HiveService.getUser(_currentUsername!);
        if (_currentUser != null) {
          print('✅ User loaded from Hive: ${_currentUser!.username}');
        } else {
          print('⚠️ User not found in Hive, creating new user object');
          // Jika user tidak ada di Hive, buat user baru
          _currentUser = User(
            username: _currentUsername!,
            passwordHash: '',
            nama: '',
            email: '',
            phone: '',
            alamat: '',
            profileImage: '',
            saran: '',
            kesan: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await HiveService.saveUser(_currentUser!);
        }
      } else {
        print('ℹ️ No saved username found');
        _currentUser = null;
      }
    } catch (e) {
      print('❌ Error initializing current user: $e');
      _currentUsername = null;
      _currentUser = null;
    }
  }

  // Get users box menggunakan HiveService
  static Future<Box<User>> getUserBox() async {
    return await HiveService.getUserBox();
  }

  // Get current logged in user (synchronous)
  static User? getCurrentUser() {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      if (_currentUsername == null) return null;
      
      if (!_areEssentialBoxesOpen()) {
        print('⚠️ Warning: Essential boxes not open yet');
        return null;
      }
      
      final box = HiveService.getUserBoxSync();
      _currentUser = box.get(_currentUsername);
      return _currentUser;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Async version of getCurrentUser
  static Future<User?> getCurrentUserAsync() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      if (_currentUsername == null) return null;
      
      final box = await HiveService.getUserBox();
      _currentUser = box.get(_currentUsername);
      return _currentUser;
    } catch (e) {
      print('❌ Error getting current user async: $e');
      return null;
    }
  }

  // Set current logged in user
  static Future<void> setCurrentUser(User user) async {
    try {
      print('🔐 Setting current user: ${user.username}');
      
      // Pastikan HiveService terinisialisasi
      if (!_areEssentialBoxesOpen()) {
        await HiveService.init();
      }

      // Gunakan HiveService untuk menyimpan user
      await HiveService.saveUser(user);
      
      // Simpan info user yang sedang login di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loggedInUserKey, user.username);
      
      // Update cache
      _currentUsername = user.username;
      _currentUser = user;
      
      print('✅ Current user set successfully: ${user.username}');
    } catch (e) {
      print('❌ Error setting current user: $e');
      rethrow;
    }
  }

  // Clear current logged in user (logout)
  static Future<void> clearCurrentUser() async {
    try {
      print('🚪 Clearing current user...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedInUserKey);
      
      // Clear cache
      _currentUsername = null;
      _currentUser = null;
      
      print('✅ Current user cleared successfully');
    } catch (e) {
      print('❌ Error clearing current user: $e');
    }
  }

  // Check if user is logged in
  static bool isUserLoggedIn() {
    try {
      if (_currentUsername == null) return false;
      if (!_areEssentialBoxesOpen()) return false;
      
      // Check if user exists in Hive
      final userExists = HiveService.getUserBoxSync().containsKey(_currentUsername);
      
      // Check if password exists (untuk validasi ekstra)
      final passwordExists = HiveService.passwordExists(_currentUsername!);
      
      final isLoggedIn = userExists && passwordExists;
      print('🔍 User login check: username=$_currentUsername, userExists=$userExists, passwordExists=$passwordExists, result=$isLoggedIn');
      
      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking if user is logged in: $e');
      return false;
    }
  }

  // Get current user username (untuk FavoriteService)
  static String? getCurrentUsername() {
    return _currentUsername;
  }

  // Get current user ID untuk rental system
  static String? getCurrentUserId() {
    return _currentUsername; // Username sebagai user ID
  }

  // Hash password menggunakan SHA256
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user dengan enkripsi password
  static Future<bool> registerUser(String username, String password, {
    String nama = '',
    String email = '',
    String phone = '',
    String alamat = '',
    String profileImage = '',
  }) async {
    try {
      print('📝 Registering user: $username');
      
      final box = await getUserBox();
      
      // Check if username already exists
      if (box.containsKey(username)) {
        print('❌ Username already exists: $username');
        return false;
      }
      
      // Check if password username already exists
      if (HiveService.passwordExists(username)) {
        print('❌ Password username already exists: $username');
        return false;
      }
      
      // Hash password
      final passwordHash = hashPassword(password);
      
      // Create user object
      final user = User(
        username: username,
        passwordHash: passwordHash,
        nama: nama,
        email: email,
        phone: phone,
        alamat: alamat,
        profileImage: profileImage,
        saran: '',
        kesan: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save user menggunakan HiveService
      await HiveService.saveUser(user);
      
      // Save password hash in password box for compatibility
      await HiveService.savePassword(username, passwordHash);
      
      print('✅ User registered successfully: $username');
      return true;
    } catch (e) {
      print('❌ Error registering user: $e');
      return false;
    }
  }

  // Login user dengan validasi lengkap dan enkripsi
  static Future<User?> loginUser(String username, String password) async {
    try {
      print('🔐 Attempting login: $username');
      
      // Pastikan HiveService terinisialisasi
      if (!_areEssentialBoxesOpen()) {
        await HiveService.init();
      }

      // Hash password yang diberikan
      final passwordHash = hashPassword(password);
      
      // Cek password dari box password (existing system) menggunakan HiveService
      if (!HiveService.passwordExists(username)) {
        print('❌ Username not found in password box: $username');
        return null;
      }
      
      String? storedPasswordHash = HiveService.getPassword(username);
      if (storedPasswordHash == null || passwordHash != storedPasswordHash) {
        print('❌ Password mismatch for user: $username');
        return null;
      }

      print('✅ Password validated for user: $username');

      // Ambil atau buat User object menggunakan HiveService
      User? user = await HiveService.getUser(username);
      
      if (user == null) {
        print('📝 Creating new User object for: $username');
        // Buat User object baru jika belum ada
        user = User(
          username: username,
          passwordHash: passwordHash,
          nama: '',
          email: '',
          phone: '',
          alamat: '',
          profileImage: '',
          saran: '',
          kesan: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await HiveService.saveUser(user);
      }
      
      // Set sebagai current user
      await setCurrentUser(user);
      print('✅ Login successful for user: $username');
      return user;
    } catch (e) {
      print('❌ Error during login: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUser(User updatedUser) async {
    try {
      print('📝 Updating user: ${updatedUser.username}');
      
      // Update timestamp
      updatedUser.updatedAt = DateTime.now();
      
      // Update menggunakan HiveService
      await HiveService.updateUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUsername == updatedUser.username) {
        _currentUser = updatedUser;
        await setCurrentUser(updatedUser);
      }
      
      print('✅ User updated successfully: ${updatedUser.username}');
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  // Update user profile image
  static Future<bool> updateProfileImage(String imagePath) async {
    try {
      if (_currentUser == null) {
        print('❌ No current user to update profile image');
        return false;
      }
      
      final updatedUser = _currentUser!.copyWith(
        profileImage: imagePath,
        updatedAt: DateTime.now(),
      );
      
      return await updateUser(updatedUser);
    } catch (e) {
      print('❌ Error updating profile image: $e');
      return false;
    }
  }

  // Update saran dan kesan
  static Future<bool> updateSaranKesan(String saran, String kesan) async {
    try {
      if (_currentUser == null) {
        print('❌ No current user to update saran kesan');
        return false;
      }
      
      final updatedUser = _currentUser!.copyWith(
        saran: saran,
        kesan: kesan,
        updatedAt: DateTime.now(),
      );
      
      return await updateUser(updatedUser);
    } catch (e) {
      print('❌ Error updating saran kesan: $e');
      return false;
    }
  }

  // Change password
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      if (_currentUser == null) {
        print('❌ No current user to change password');
        return false;
      }
      
      // Verify old password
      final oldPasswordHash = hashPassword(oldPassword);
      if (oldPasswordHash != _currentUser!.passwordHash) {
        print('❌ Old password mismatch');
        return false;
      }
      
      // Hash new password
      final newPasswordHash = hashPassword(newPassword);
      
      // Update user object
      final updatedUser = _currentUser!.copyWith(
        passwordHash: newPasswordHash,
        updatedAt: DateTime.now(),
      );
      
      // Update in Hive
      await updateUser(updatedUser);
      
      // Update password box
      await HiveService.savePassword(_currentUser!.username, newPasswordHash);
      
      print('✅ Password changed successfully');
      return true;
    } catch (e) {
      print('❌ Error changing password: $e');
      return false;
    }
  }

  // Get all users (untuk admin/debugging)
  static Future<List<User>> getAllUsers() async {
    try {
      return await HiveService.getAllUsers();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Delete user
  static Future<bool> deleteUser(String username) async {
    try {
      print('🗑️ Deleting user: $username');
      
      // If deleting current user, logout first
      if (_currentUsername == username) {
        await clearCurrentUser();
      }
      
      // Delete menggunakan HiveService (akan menghapus user dan related data)
      await HiveService.deleteUser(username);
      
      // Delete password juga
      final passwordBox = HiveService.getPasswordBox();
      await passwordBox.delete(username);
      
      print('✅ User deleted successfully: $username');
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  // Check if username exists
  static Future<bool> usernameExists(String username) async {
    try {
      final box = await getUserBox();
      final userExists = box.containsKey(username);
      final passwordExists = HiveService.passwordExists(username);
      
      // Username exists jika ada di salah satu box
      return userExists || passwordExists;
    } catch (e) {
      print('❌ Error checking username: $e');
      return false;
    }
  }

  // Get user profile data
  static Future<User?> getUserProfile(String username) async {
    try {
      return await HiveService.getUser(username);
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  static Future<User?> getCurrentUserProfile() async {
    if (_currentUsername == null) return null;
    return await getUserProfile(_currentUsername!);
  }

  // Validate current session
  static Future<bool> validateCurrentSession() async {
    try {
      if (_currentUsername == null) {
        print('ℹ️ No current username in cache');
        return false;
      }

      // Check if user still exists in both boxes
      final userExists = await HiveService.getUser(_currentUsername!) != null;
      final passwordExists = HiveService.passwordExists(_currentUsername!);
      
      if (!userExists || !passwordExists) {
        print('⚠️ Session invalid: user or password missing');
        await clearCurrentUser();
        return false;
      }

      print('✅ Session valid for user: $_currentUsername');
      return true;
    } catch (e) {
      print('❌ Error validating session: $e');
      await clearCurrentUser();
      return false;
    }
  }

  // Refresh current user data
  static Future<void> refreshCurrentUser() async {
    try {
      if (_currentUsername == null) return;
      
      _currentUser = await HiveService.getUser(_currentUsername!);
      print('🔄 Current user refreshed: $_currentUsername');
    } catch (e) {
      print('❌ Error refreshing current user: $e');
    }
  }

  // Method untuk validasi akses rental
  static bool canAccessRental(String rentalUserId) {
    return _currentUsername == rentalUserId;
  }

  // Method untuk get safe current user ID
  static Future<String?> getCurrentUserIdSafe() async {
    await initCurrentUser();
    return getCurrentUserId();
  }

  // Get user profile completion percentage
  static double getUserProfileCompletion() {
    if (_currentUser == null) return 0.0;
    
    int filledFields = 0;
    int totalFields = 6; // nama, email, phone, alamat, profileImage, saran/kesan
    
    if (_currentUser!.nama.isNotEmpty) filledFields++;
    if (_currentUser!.email.isNotEmpty) filledFields++;
    if (_currentUser!.phone.isNotEmpty) filledFields++;
    if (_currentUser!.alamat.isNotEmpty) filledFields++;
    if (_currentUser!.profileImage.isNotEmpty) filledFields++;
    if (_currentUser!.saran.isNotEmpty || _currentUser!.kesan.isNotEmpty) filledFields++;
    
    return (filledFields / totalFields) * 100;
  }

  // Check if profile is complete
  static bool isProfileComplete() {
    return getUserProfileCompletion() >= 80.0; // 80% completion threshold
  }

  // Get formatted user display name
  static String getUserDisplayName() {
    if (_currentUser == null) return 'Guest';
    if (_currentUser!.nama.isNotEmpty) return _currentUser!.nama;
    return _currentUser!.username;
  }

  // Debug methods
  static Future<void> printUserDebug() async {
    try {
      print('🔍 === USER SERVICE DEBUG (SakuRimba) ===');
      print('Current username: $_currentUsername');
      print('Current user cached: ${_currentUser?.username}');
      print('Is logged in: ${isUserLoggedIn()}');
      print('Profile completion: ${getUserProfileCompletion()}%');
      
      if (_currentUsername != null) {
        final userInHive = await HiveService.getUser(_currentUsername!);
        final passwordExists = HiveService.passwordExists(_currentUsername!);
        print('User in Hive: ${userInHive?.username}');
        print('Password exists: $passwordExists');
        print('Profile image: ${userInHive?.profileImage}');
        print('Saran: ${userInHive?.saran}');
        print('Kesan: ${userInHive?.kesan}');
      }
      
      final allUsers = await HiveService.getAllUsers();
      print('Total users in Hive: ${allUsers.length}');
      for (var user in allUsers) {
        print('  - ${user.username} (${user.nama})');
      }
      print('==============================');
    } catch (e) {
      print('❌ Error in user debug: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final allUsers = await HiveService.getAllUsers();
      final passwordBox = HiveService.getPasswordBox();
      
      return {
        'totalUsers': allUsers.length,
        'totalPasswords': passwordBox.length,
        'currentUser': _currentUsername,
        'isLoggedIn': isUserLoggedIn(),
        'profileCompletion': getUserProfileCompletion(),
        'isProfileComplete': isProfileComplete(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {};
    }
  }
}