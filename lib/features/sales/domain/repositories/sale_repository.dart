import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/sale.dart';

abstract class SaleRepository {
  Future<Either<Failure, void>> saveSale(Sale sale);
  Future<Either<Failure, List<Sale>>> getAllSales();
  Future<Either<Failure, List<Sale>>> getUnsyncedSales();
  Future<Either<Failure, void>> markSynced(String saleId);
  Future<Either<Failure, void>> deleteSale(String saleId);
}
