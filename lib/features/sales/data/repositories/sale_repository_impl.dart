import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  @override
  Future<Either<Failure, void>> saveSale(Sale sale) async {
    try {
      final box = HiveDatabase.salesBox;
      final model = SaleModel.fromEntity(sale);
      await box.put(sale.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Sale>>> getAllSales() async {
    try {
      final box = HiveDatabase.salesBox;
      // Return newest first
      final sales = box.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Right(sales);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Sale>>> getUnsyncedSales() async {
    try {
      final box = HiveDatabase.salesBox;
      final unsynced = box.values.where((s) => !s.synced).toList();
      return Right(unsynced);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markSynced(String saleId) async {
    try {
      final box = HiveDatabase.salesBox;
      final sale = box.get(saleId);
      if (sale != null) {
        final updated = SaleModel.fromEntity(sale.copyWith(synced: true));
        await box.put(saleId, updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSale(String saleId) async {
    try {
      await HiveDatabase.salesBox.delete(saleId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
