import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final String productId;
  final String productName;
  final String barcode;
  final int quantity;
  final double price;
  final double total;

  const SaleItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  List<Object?> get props =>
      [productId, productName, barcode, quantity, price, total];
}
