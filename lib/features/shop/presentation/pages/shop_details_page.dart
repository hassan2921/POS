import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/shop.dart';
import '../bloc/shop_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // General
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;

  // Payment
  late TextEditingController _jazzCashController;
  late TextEditingController _easypaisaController;
  late TextEditingController _nayapayController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankTitleController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankIbanController;

  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _phoneController = TextEditingController();
    _footerController = TextEditingController();
    _jazzCashController = TextEditingController();
    _easypaisaController = TextEditingController();
    _nayapayController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankTitleController = TextEditingController();
    _bankAccountController = TextEditingController();
    _bankIbanController = TextEditingController();

    context.read<ShopBloc>().add(LoadShopEvent());
  }

  void _updateControllers(Shop shop) {
    if (_populated) return;
    _populated = true;
    _nameController.text = shop.name;
    _address1Controller.text = shop.addressLine1;
    _address2Controller.text = shop.addressLine2;
    _phoneController.text = shop.phoneNumber;
    _footerController.text = shop.footerText;
    _jazzCashController.text = shop.jazzCashNumber;
    _easypaisaController.text = shop.easypaisaNumber;
    _nayapayController.text = shop.nayapayNumber;
    _bankNameController.text = shop.bankName;
    _bankTitleController.text = shop.bankAccountTitle;
    _bankAccountController.text = shop.bankAccountNumber;
    _bankIbanController.text = shop.bankIban;
  }

  @override
  void dispose() {
    for (final c in [
      _nameController, _address1Controller, _address2Controller,
      _phoneController, _footerController, _jazzCashController,
      _easypaisaController, _nayapayController, _bankNameController,
      _bankTitleController, _bankAccountController, _bankIbanController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = Shop(
        name: _nameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        phoneNumber: _phoneController.text,
        footerText: _footerController.text,
        jazzCashNumber: _jazzCashController.text,
        easypaisaNumber: _easypaisaController.text,
        nayapayNumber: _nayapayController.text,
        bankName: _bankNameController.text,
        bankAccountTitle: _bankTitleController.text,
        bankAccountNumber: _bankAccountController.text,
        bankIban: _bankIbanController.text,
      );
      context.read<ShopBloc>().add(UpdateShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state is ShopLoaded) {
            _updateControllers(state.shop);
          } else if (state is ShopOperationSuccess) {
            context.pop();
          } else if (state is ShopError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        buildWhen: (previous, current) =>
            current is ShopLoading || current is ShopLoaded,
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── General Info ───────────────────────────────────
                  Text('General Information',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      )),
                  const SizedBox(height: 5),
                  Text(
                    'These details will appear on your digital and printed receipts.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),

                  const InputLabel(text: 'Shop Name'),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'e.g. Hassan General Store',
                    validator: AppValidators.required('Required'),
                  ),
                  const SizedBox(height: 15),

                  const InputLabel(text: 'Address Line 1'),
                  _buildTextField(
                    controller: _address1Controller,
                    hint: 'Street / Area',
                    validator: AppValidators.required('Required'),
                  ),
                  const SizedBox(height: 15),

                  const InputLabel(text: 'Address Line 2 (Optional)'),
                  _buildTextField(
                    controller: _address2Controller,
                    hint: 'City / Postal code',
                  ),
                  const SizedBox(height: 15),

                  const InputLabel(text: 'Phone Number'),
                  _buildTextField(
                    controller: _phoneController,
                    hint: '+92 300 1234567',
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.required('Required'),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const InputLabel(text: 'Receipt Footer Text'),
                      Text('Max 60 chars',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                  _buildTextField(
                    controller: _footerController,
                    hint: 'Thank you, Visit again!',
                    maxLines: 2,
                    maxLength: 60,
                  ),

                  const SizedBox(height: 32),

                  // ── Payment Methods ────────────────────────────────
                  Text('Payment Methods',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      )),
                  const SizedBox(height: 5),
                  Text(
                    'Add numbers for methods you accept. Leave blank to hide on checkout.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),

                  // JazzCash
                  _paymentHeader(
                      color: const Color(0xFFE31837),
                      label: 'JazzCash',
                      icon: Icons.phone_android),
                  const SizedBox(height: 10),
                  const InputLabel(text: 'JazzCash Number'),
                  _buildTextField(
                    controller: _jazzCashController,
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Easypaisa
                  _paymentHeader(
                      color: const Color(0xFF4CAF50),
                      label: 'Easypaisa',
                      icon: Icons.phone_android),
                  const SizedBox(height: 10),
                  const InputLabel(text: 'Easypaisa Number'),
                  _buildTextField(
                    controller: _easypaisaController,
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Nayapay
                  _paymentHeader(
                      color: const Color(0xFF7B2FBE),
                      label: 'Nayapay',
                      icon: Icons.phone_android),
                  const SizedBox(height: 10),
                  const InputLabel(text: 'Nayapay Number'),
                  _buildTextField(
                    controller: _nayapayController,
                    hint: '03001234567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Bank Transfer
                  _paymentHeader(
                      color: const Color(0xFF1565C0),
                      label: 'Bank Transfer',
                      icon: Icons.account_balance),
                  const SizedBox(height: 10),

                  const InputLabel(text: 'Bank Name'),
                  _buildTextField(
                    controller: _bankNameController,
                    hint: 'e.g. HBL / MCB / UBL / Meezan',
                  ),
                  const SizedBox(height: 12),

                  const InputLabel(text: 'Account Title'),
                  _buildTextField(
                    controller: _bankTitleController,
                    hint: 'e.g. Muhammad Hassan',
                  ),
                  const SizedBox(height: 12),

                  const InputLabel(text: 'Account Number'),
                  _buildTextField(
                    controller: _bankAccountController,
                    hint: '01234567890123',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  const InputLabel(text: 'IBAN (Optional)'),
                  _buildTextField(
                    controller: _bankIbanController,
                    hint: 'PK36HABB0000001234567890',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _saveShop,
        icon: Icons.save,
        label: 'Save Details',
      ),
    );
  }

  Widget _paymentHeader({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
