import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/khata_entry.dart';
import '../../domain/repositories/khata_repository.dart';
import '../models/customer_model.dart';
import '../models/khata_entry_model.dart';

class KhataRepositoryImpl implements KhataRepository {
  Box<CustomerModel> get _customerBox =>
      Hive.box<CustomerModel>('customers');
  Box<KhataEntryModel> get _entryBox =>
      Hive.box<KhataEntryModel>('khata_entries');

  // ── Customers ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Customer>>> getCustomers() async {
    try {
      final customers = List<Customer>.from(_customerBox.values)
        ..sort((a, b) => b.balance.compareTo(a.balance));
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure('Failed to load customers: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      await _customerBox.put(
          customer.id, CustomerModel.fromEntity(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add customer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      await _customerBox.put(
          customer.id, CustomerModel.fromEntity(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to update customer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await _customerBox.delete(id);
      // Also remove all entries for this customer
      final keys = _entryBox.values
          .where((e) => e.customerId == id)
          .map((e) => e.id)
          .toList();
      await _entryBox.deleteAll(keys);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete customer: $e'));
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
      return Left(CacheFailure('Failed to load entries: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addEntry(KhataEntry entry) async {
    try {
      await _entryBox.put(entry.id, KhataEntryModel.fromEntity(entry));

      // Update customer balance
      final customer = _customerBox.get(entry.customerId);
      if (customer != null) {
        final delta = entry.type == KhataEntryType.credit
            ? entry.amount
            : -entry.amount;
        final updated = CustomerModel(
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          balance: customer.balance + delta,
        );
        await _customerBox.put(updated.id, updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save entry: $e'));
    }
  }
}
