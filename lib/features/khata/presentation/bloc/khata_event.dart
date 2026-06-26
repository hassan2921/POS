part of 'khata_bloc.dart';

abstract class KhataEvent extends Equatable {
  const KhataEvent();
  @override
  List<Object?> get props => [];
}

class LoadKhataEvent extends KhataEvent {}

class AddCustomerEvent extends KhataEvent {
  final String name;
  final String phone;
  const AddCustomerEvent({required this.name, required this.phone});
  @override
  List<Object?> get props => [name, phone];
}

class DeleteCustomerEvent extends KhataEvent {
  final String customerId;
  const DeleteCustomerEvent(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class LoadCustomerEntriesEvent extends KhataEvent {
  final String customerId;
  const LoadCustomerEntriesEvent(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class AddCreditEntryEvent extends KhataEvent {
  final String customerId;
  final double amount;
  final String note;
  final String? saleId;
  const AddCreditEntryEvent({
    required this.customerId,
    required this.amount,
    required this.note,
    this.saleId,
  });
  @override
  List<Object?> get props => [customerId, amount, note, saleId];
}

class AddPaymentEvent extends KhataEvent {
  final String customerId;
  final double amount;
  final String note;
  const AddPaymentEvent({
    required this.customerId,
    required this.amount,
    required this.note,
  });
  @override
  List<Object?> get props => [customerId, amount, note];
}
