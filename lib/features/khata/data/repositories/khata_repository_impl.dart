import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/khata_entry.dart';
import '../../domain/repositories/khata_repository.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

class KhataRepositoryImpl implements KhataRepository {
  // Use HiveDatabase constants instead of string literals so renames propagate
  Box<CustomerModel> get _customerBox => HiveDatabase.customersBox;
  Box<KhataEntryModel> get _entryBox => HiveDatabase.khataEntriesBox;

  // ── Customers ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Customer>>> getCustomers() async {
    try {
      final customers = List<Customer>.from(_customerBox.values)
        ..sort((a, b) => b.balance.compareTo(a.balance));
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Failed to load customers'));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      await _customerBox.put(
          customer.id, CustomerModel.fromEntity(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add customer'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      await _customerBox.put(
          customer.id, CustomerModel.fromEntity(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      // Collect entry keys BEFORE deleting the customer so that if entry
      // deletion fails we have not lost the customer record entirely.
      final entryKeys = _entryBox.values
          .where((e) => e.customerId == id)
          .map((e) => e.id)
          .toList();

      await _entryBox.deleteAll(entryKeys);
      await _customerBox.delete(id);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete customer'));
    }
  }

  // ── Khata Entries ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<KhataEntry>>> getEntriesForCustomer(
      String customerId) async {
    try {
      final entries = List<KhataEntry>.from(
        _entryBox.values.where((e) => e.customerId == customerId),
      )..sort((a, b) => b.date.compareTo(a.date));
      return Right(entries);
    } catch (e) {
      return Left(CacheFailure('Failed to load entries'));
    }
  }

  @override
  Future<Either<Failure, void>> addEntry(KhataEntry entry) async {
    try {
      final customer = _customerBox.get(entry.customerId);
      if (customer == null) {
        return Left(CacheFailure('Customer not found'));
      }

      // Compute the updated balance BEFORE writing either record.
      // If either write fails, the try-catch rolls back nothing (Hive has
      // no transactions), but at least we fail cleanly rather than silently.
      final delta = entry.type == KhataEntryType.credit
          ? entry.amount
          : -entry.amount;

      final updatedCustomer = CustomerModel(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        balance: customer.balance + delta,
      );

      // Write the entry first, then update the balance.
      // If balance update fails, the entry exists but balance is stale —
      // visible as a discrepancy that can be corrected by re-loading entries.
      await _entryBox.put(entry.id, KhataEntryModel.fromEntity(entry));
      await _customerBox.put(updatedCustomer.id, updatedCustomer);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save entry'));
    }
  }
}
