import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/hive_database.dart';
import '../../features/sales/data/models/sale_model.dart';

/// SyncService listens for internet connectivity and syncs
/// any unsynced local sales to the backend when online.
///
/// WIRING INSTRUCTIONS:
/// 1. Add `connectivity_plus` to pubspec.yaml
/// 2. Replace the `_uploadSale` stub with your real API call
/// 3. Call `SyncService.instance.init()` in main() after HiveDatabase.init()
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  StreamSubscription? _subscription;
  bool _isSyncing = false;

  /// Call once at app startup
  void init() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _syncPendingSales();
      }
    });

    // Also attempt sync on startup in case already online
    _trySyncOnStartup();
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _trySyncOnStartup() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline = result.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      await _syncPendingSales();
    }
  }

  Future<void> _syncPendingSales() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final box = HiveDatabase.salesBox;
      final unsynced = box.values.where((s) => !s.synced).toList();

      for (final sale in unsynced) {
        final success = await _uploadSale(sale);
        if (success) {
          final updated = SaleModel.fromEntity(sale.copyWith(synced: true));
          await box.put(sale.id, updated);
        }
      }
    } catch (_) {
      // Silent — will retry on next connectivity event
    } finally {
      _isSyncing = false;
    }
  }

  /// -------------------------------------------------------------------
  /// STUB: Replace with your actual API call.
  ///
  /// Example with http:
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('https://your-api.com/api/sales'),
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode({
  ///     'id': sale.id,
  ///     'date': sale.date.toIso8601String(),
  ///     'total': sale.total,
  ///     'items': sale.items.map((i) => {
  ///       'productId': i.productId,
  ///       'name': i.productName,
  ///       'qty': i.quantity,
  ///       'price': i.price,
  ///       'total': i.total,
  ///     }).toList(),
  ///   }),
  /// );
  /// return response.statusCode == 200 || response.statusCode == 201;
  /// ```
  /// -------------------------------------------------------------------
  Future<bool> _uploadSale(SaleModel sale) async {
    // TODO: implement real API call
    await Future.delayed(const Duration(milliseconds: 100)); // simulate
    return false; // Return false until you wire the API
  }

  /// Force a manual sync attempt (e.g. from a sync button in the UI)
  Future<void> syncNow() => _syncPendingSales();
}
