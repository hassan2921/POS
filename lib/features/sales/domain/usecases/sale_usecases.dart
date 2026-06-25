import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class SaveSaleUseCase implements UseCase<void, Sale> {
  final SaleRepository repository;
  SaveSaleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Sale params) =>
      repository.saveSale(params);
}

class GetAllSalesUseCase implements UseCase<List<Sale>, NoParams> {
  final SaleRepository repository;
  GetAllSalesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Sale>>> call(NoParams params) =>
      repository.getAllSales();
}

class GetUnsyncedSalesUseCase implements UseCase<List<Sale>, NoParams> {
  final SaleRepository repository;
  GetUnsyncedSalesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Sale>>> call(NoParams params) =>
      repository.getUnsyncedSales();
}

class MarkSaleSyncedUseCase implements UseCase<void, String> {
  final SaleRepository repository;
  MarkSaleSyncedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) =>
      repository.markSynced(params);
}
