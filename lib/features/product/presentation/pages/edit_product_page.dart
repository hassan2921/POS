import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/app_localizations.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late int _stock;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _price = widget.product.price;
    _stock = widget.product.stock;
    _unit = widget.product.unit;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedProduct = Product(
        id: widget.product.id,
        name: _name,
        barcode: widget.product.barcode,
        price: _price,
        stock: _stock,
        unit: _unit,
      );

      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state.status == ProductStatus.success) {
          context.pop();
        } else if (state.status == ProductStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message ?? 'Failed to update product'),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(context.tr('edit_product_title'),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Barcode details (immutable block)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('barcode').toUpperCase(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.7))),
                            const SizedBox(height: 2),
                            Text(widget.product.barcode,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  InputLabel(text: context.tr('product_name')),
                  TextFormField(
                    initialValue: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    validator:
                        AppValidators.required(context.trOnce('name_required')),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: context.tr('price')),
                  TextFormField(
                    initialValue: _price.toStringAsFixed(2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
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
                    initialValue: _stock.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: context.tr('stock_hint'),
                    ),
                    validator: AppValidators.required(
                        context.trOnce('stock_required')),
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
                      DropdownMenuItem(
                          value: null, child: Text(context.tr('unit_none'))),
                      DropdownMenuItem(
                          value: 'kg', child: Text(context.tr('unit_kg'))),
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
          icon: Icons.save,
          label: context.tr('save_changes'),
        )),
    );
  }
}
