import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/sales/data/models/sale_model.dart';
import '../../features/sales/data/models/sale_item_model.dart';
import '../../features/khata/data/models/customer_model.dart';
import '../../features/khata/data/models/khata_entry_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String salesBoxName = 'sales';
  static const String customersBoxName = 'customers';
  static const String khataEntriesBoxName = 'khata_entries';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(SaleItemModelAdapter()); // typeId: 3 — register before SaleModel
    Hive.registerAdapter(SaleModelAdapter());     // typeId: 2
    Hive.registerAdapter(CustomerModelAdapter()); // typeId: 4
    Hive.registerAdapter(KhataEntryModelAdapter()); // typeId: 5

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox<SaleModel>(salesBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<CustomerModel>(customersBoxName);
    await Hive.openBox<KhataEntryModel>(khataEntriesBoxName);
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box<SaleModel> get salesBox => Hive.box<SaleModel>(salesBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<CustomerModel> get customersBox =>
      Hive.box<CustomerModel>(customersBoxName);
  static Box<KhataEntryModel> get khataEntriesBox =>
      Hive.box<KhataEntryModel>(khataEntriesBoxName);
}
