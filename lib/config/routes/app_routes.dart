import 'package:go_router/go_router.dart';

import '../../features/billing/presentation/pages/pin_page.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';

import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';

import '../../features/shop/presentation/pages/shop_details_page.dart';

import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/change_pin_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

import '../../features/sales/presentation/pages/sales_history_page.dart';

import '../../features/product/domain/entities/product.dart';

final router = GoRouter(
  initialLocation: '/pin',
  routes: [
    // PIN LOGIN / SETUP
    GoRoute(
      path: '/pin',
      builder: (context, state) => const PinPage(),
    ),

    // CHANGE PIN (from settings)
    GoRoute(
      path: '/change-pin',
      builder: (context, state) => const ChangePinPage(),
    ),

    // HOME
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'scanner',
          builder: (context, state) => const ScannerPage(),
        ),
        GoRoute(
          path: 'checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    ),

    // SETTINGS
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // PRODUCTS
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product == null) return const ProductListPage();
            return EditProductPage(product: product);
          },
        ),
      ],
    ),

    // SHOP
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),

    // SALES HISTORY
    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesHistoryPage(),
    ),

    // SCANNER (global, used from product pages too)
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),
  ],
);
