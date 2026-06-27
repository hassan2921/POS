import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/app_localizations.dart';

class AddProductPage extends StatefulWidget {
  final String? initialBarcode;
  const AddProductPage({super.key, this.initialBarcode});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  late String _barcode;
  double _price = 0.0;
  int _stock = 0;
  String _unit = '';

  @override
  void initState() {
    super.initState();
    _barcode = widget.initialBarcode ?? '';
  }

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final productState = context.read<ProductBloc>().state;
      final existingProduct =
          productState.products.where((p) => p.barcode == _barcode).firstOrNull;

      if (existingProduct != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trOnce('barcode_exists').replaceAll('{barcode}', _barcode)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = Product(
        id: const Uuid().v4(),
        name: _name,
        barcode: _barcode,
        price: _price,
        stock: _stock,
        unit: _unit,
      );

      context.read<ProductBloc>().add(AddProduct(product));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(context.tr('add_product_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputLabel(text: context.tr('barcode')),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_barcode),
                          initialValue: _barcode,
                          decoration: InputDecoration(
                            hintText: context.tr('scan_or_enter_barcode'),
                          ),
                          validator: AppValidators.required(context.trOnce('barcode_required')),
                          onSaved: (value) => _barcode = value!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppTheme.primaryColor),
                          onPressed: _scanBarcode,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(context.tr('scan_to_search'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
                  const SizedBox(height: 24),
                  InputLabel(text: context.tr('product_name')),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: context.tr('product_name_hint'),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required(context.trOnce('name_required')),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: context.tr('price')),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    validator: AppValidators.price(
                      empty: context.trOnce('price_required'),
                      invalid: context.trOnce('price_invalid'),
                      negative: context.trOnce('price_negative'),
                    ),
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: context.tr('stock')),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: context.tr('stock_hint'),
                    ),
                    validator: AppValidators.required(context.trOnce('stock_required')),
                    onSaved: (value) =>
                        _stock = int.tryParse(value ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: context.tr('unit_label')),
                  DropdownButtonFormField<String>(
                    initialValue: _unit.isEmpty ? null : _unit,
                    decoration: InputDecoration(
                      hintText: context.tr('unit_hint'),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('unit_none'))),
                      DropdownMenuItem(value: 'pcs', child: Text(context.tr('unit_pcs'))),
                      DropdownMenuItem(value: 'kg', child: Text(context.tr('unit_kg'))),
                      DropdownMenuItem(value: 'g', child: Text(context.tr('unit_g'))),
                      DropdownMenuItem(value: 'ltr', child: Text(context.tr('unit_ltr'))),
                      DropdownMenuItem(value: 'ml', child: Text(context.tr('unit_ml'))),
                      DropdownMenuItem(value: 'dozen', child: Text(context.tr('unit_dozen'))),
                      DropdownMenuItem(value: 'box', child: Text(context.tr('unit_box'))),
                      DropdownMenuItem(value: 'pack', child: Text(context.tr('unit_pack'))),
                      DropdownMenuItem(value: 'm', child: Text(context.tr('unit_m'))),
                      DropdownMenuItem(value: 'ft', child: Text(context.tr('unit_ft'))),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? ''),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _submit,
          icon: Icons.add_circle,
          label: context.tr('add_product_btn'),
        ));
  }
}
