import 'package:equatable/equatable.dart';

enum KhataEntryType { credit, payment }

/// One line in a customer's khata ledger.
///
/// [credit] — goods given on udhaar (balance increases).
/// [payment] — customer paid back (balance decreases).
class KhataEntry extends Equatable {
  final String id;
  final String customerId;
  final double amount;
  final KhataEntryType type;
  final DateTime date;
  final String note;

  /// Optional: the sale ID that generated this credit entry.
  final String? saleId;

  const KhataEntry({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
    this.saleId,
  });

  @override
  List<Object?> get props => [id, customerId, amount, type, date, note, saleId];
}
