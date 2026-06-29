import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;
  final String footerText;

  // ── Pakistani payment methods ────────────────────────────────────────
  final String jazzCashNumber;    // e.g. 03001234567
  final String easypaisaNumber;   // e.g. 03001234567
  final String nayapayNumber;     // e.g. 03001234567
  final String bankName;          // e.g. HBL
  final String bankAccountTitle;  // e.g. Muhammad Hassan
  final String bankAccountNumber; // e.g. 01234567890123
  final String bankIban;          // e.g. PK36HABB0000001234567890

  const Shop({
    this.name = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNumber = '',
    this.footerText = '',
    this.jazzCashNumber = '',
    this.easypaisaNumber = '',
    this.nayapayNumber = '',
    this.bankName = '',
    this.bankAccountTitle = '',
    this.bankAccountNumber = '',
    this.bankIban = '',
    
  });

  Shop copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? phoneNumber,
    String? footerText,
    String? jazzCashNumber,
    String? easypaisaNumber,
    String? nayapayNumber,
    String? bankName,
    String? bankAccountTitle,
    String? bankAccountNumber,
    String? bankIban,
    
  }) {
    return Shop(
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      footerText: footerText ?? this.footerText,
      jazzCashNumber: jazzCashNumber ?? this.jazzCashNumber,
      easypaisaNumber: easypaisaNumber ?? this.easypaisaNumber,
      nayapayNumber: nayapayNumber ?? this.nayapayNumber,
      bankName: bankName ?? this.bankName,
      bankAccountTitle: bankAccountTitle ?? this.bankAccountTitle,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIban: bankIban ?? this.bankIban,
      
    );
  }

  @override
  List<Object?> get props => [
        name, addressLine1, addressLine2, phoneNumber, footerText,
        jazzCashNumber, easypaisaNumber, nayapayNumber,
        bankName, bankAccountTitle, bankAccountNumber, bankIban, 
      ];
}
