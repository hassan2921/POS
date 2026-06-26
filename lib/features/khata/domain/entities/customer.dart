import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;

  /// Running balance — positive means customer owes money (udhaar).
  final double balance;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    double? balance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, balance];
}
