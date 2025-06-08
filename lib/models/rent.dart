import 'package:hive/hive.dart';

part 'rent.g.dart';

@HiveType(typeId: 2)
class Rent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String peralatanId;

  @HiveField(2)
  String peralatanNama;

  @HiveField(3)
  String userId;

  @HiveField(4)
  String userName;

  @HiveField(5)
  String userPhone;

  @HiveField(6)
  int quantity;

  @HiveField(7)
  int rentalDays;

  @HiveField(8)
  double pricePerDay;

  @HiveField(9)
  double totalPrice;

  @HiveField(10)
  DateTime startDate;

  @HiveField(11)
  DateTime endDate;

  @HiveField(12)
  DateTime bookingDate;

  @HiveField(13)
  DateTime? createdAt;

  @HiveField(14)
  String status; // 'pending', 'confirmed', 'active', 'completed', 'cancelled'

  @HiveField(15)
  String paymentStatus; // 'unpaid', 'dp', 'paid', 'refunded'

  @HiveField(16)
  double paidAmount;

  @HiveField(17)
  DateTime? paymentDate;

  Rent({
    required this.id,
    required this.peralatanId,
    required this.peralatanNama,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.quantity,
    required this.rentalDays,
    required this.pricePerDay,
    required this.totalPrice,
    required this.startDate,
    required this.endDate,
    required this.bookingDate,
    this.createdAt,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0.0,
    this.paymentDate,
  });

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peralatanId': peralatanId,
      'peralatanNama': peralatanNama,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'quantity': quantity,
      'rentalDays': rentalDays,
      'pricePerDay': pricePerDay,
      'totalPrice': totalPrice,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'bookingDate': bookingDate.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }

  /// Create instance from Map
  factory Rent.fromMap(Map<String, dynamic> map) {
    return Rent(
      id: map['id'] ?? '',
      peralatanId: map['peralatanId'] ?? '',
      peralatanNama: map['peralatanNama'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      quantity: map['quantity'] ?? 1,
      rentalDays: map['rentalDays'] ?? 1,
      pricePerDay: (map['pricePerDay'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now().add(Duration(days: 1)),
      bookingDate: map['bookingDate'] != null ? DateTime.parse(map['bookingDate']) : DateTime.now(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate']) : null,
    );
  }

  /// Copy with method
  Rent copyWith({
    String? id,
    String? peralatanId,
    String? peralatanNama,
    String? userId,
    String? userName,
    String? userPhone,
    int? quantity,
    int? rentalDays,
    double? pricePerDay,
    double? totalPrice,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? bookingDate,
    DateTime? createdAt,
    String? status,
    String? paymentStatus,
    double? paidAmount,
    DateTime? paymentDate,
  }) {
    return Rent(
      id: id ?? this.id,
      peralatanId: peralatanId ?? this.peralatanId,
      peralatanNama: peralatanNama ?? this.peralatanNama,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      quantity: quantity ?? this.quantity,
      rentalDays: rentalDays ?? this.rentalDays,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      totalPrice: totalPrice ?? this.totalPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bookingDate: bookingDate ?? this.bookingDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  @override
  String toString() {
    return 'Rent(id: \$id, peralatan: \$peralatanNama, user: \$userName, status: \$status, paid: \$paidAmount)';
  }
}
