part of 'sales_bloc.dart';

enum SalesStatus { initial, loading, loaded, error }

class SalesState extends Equatable {
  final SalesStatus status;
  final List<Sale> sales;
  final String? message;

  const SalesState({
    this.status = SalesStatus.initial,
    this.sales = const [],
    this.message,
  });

  SalesState copyWith({
    SalesStatus? status,
    List<Sale>? sales,
    String? message,
  }) {
    return SalesState(
      status: status ?? this.status,
      sales: sales ?? this.sales,
      message: message ?? this.message,
    );
  }

  double get totalRevenue => sales.fold(0, (sum, s) => sum + s.total);

  @override
  List<Object?> get props => [status, sales, message];
}
