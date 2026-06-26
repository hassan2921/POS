// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'khata_entry_model.dart';

class KhataEntryModelAdapter extends TypeAdapter<KhataEntryModel> {
  @override
  final int typeId = 5;

  @override
  KhataEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KhataEntryModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      amount: fields[2] as double,
      typeIndex: fields[3] as int,
      date: fields[4] as DateTime,
      note: fields[5] as String,
      saleId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KhataEntryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.saleId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KhataEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
