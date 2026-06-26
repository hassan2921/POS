import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 4)
class CustomerModel extends Customer {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String name;

  @override
  @HiveField(2)
  final String phone;

  @override
  @HiveField(3)
  final double balance;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
  }) : super(id: id, name: name, phone: phone, balance: balance);

  factory CustomerModel.fromEntity(Customer c) => CustomerModel(
        id: c.id,
        name: c.name,
        phone: c.phone,
        balance: c.balance,
      );
}
