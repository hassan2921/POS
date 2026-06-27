import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../sales/domain/entities/sale.dart';
import '../../../sales/domain/usecases/sale_usecases.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/usecases/product_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetAllSalesUseCase getAllSalesUseCase;
  final GetProductsUseCase getProductsUseCase;

  List<Sale> _allSales = const [];
  List<Product> _allProducts = const [];
  bool _cacheValid = false;

  DashboardBloc({
    required this.getAllSalesUseCase,
    required this.getProductsUseCase,
  }) : super(const DashboardState()) {
    on<LoadDashboardEvent>(_onLoad);
    on<ChangePeriodEvent>(_onChangePeriod);
  }

  Future<void> _onLoad(
      LoadDashboardEvent event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    final salesResult = await getAllSalesUseCase(NoParams());
    final productsResult = await getProductsUseCase(NoParams());

    List<Sale>? sales;
    List<Product>? products;

    salesResult.fold(
      (failure) => emit(state.copyWith(
          status: DashboardStatus.error, error: failure.message)),
      (data) => sales = data,
    );

    productsResult.fold(
      (failure) => emit(state.copyWith(
          status: DashboardStatus.error, error: failure.message)),
      (data) => products = data,
    );

    if (sales == null || products == null) return;

    _allSales = sales!;
    _allProducts = products!;
    _cacheValid = true;

    _emitComputedState(emit, state.period);

    // Free the in-memory lists after computing — a business with thousands of
    // sales would otherwise hold them forever alongside the BLoC singleton.
    // Period changes will reload from Hive (fast, since Hive caches internally).
    _allSales = const [];
    _allProducts = const [];
    _cacheValid = false;
  }

  Future<void> _onChangePeriod(
      ChangePeriodEvent event, Emitter<DashboardState> emit) async {
    if (!_cacheValid) {
      emit(state.copyWith(status: DashboardStatus.loading));
      final salesResult = await getAllSalesUseCase(NoParams());
      final productsResult = await getProductsUseCase(NoParams());

      List<Sale>? sales;
      List<Product>? products;
      salesResult.fold(
        (f) => emit(state.copyWith(status: DashboardStatus.error, error: f.message)),
        (d) => sales = d,
      );
      productsResult.fold(
        (f) => emit(state.copyWith(status: DashboardStatus.error, error: f.message)),
        (d) => products = d,
      );
      if (sales == null || products == null) return;
      _allSales = sales!;
      _allProducts = products!;
      _cacheValid = true;
    }

    _emitComputedState(emit, event.period);

    _allSales = const [];
    _allProducts = const [];
    _cacheValid = false;
  }

  void _emitComputedState(Emitter<DashboardState> emit, DashboardPeriod period) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Filter sales by period
    late DateTime periodStart;
    switch (period) {
      case DashboardPeriod.today:
        periodStart = todayStart;
        break;
      case DashboardPeriod.week:
        periodStart = todayStart.subtract(const Duration(days: 6));
        break;
      case DashboardPeriod.month:
        periodStart = todayStart.subtract(const Duration(days: 29));
        break;
      case DashboardPeriod.all:
        periodStart = DateTime(2000);
        break;
    }

    final filteredSales =
        _allSales.where((s) => s.date.isAfter(periodStart) || _isSameDay(s.date, periodStart)).toList();

    // Summary stats
    final totalRevenue = filteredSales.fold<double>(0, (sum, s) => sum + s.total);
    final totalOrders = filteredSales.length;
    final averageOrderValue =
        totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final totalItemsSold = filteredSales.fold<int>(
        0, (sum, s) => sum + s.items.fold<int>(0, (is2, i) => is2 + i.quantity));

    // Daily revenue for chart
    final Map<String, DailyRevenue> dailyMap = {};

    // Pre-fill dates for the period to show zero-revenue days
    if (period != DashboardPeriod.all) {
      final int days;
      switch (period) {
        case DashboardPeriod.today:
          days = 1;
          break;
        case DashboardPeriod.week:
          days = 7;
          break;
        case DashboardPeriod.month:
          days = 30;
          break;
        case DashboardPeriod.all:
          days = 0;
          break;
      }
      for (int i = 0; i < days; i++) {
        final d = todayStart.subtract(Duration(days: days - 1 - i));
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        dailyMap[key] = DailyRevenue(date: d, revenue: 0, orderCount: 0);
      }
    }

    for (final sale in filteredSales) {
      final d = DateTime(sale.date.year, sale.date.month, sale.date.day);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final existing = dailyMap[key];
      if (existing != null) {
        dailyMap[key] = DailyRevenue(
          date: d,
          revenue: existing.revenue + sale.total,
          orderCount: existing.orderCount + 1,
        );
      } else {
        dailyMap[key] = DailyRevenue(
          date: d,
          revenue: sale.total,
          orderCount: 1,
        );
      }
    }

    final dailyRevenue = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Top selling products
    final Map<String, _ProductAccumulator> productMap = {};
    for (final sale in filteredSales) {
      for (final item in sale.items) {
        final acc = productMap.putIfAbsent(
          item.productId,
          () => _ProductAccumulator(item.productName),
        );
        acc.quantity += item.quantity;
        acc.revenue += item.total;
      }
    }
    final topProducts = productMap.entries
        .map((e) => TopProduct(
              productName: e.value.name,
              quantitySold: e.value.quantity,
              revenue: e.value.revenue,
            ))
        .toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    // Stock alerts
    const lowStockThreshold = 5;
    final lowStockCount = _allProducts
        .where((p) => p.stock > 0 && p.stock <= lowStockThreshold)
        .length;
    final outOfStockCount = _allProducts.where((p) => p.stock <= 0).length;

    emit(DashboardState(
      status: DashboardStatus.loaded,
      period: period,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      averageOrderValue: averageOrderValue,
      totalItemsSold: totalItemsSold,
      dailyRevenue: dailyRevenue,
      topProducts: topProducts.take(10).toList(),
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
    ));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ProductAccumulator {
  final String name;
  int quantity = 0;
  double revenue = 0;

  _ProductAccumulator(this.name);
}
