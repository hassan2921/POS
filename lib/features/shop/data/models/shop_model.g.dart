// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopModelAdapter extends TypeAdapter<ShopModel> {
  @override
  final int typeId = 1;

  @override
  ShopModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopModel(
      name: fields[0] as String,
      addressLine1: fields[1] as String,
      addressLine2: fields[2] as String,
      phoneNumber: fields[3] as String,
      footerText: fields[5] as String,
      jazzCashNumber: fields[6] as String? ?? '',
      easypaisaNumber: fields[7] as String? ?? '',
      nayapayNumber: fields[8] as String? ?? '',
      bankName: fields[9] as String? ?? '',
      bankAccountTitle: fields[10] as String? ?? '',
      bankAccountNumber: fields[11] as String? ?? '',
      bankIban: fields[12] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ShopModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.addressLine1)
      ..writeByte(2)
      ..write(obj.addressLine2)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.footerText)
      ..writeByte(6)
      ..write(obj.jazzCashNumber)
      ..writeByte(7)
      ..write(obj.easypaisaNumber)
      ..writeByte(8)
      ..write(obj.nayapayNumber)
      ..writeByte(9)
      ..write(obj.bankName)
      ..writeByte(10)
      ..write(obj.bankAccountTitle)
      ..writeByte(11)
      ..write(obj.bankAccountNumber)
      ..writeByte(12)
      ..write(obj.bankIban);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
