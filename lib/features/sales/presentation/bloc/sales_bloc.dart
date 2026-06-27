import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sale_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'sales_event.dart';
part 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final GetAllSalesUseCase getAllSalesUseCase;
  final SaveSaleUseCase saveSaleUseCase;

  SalesBloc({
    required this.getAllSalesUseCase,
    required this.saveSaleUseCase,
  }) : super(const SalesState()) {
    on<LoadSalesEvent>(_onLoad);
    on<SaveSaleEvent>(_onSave);
    on<ClearSalesEvent>((_, emit) => emit(const SalesState()));
  }

  Future<void> _onLoad(LoadSalesEvent event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    final result = await getAllSalesUseCase(NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(status: SalesStatus.error, message: failure.message)),
      (sales) =>
          emit(state.copyWith(status: SalesStatus.loaded, sales: sales)),
    );
  }

  Future<void> _onSave(SaveSaleEvent event, Emitter<SalesState> emit) async {
    await saveSaleUseCase(event.sale);
    add(LoadSalesEvent());
  }
}
