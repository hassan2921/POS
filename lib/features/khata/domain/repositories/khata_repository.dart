import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer.dart';
import '../entities/khata_entry.dart';

abstract class KhataRepository {
  Future<Either<Failure, List<Customer>>> getCustomers();
  Future<Either<Failure, void>> addCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, List<KhataEntry>>> getEntriesForCustomer(
      String customerId);
  Future<Either<Failure, void>> addEntry(KhataEntry entry);
}
