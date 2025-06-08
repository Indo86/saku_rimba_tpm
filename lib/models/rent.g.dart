// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rent.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentAdapter extends TypeAdapter<Rent> {
  @override
  final int typeId = 2;

  @override
  Rent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rent(
      id: fields[0] as String,
      peralatanId: fields[1] as String,
      peralatanNama: fields[2] as String,
      userId: fields[3] as String,
      userName: fields[4] as String,
      userPhone: fields[5] as String,
      quantity: fields[6] as int,
      rentalDays: fields[7] as int,
      pricePerDay: fields[8] as double,
      totalPrice: fields[9] as double,
      startDate: fields[10] as DateTime,
      endDate: fields[11] as DateTime,
      bookingDate: fields[12] as DateTime,
      createdAt: fields[13] as DateTime?,
      status: fields[14] as String,
      paymentStatus: fields[15] as String,
      paidAmount: fields[16] as double,
      paymentDate: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Rent obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.peralatanId)
      ..writeByte(2)
      ..write(obj.peralatanNama)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.userName)
      ..writeByte(5)
      ..write(obj.userPhone)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.rentalDays)
      ..writeByte(8)
      ..write(obj.pricePerDay)
      ..writeByte(9)
      ..write(obj.totalPrice)
      ..writeByte(10)
      ..write(obj.startDate)
      ..writeByte(11)
      ..write(obj.endDate)
      ..writeByte(12)
      ..write(obj.bookingDate)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.paymentStatus)
      ..writeByte(16)
      ..write(obj.paidAmount)
      ..writeByte(17)
      ..write(obj.paymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
