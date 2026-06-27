import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/hive_database.dart';
import '../../features/sales/data/models/sale_model.dart';

/// SyncService listens for internet connectivity and syncs
/// any unsynced local sales to the backend when online.
///
/// WIRING INSTRUCTIONS:
/// 1. Replace the `_uploadSale` stub with your real API call
/// 2. Call `SyncService.instance.init()` in main() after HiveDatabase.init()
/// 3. Call `SyncService.instance.dispose()` in your app's lifecycle onDetach
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  void init() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _syncPendingSales();
    });

    _trySyncOnStartup();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _trySyncOnStartup() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline = result.any((r) => r != ConnectivityResult.none);
    if (isOnline) await _syncPendingSales();
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
    } catch (e, st) {
      // Log for debugging; will retry on next connectivity event.
      developer.log('SyncService: upload error — $e', error: e, stackTrace: st);
    } finally {
      _isSyncing = false;
    }
  }

  /// -------------------------------------------------------------------
  /// STUB: Replace with your actual API call.
  ///
  /// NOTE: This stub always returns false. Until a real backend is wired,
  /// ALL sales will remain marked as "UNSYNCED" in the sales history.
  ///
  /// Example with http:
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('https://your-api.com/api/sales'),
  ///   headers: {'Content-Type': 'application/json'},
  ///   body: jsonEncode({...}),
  /// );
  /// return response.statusCode == 200 || response.statusCode == 201;
  /// ```
  /// -------------------------------------------------------------------
  Future<bool> _uploadSale(SaleModel sale) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return false;
  }

  Future<void> syncNow() => _syncPendingSales();
}
