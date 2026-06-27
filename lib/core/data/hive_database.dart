import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  static const String _encryptionKeyName = 'hive_encryption_key';

  static HiveCipher? _cipher;

  static Future<void> init() async {
    await Hive.initFlutter();

    _cipher = await _loadOrCreateCipher();

    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(SaleItemModelAdapter()); // typeId: 3 — register before SaleModel
    Hive.registerAdapter(SaleModelAdapter());     // typeId: 2
    Hive.registerAdapter(CustomerModelAdapter()); // typeId: 4
    Hive.registerAdapter(KhataEntryModelAdapter()); // typeId: 5

    // Open boxes — settings is untyped to hold mixed primitives (String, bool, int).
    // Use _openEncryptedBox so that boxes from a pre-encryption build are deleted
    // and recreated rather than leaving the app in a broken state.
    await _openEncryptedBox<ProductModel>(productBoxName);
    await _openEncryptedBox<ShopModel>(shopBoxName);
    await _openEncryptedBox<SaleModel>(salesBoxName);
    await _openEncryptedDynBox(settingsBoxName);
    await _openEncryptedBox<CustomerModel>(customersBoxName);
    await _openEncryptedBox<KhataEntryModel>(khataEntriesBoxName);
  }

  /// Opens a typed box with AES encryption.
  /// If the box can't be opened (e.g. previously stored without encryption),
  /// it is deleted from disk and reopened fresh so the app doesn't crash.
  static Future<Box<T>> _openEncryptedBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: _cipher);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name, encryptionCipher: _cipher);
    }
  }

  /// Same as [_openEncryptedBox] but for the untyped settings box.
  static Future<Box> _openEncryptedDynBox(String name) async {
    try {
      return await Hive.openBox(name, encryptionCipher: _cipher);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox(name, encryptionCipher: _cipher);
    }
  }

  /// Loads the AES-256 key from secure storage, or generates and stores a new one.
  /// The key lives in the Android Keystore / iOS Keychain, separate from Hive files.
  static Future<HiveCipher> _loadOrCreateCipher() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    String? keyBase64 = await storage.read(key: _encryptionKeyName);
    if (keyBase64 == null) {
      final key = Uint8List(32);
      final random = Random.secure();
      for (int i = 0; i < 32; i++) {
        key[i] = random.nextInt(256);
      }
      keyBase64 = base64Url.encode(key);
      await storage.write(key: _encryptionKeyName, value: keyBase64);
    }

    return HiveAesCipher(base64Url.decode(keyBase64));
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
