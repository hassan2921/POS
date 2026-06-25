part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, error }

enum DashboardPeriod { today, week, month, all }

class TopProduct extends Equatable {
  final String productName;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  @override
  List<Object?> get props => [productName, quantitySold, revenue];
}

class DailyRevenue extends Equatable {
  final DateTime date;
  final double revenue;
  final int orderCount;

  const DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  @override
  List<Object?> get props => [date, revenue, orderCount];
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardPeriod period;
  final String? error;

  // Summary stats
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int totalItemsSold;

  // Chart data
  final List<DailyRevenue> dailyRevenue;

  // Top products
  final List<TopProduct> topProducts;

  // Stock alerts
  final int lowStockCount;
  final int outOfStockCount;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.period = DashboardPeriod.week,
    this.error,
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.averageOrderValue = 0,
    this.totalItemsSold = 0,
    this.dailyRevenue = const [],
    this.topProducts = const [],
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardPeriod? period,
    String? error,
    double? totalRevenue,
    int? totalOrders,
    double? averageOrderValue,
    int? totalItemsSold,
    List<DailyRevenue>? dailyRevenue,
    List<TopProduct>? topProducts,
    int? lowStockCount,
    int? outOfStockCount,
  }) {
    return DashboardState(
      status: status ?? this.status,
      period: period ?? this.period,
      error: error ?? this.error,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      topProducts: topProducts ?? this.topProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      outOfStockCount: outOfStockCount ?? this.outOfStockCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        period,
        error,
        totalRevenue,
        totalOrders,
        averageOrderValue,
        totalItemsSold,
        dailyRevenue,
        topProducts,
        lowStockCount,
        outOfStockCount,
      ];
}
