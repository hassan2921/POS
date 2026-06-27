import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/khata_entry.dart';
import '../../domain/usecases/khata_usecases.dart';

part 'khata_event.dart';
part 'khata_state.dart';

class KhataBloc extends Bloc<KhataEvent, KhataState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  final GetEntriesForCustomerUseCase getEntriesForCustomerUseCase;
  final AddKhataEntryUseCase addKhataEntryUseCase;

  KhataBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
    required this.getEntriesForCustomerUseCase,
    required this.addKhataEntryUseCase,
  }) : super(const KhataState()) {
    on<LoadKhataEvent>(_onLoad);
    on<AddCustomerEvent>(_onAddCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<LoadCustomerEntriesEvent>(_onLoadEntries);
    on<AddCreditEntryEvent>(_onAddCredit);
    on<AddPaymentEvent>(_onAddPayment);
    on<ClearCustomerEntriesEvent>(
        (_, emit) => emit(state.copyWith(selectedEntries: [])));
  }

  Future<void> _onLoad(
      LoadKhataEvent event, Emitter<KhataState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await getCustomersUseCase();
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (customers) =>
          emit(state.copyWith(isLoading: false, customers: customers)),
    );
  }

  Future<void> _onAddCustomer(
      AddCustomerEvent event, Emitter<KhataState> emit) async {
    final customer = Customer(
      id: const Uuid().v4(),
      name: event.name.trim(),
      phone: event.phone.trim(),
      balance: 0,
    );
    final result = await addCustomerUseCase(customer);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => add(LoadKhataEvent()),
    );
  }

  Future<void> _onDeleteCustomer(
      DeleteCustomerEvent event, Emitter<KhataState> emit) async {
    final result = await deleteCustomerUseCase(event.customerId);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => add(LoadKhataEvent()),
    );
  }

  Future<void> _onLoadEntries(
      LoadCustomerEntriesEvent event, Emitter<KhataState> emit) async {
    emit(state.copyWith(isLoadingEntries: true));
    final result = await getEntriesForCustomerUseCase(event.customerId);
    result.fold(
      (failure) => emit(state.copyWith(
          isLoadingEntries: false, error: failure.message)),
      (entries) => emit(state.copyWith(
          isLoadingEntries: false, selectedEntries: entries)),
    );
  }

  Future<void> _onAddCredit(
      AddCreditEntryEvent event, Emitter<KhataState> emit) async {
    final entry = KhataEntry(
      id: const Uuid().v4(),
      customerId: event.customerId,
      amount: event.amount,
      type: KhataEntryType.credit,
      date: DateTime.now(),
      note: event.note,
      saleId: event.saleId,
    );
    final result = await addKhataEntryUseCase(entry);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        add(LoadKhataEvent());
        add(LoadCustomerEntriesEvent(event.customerId));
      },
    );
  }

  Future<void> _onAddPayment(
      AddPaymentEvent event, Emitter<KhataState> emit) async {
    final entry = KhataEntry(
      id: const Uuid().v4(),
      customerId: event.customerId,
      amount: event.amount,
      type: KhataEntryType.payment,
      date: DateTime.now(),
      note: event.note,
    );
    final result = await addKhataEntryUseCase(entry);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        add(LoadKhataEvent());
        add(LoadCustomerEntriesEvent(event.customerId));
      },
    );
  }
}
