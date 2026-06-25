import 'package:equatable/equatable.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final bool synced;

  const Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.synced = false,
  });

  Sale copyWith({
    String? id,
    DateTime? date,
    List<SaleItem>? items,
    double? total,
    bool? synced,
  }) {
    return Sale(
      id: id ?? this.id,
      date: date ?? this.date,
      items: items ?? this.items,
      total: total ?? this.total,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [id, date, items, total, synced];
}
