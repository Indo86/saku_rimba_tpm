// models/user.dart (SakuRimba)
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String passwordHash;

  @HiveField(2)
  String nama;

  @HiveField(3)
  String email;

  @HiveField(4)
  String phone;

  @HiveField(5)
  String alamat;

  @HiveField(6)
  String profileImage;

  @HiveField(7)
  String saran;

  @HiveField(8)
  String kesan;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  User({
    required this.username,
    required this.passwordHash,
    this.nama = '',
    this.email = '',
    this.phone = '',
    this.alamat = '',
    this.profileImage = '',
    this.saran = '',
    this.kesan = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'nama': nama,
      'email': email,
      'phone': phone,
      'alamat': alamat,
      'profileImage': profileImage,
      'saran': saran,
      'kesan': kesan,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create instance from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      alamat: map['alamat'] ?? '',
      profileImage: map['profileImage'] ?? '',
      saran: map['saran'] ?? '',
      kesan: map['kesan'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  /// Copy with method for easy updates
  User copyWith({
    String? username,
    String? passwordHash,
    String? nama,
    String? email,
    String? phone,
    String? alamat,
    String? profileImage,
    String? saran,
    String? kesan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alamat: alamat ?? this.alamat,
      profileImage: profileImage ?? this.profileImage,
      saran: saran ?? this.saran,
      kesan: kesan ?? this.kesan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (prefer nama over username)
  String get displayName {
    return nama.isNotEmpty ? nama : username;
  }

  /// Get initials for avatar
  String get initials {
    final name = displayName;
    if (name.isEmpty) return 'U';
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return nama.isNotEmpty && 
           email.isNotEmpty && 
           phone.isNotEmpty && 
           alamat.isNotEmpty;
  }

  /// Get profile completion percentage
  double get profileCompletionPercentage {
    int filledFields = 0;
    const totalFields = 6; // nama, email, phone, alamat, profileImage, saran/kesan
    
    if (nama.isNotEmpty) filledFields++;
    if (email.isNotEmpty) filledFields++;
    if (phone.isNotEmpty) filledFields++;
    if (alamat.isNotEmpty) filledFields++;
    if (profileImage.isNotEmpty) filledFields++;
    if (saran.isNotEmpty || kesan.isNotEmpty) filledFields++;
    
    return (filledFields / totalFields) * 100;
  }

  /// Validate email format
  bool get isEmailValid {
    if (email.isEmpty) return true; // Empty is considered valid (optional field)
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone format
  bool get isPhoneValid {
    if (phone.isEmpty) return true; // Empty is considered valid (optional field)
    return RegExp(r'^[0-9+]{10,15}$').hasMatch(phone);
  }

  /// Get account age in days
  int get accountAgeDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted last update date
  String get formattedUpdatedDate {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  /// Check if recently updated (within last 24 hours)
  bool get isRecentlyUpdated {
    return DateTime.now().difference(updatedAt).inHours < 24;
  }

  /// Get user summary for display
  Map<String, dynamic> get summary {
    return {
      'username': username,
      'displayName': displayName,
      'initials': initials,
      'isProfileComplete': isProfileComplete,
      'profileCompletionPercentage': profileCompletionPercentage,
      'accountAgeDays': accountAgeDays,
      'isRecentlyUpdated': isRecentlyUpdated,
      'hasProfileImage': profileImage.isNotEmpty,
      'hasContactInfo': email.isNotEmpty || phone.isNotEmpty,
    };
  }

  /// Validate user data
  List<String> validate() {
    final List<String> errors = [];
    
    if (username.isEmpty) {
      errors.add('Username tidak boleh kosong');
    } else if (username.length < 3) {
      errors.add('Username minimal 3 karakter');
    } else if (username.length > 20) {
      errors.add('Username maksimal 20 karakter');
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      errors.add('Username hanya boleh huruf, angka, dan underscore');
    }
    
    if (passwordHash.isEmpty) {
      errors.add('Password hash tidak boleh kosong');
    }
    
    if (nama.isNotEmpty && nama.length < 2) {
      errors.add('Nama minimal 2 karakter');
    }
    
    if (!isEmailValid) {
      errors.add('Format email tidak valid');
    }
    
    if (!isPhoneValid) {
      errors.add('Format nomor telepon tidak valid');
    }
    
    return errors;
  }

  /// Check if user data is valid
  bool get isValid {
    return validate().isEmpty;
  }

  /// Sanitize user input
  User sanitize() {
    return copyWith(
      username: username.trim().toLowerCase(),
      nama: nama.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      alamat: alamat.trim(),
      saran: saran.trim(),
      kesan: kesan.trim(),
    );
  }

  /// Update timestamp
  User touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nama': nama,
      'email': email,
      'phone': phone,
      'alamat': alamat,
      'profileImage': profileImage,
      'saran': saran,
      'kesan': kesan,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileCompletionPercentage': profileCompletionPercentage,
      'accountAgeDays': accountAgeDays,
    };
  }

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      passwordHash: '', // Don't include password hash in JSON
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      alamat: json['alamat'] ?? '',
      profileImage: json['profileImage'] ?? '',
      saran: json['saran'] ?? '',
      kesan: json['kesan'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'User(username: $username, nama: $nama, email: $email, profileComplete: $isProfileComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}