part of 'khata_bloc.dart';

class KhataState extends Equatable {
  final List<Customer> customers;
  final List<KhataEntry> selectedEntries;
  final bool isLoading;
  final bool isLoadingEntries;
  final String? error;

  const KhataState({
    this.customers = const [],
    this.selectedEntries = const [],
    this.isLoading = false,
    this.isLoadingEntries = false,
    this.error,
  });

  /// Total outstanding balance across all customers.
  double get totalOutstanding =>
      customers.fold(0, (sum, c) => sum + c.balance);

  KhataState copyWith({
    List<Customer>? customers,
    List<KhataEntry>? selectedEntries,
    bool? isLoading,
    bool? isLoadingEntries,
    String? error,
    bool clearError = false,
  }) {
    return KhataState(
      customers: customers ?? this.customers,
      selectedEntries: selectedEntries ?? this.selectedEntries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingEntries: isLoadingEntries ?? this.isLoadingEntries,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [customers, selectedEntries, isLoading, isLoadingEntries, error];
}
