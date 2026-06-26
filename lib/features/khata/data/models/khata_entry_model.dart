import 'package:hive/hive.dart';
import '../../domain/entities/khata_entry.dart';

part 'khata_entry_model.g.dart';

@HiveType(typeId: 5)
class KhataEntryModel extends KhataEntry {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String customerId;

  @override
  @HiveField(2)
  final double amount;

  /// Stored as int: 0 = credit, 1 = payment
  @HiveField(3)
  final int typeIndex;

  @override
  @HiveField(4)
  final DateTime date;

  @override
  @HiveField(5)
  final String note;

  @override
  @HiveField(6)
  final String? saleId;

  KhataEntryModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.typeIndex,
    required this.date,
    required this.note,
    this.saleId,
  }) : super(
          id: id,
          customerId: customerId,
          amount: amount,
          type: typeIndex == 0 ? KhataEntryType.credit : KhataEntryType.payment,
          date: date,
          note: note,
          saleId: saleId,
        );

  factory KhataEntryModel.fromEntity(KhataEntry e) => KhataEntryModel(
        id: e.id,
        customerId: e.customerId,
        amount: e.amount,
        typeIndex: e.type == KhataEntryType.credit ? 0 : 1,
        date: e.date,
        note: e.note,
        saleId: e.saleId,
      );
}
