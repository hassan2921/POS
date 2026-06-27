import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer.dart';
import '../entities/khata_entry.dart';
import '../repositories/khata_repository.dart';

class GetCustomersUseCase {
  final KhataRepository repository;
  GetCustomersUseCase(this.repository);
  Future<Either<Failure, List<Customer>>> call() =>
      repository.getCustomers();
}

class AddCustomerUseCase {
  final KhataRepository repository;
  AddCustomerUseCase(this.repository);
  Future<Either<Failure, void>> call(Customer customer) =>
      repository.addCustomer(customer);
}

class UpdateCustomerUseCase {
  final KhataRepository repository;
  UpdateCustomerUseCase(this.repository);
  Future<Either<Failure, void>> call(Customer customer) =>
      repository.updateCustomer(customer);
}

class DeleteCustomerUseCase {
  final KhataRepository repository;
  DeleteCustomerUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) =>
      repository.deleteCustomer(id);
}

class GetEntriesForCustomerUseCase {
  final KhataRepository repository;
  GetEntriesForCustomerUseCase(this.repository);
  Future<Either<Failure, List<KhataEntry>>> call(String customerId) =>
      repository.getEntriesForCustomer(customerId);
}

class AddKhataEntryUseCase {
  final KhataRepository repository;
  AddKhataEntryUseCase(this.repository);
  Future<Either<Failure, void>> call(KhataEntry entry) =>
      repository.addEntry(entry);
}
