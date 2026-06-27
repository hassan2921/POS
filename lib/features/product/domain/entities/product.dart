import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final int stock;
  /// Unit label shown on receipts/cart (e.g. 'kg', 'pcs'). Empty = no unit displayed.
  final String unit;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.stock = 0,
    this.unit = '',
  });

  @override
  List<Object?> get props => [id, name, barcode, price, stock, unit];
}
