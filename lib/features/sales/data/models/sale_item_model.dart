import 'package:hive/hive.dart';
import '../../domain/entities/sale_item.dart';

part 'sale_item_model.g.dart';

@HiveType(typeId: 3)
class SaleItemModel extends SaleItem {
  @override
  @HiveField(0)
  final String productId;

  @override
  @HiveField(1)
  final String productName;

  @override
  @HiveField(2)
  final String barcode;

  @override
  @HiveField(3)
  final int quantity;

  @override
  @HiveField(4)
  final double price;

  @override
  @HiveField(5)
  final double total;

  const SaleItemModel({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.price,
    required this.total,
  }) : super(
          productId: productId,
          productName: productName,
          barcode: barcode,
          quantity: quantity,
          price: price,
          total: total,
        );

  factory SaleItemModel.fromEntity(SaleItem item) => SaleItemModel(
        productId: item.productId,
        productName: item.productName,
        barcode: item.barcode,
        quantity: item.quantity,
        price: item.price,
        total: item.total,
      );
}
