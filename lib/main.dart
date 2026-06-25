import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routes/app_routes.dart';
import 'core/data/hive_database.dart';
import 'core/service_locator.dart' as di;
import 'core/service/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/sales/presentation/bloc/sales_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();
  await di.init();
  SyncService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
          create: (_) => di.sl<ProductBloc>()..add(LoadProducts()),
        ),
        BlocProvider<ShopBloc>(
          create: (_) => di.sl<ShopBloc>()..add(LoadShopEvent()),
        ),
        BlocProvider<BillingBloc>(
          create: (_) => di.sl<BillingBloc>(),
        ),
        BlocProvider<PrinterBloc>(
          create: (_) => di.sl<PrinterBloc>()..add(InitPrinterEvent()),
        ),
        BlocProvider<SalesBloc>(
          create: (_) => di.sl<SalesBloc>()..add(LoadSalesEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Billing App',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
