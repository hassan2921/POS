import 'package:hive/hive.dart';
import '../../domain/entities/shop.dart';

part 'shop_model.g.dart';

@HiveType(typeId: 1)
class ShopModel extends Shop {
  @override
  @HiveField(0)
  final String name;
  @override
  @HiveField(1)
  final String addressLine1;
  @override
  @HiveField(2)
  final String addressLine2;
  @override
  @HiveField(3)
  final String phoneNumber;

  @override
  @HiveField(5)
  final String footerText;
  // Pakistani payment fields
  @override
  @HiveField(6)
  final String jazzCashNumber;
  @override
  @HiveField(7)
  final String easypaisaNumber;
  @override
  @HiveField(8)
  final String nayapayNumber;
  @override
  @HiveField(9)
  final String bankName;
  @override
  @HiveField(10)
  final String bankAccountTitle;
  @override
  @HiveField(11)
  final String bankAccountNumber;
  @override
  @HiveField(12)
  final String bankIban;

  const ShopModel({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneNumber,
    required this.footerText,
    this.jazzCashNumber = '',
    this.easypaisaNumber = '',
    this.nayapayNumber = '',
    this.bankName = '',
    this.bankAccountTitle = '',
    this.bankAccountNumber = '',
    this.bankIban = '',
  }) : super(
          name: name,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          phoneNumber: phoneNumber,
          footerText: footerText,
          jazzCashNumber: jazzCashNumber,
          easypaisaNumber: easypaisaNumber,
          nayapayNumber: nayapayNumber,
          bankName: bankName,
          bankAccountTitle: bankAccountTitle,
          bankAccountNumber: bankAccountNumber,
          bankIban: bankIban,
        );

  factory ShopModel.fromEntity(Shop shop) {
    return ShopModel(
      name: shop.name,
      addressLine1: shop.addressLine1,
      addressLine2: shop.addressLine2,
      phoneNumber: shop.phoneNumber,
      footerText: shop.footerText,
      jazzCashNumber: shop.jazzCashNumber,
      easypaisaNumber: shop.easypaisaNumber,
      nayapayNumber: shop.nayapayNumber,
      bankName: shop.bankName,
      bankAccountTitle: shop.bankAccountTitle,
      bankAccountNumber: shop.bankAccountNumber,
      bankIban: shop.bankIban,
    );
  }

  Shop toEntity() => this;
}
