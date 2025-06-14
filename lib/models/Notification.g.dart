// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationAdapter extends TypeAdapter<Notification> {
  @override
  final int typeId = 3;

  @override
  Notification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Notification(
      id: fields[0] as String,
      userId: fields[1] as String,
      title: fields[2] as String,
      message: fields[3] as String,
      type: fields[4] as String,
      priority: fields[5] as String,
      isRead: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      readAt: fields[8] as DateTime?,
      data: fields[9] as Map<String, dynamic>?,
      actionType: fields[10] as String?,
      actionData: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Notification obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.readAt)
      ..writeByte(9)
      ..write(obj.data)
      ..writeByte(10)
      ..write(obj.actionType)
      ..writeByte(11)
      ..write(obj.actionData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}