import 'package:get_it/get_it.dart';

// Product
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';

// Shop
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';

// Settings / Printer
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';

// Sales
import '../../features/sales/data/repositories/sale_repository_impl.dart';
import '../../features/sales/domain/repositories/sale_repository.dart';
import '../../features/sales/domain/usecases/sale_usecases.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';

// Dashboard
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Khata
import '../../features/khata/data/repositories/khata_repository_impl.dart';
import '../../features/khata/domain/repositories/khata_repository.dart';
import '../../features/khata/domain/usecases/khata_usecases.dart';
import '../../features/khata/presentation/bloc/khata_bloc.dart';

// Billing
import '../../features/billing/presentation/bloc/billing_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Billing ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(
    () => BillingBloc(
      getProductByBarcodeUseCase: sl(),
      updateProductUseCase: sl(),
      saveSaleUseCase: sl(),
    ),
  );

  // ── Product ───────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl());

  // ── Shop ──────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ShopBloc(getShopUseCase: sl(), updateShopUseCase: sl()),
  );
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));
  sl.registerLazySingleton<ShopRepository>(() => ShopRepositoryImpl());

  // ── Settings / Printer ───────────────────────────────────────────────
  sl.registerFactory(() => PrinterBloc(repository: sl()));
  sl.registerLazySingleton<PrinterRepository>(() => PrinterRepositoryImpl());

  // ── Sales ────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => SalesBloc(
      getAllSalesUseCase: sl(),
      saveSaleUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => SaveSaleUseCase(sl()));
  sl.registerLazySingleton(() => GetAllSalesUseCase(sl()));
  sl.registerLazySingleton(() => GetUnsyncedSalesUseCase(sl()));
  sl.registerLazySingleton(() => MarkSaleSyncedUseCase(sl()));
  sl.registerLazySingleton<SaleRepository>(() => SaleRepositoryImpl());

  // ── Dashboard ─────────────────────────────────────────────────────────
  sl.registerFactory(
    () => DashboardBloc(
      getAllSalesUseCase: sl(),
      getProductsUseCase: sl(),
    ),
  );

  // ── Khata ─────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => KhataBloc(
      getCustomersUseCase: sl(),
      addCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      deleteCustomerUseCase: sl(),
      getEntriesForCustomerUseCase: sl(),
      addKhataEntryUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetEntriesForCustomerUseCase(sl()));
  sl.registerLazySingleton(() => AddKhataEntryUseCase(sl()));
  sl.registerLazySingleton<KhataRepository>(() => KhataRepositoryImpl());
}

