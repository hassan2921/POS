part of 'sales_bloc.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();
  @override
  List<Object?> get props => [];
}

class LoadSalesEvent extends SalesEvent {}

class SaveSaleEvent extends SalesEvent {
  final Sale sale;
  const SaveSaleEvent(this.sale);
  @override
  List<Object?> get props => [sale];
}

class ClearSalesEvent extends SalesEvent {}
