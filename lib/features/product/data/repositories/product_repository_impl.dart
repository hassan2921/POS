import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      return Right(HiveDatabase.productBox.values.toList());
    } catch (_) {
      return Left(const CacheFailure('Failed to load products'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final box = HiveDatabase.productBox;
      // Linear scan — acceptable for typical product catalogs (<1000 items).
      // For very large catalogs, consider maintaining a barcode→id index map.
      for (final product in box.values) {
        if (product.barcode == barcode) return Right(product);
      }
      return Left(const CacheFailure('Product not found'));
    } catch (_) {
      return Left(const CacheFailure('Failed to search product'));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      await HiveDatabase.productBox
          .put(product.id, ProductModel.fromEntity(product));
      return const Right(null);
    } catch (_) {
      return Left(const CacheFailure('Failed to add product'));
    }
  }

  @override
  Future<Either<Failure, void>> bulkAddProducts(List<Product> products) async {
    try {
      final entries = {
        for (final p in products) p.id: ProductModel.fromEntity(p),
      };
      await HiveDatabase.productBox.putAll(entries);
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure('Failed to bulk add products'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      await HiveDatabase.productBox
          .put(product.id, ProductModel.fromEntity(product));
      return const Right(null);
    } catch (_) {
      return Left(const CacheFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await HiveDatabase.productBox.delete(id);
      return const Right(null);
    } catch (_) {
      return Left(const CacheFailure('Failed to delete product'));
    }
  }
}
