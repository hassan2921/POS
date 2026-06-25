import 'package:hive/hive.dart';
import '../../domain/entities/sale.dart';
import 'sale_item_model.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 2)
class SaleModel extends Sale {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<SaleItemModel> itemModels;

  @override
  @HiveField(3)
  final double total;

  @override
  @HiveField(4)
  final bool synced;

  SaleModel({
    required this.id,
    required this.date,
    required this.itemModels,
    required this.total,
    this.synced = false,
  }) : super(
          id: id,
          date: date,
          items: itemModels,
          total: total,
          synced: synced,
        );

  factory SaleModel.fromEntity(Sale sale) => SaleModel(
        id: sale.id,
        date: sale.date,
        itemModels:
            sale.items.map((i) => SaleItemModel.fromEntity(i)).toList(),
        total: sale.total,
        synced: sale.synced,
      );
}
