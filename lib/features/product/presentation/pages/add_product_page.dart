import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';

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
  bool _isImporting = false;

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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String targetBarcode = _barcode.trim();

      // 1. If barcode is empty, ask if they want to generate a unique code
      if (targetBarcode.isEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.qr_code, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  ctx.isUrdu ? 'بارکوڈ نہیں ہے' : 'No Barcode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              ctx.isUrdu
                  ? 'اس پروڈکٹ کا بارکوڈ نہیں ہے۔ کیا آپ اس کے لیے ایک مخصوص کوڈ بنانا چاہتے ہیں؟'
                  : 'This product does not have a barcode. Do you want to generate a unique code for it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.isUrdu ? 'نہیں' : 'No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.isUrdu ? 'جی ہاں' : 'Yes'),
              ),
            ],
          ),
        );

        if (proceed == null) return; // user dismissed dialog

        targetBarcode = 'NOBAR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      }

      // Check if code exists (only if it wasn't auto-generated)
      if (!targetBarcode.startsWith('NOBAR-')) {
        final productState = context.read<ProductBloc>().state;
        final existingProduct = productState.products
            .where((p) => p.barcode == targetBarcode)
            .firstOrNull;

        if (existingProduct != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trWith('barcode_exists', {'barcode': targetBarcode})),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // 2. Ask "Is this item sold in kg?"
      final soldInKg = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.scale, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                ctx.isUrdu ? 'کلوگرام میں فروخت' : 'Sold in KG',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            ctx.isUrdu
                ? 'کیا یہ پروڈکٹ کلو (KG) میں فروخت ہوتی ہے؟'
                : 'Is this item sold in kg?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.isUrdu ? 'نہیں' : 'No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.isUrdu ? 'جی ہاں' : 'Yes'),
            ),
          ],
        ),
      );

      if (soldInKg == null) return; // user dismissed dialog

      final finalUnit = soldInKg ? 'kg' : _unit;

      final product = Product(
        id: const Uuid().v4(),
        name: _name,
        barcode: targetBarcode,
        price: _price,
        stock: _stock,
        unit: finalUnit,
      );

      if (mounted) {
        context.read<ProductBloc>().add(AddProduct(product));
      }
    }
  }

  void _showImportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header band ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.upload_file_rounded,
                          color: AppTheme.primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.tr('import_csv_title'),
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctx.tr('import_csv_subtitle'),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close,
                          color: Color(0xFF9CA3AF), size: 22),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Steps row ──────────────────────────────────────
                    Row(
                      children: [
                        _StepTile(
                            icon: Icons.tag_rounded,
                            label: ctx.tr('csv_col_barcode')),
                        const _StepDivider(),
                        _StepTile(
                            icon: Icons.label_outline_rounded,
                            label: ctx.tr('csv_col_name')),
                        const _StepDivider(),
                        _StepTile(
                            icon: Icons.currency_rupee_rounded,
                            label: ctx.tr('csv_col_price')),
                        const _StepDivider(),
                        _StepTile(
                            icon: Icons.inventory_2_outlined,
                            label: ctx.tr('csv_col_stock')),
                        const _StepDivider(),
                        _StepTile(
                            icon: Icons.straighten_rounded,
                            label: ctx.tr('csv_col_unit'),
                            muted: true),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── CSV preview table ──────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          // header row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF2F7),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(11)),
                            ),
                            child: Row(
                              children: [
                                _CsvCell(
                                    text: ctx.tr('csv_col_barcode'),
                                    flex: 2,
                                    isHeader: true),
                                _CsvCell(
                                    text: ctx.tr('csv_col_name'),
                                    flex: 3,
                                    isHeader: true),
                                _CsvCell(
                                    text: ctx.tr('csv_col_price'),
                                    flex: 2,
                                    isHeader: true),
                                _CsvCell(
                                    text: ctx.tr('csv_col_stock'),
                                    flex: 2,
                                    isHeader: true),
                                _CsvCell(
                                    text: ctx.tr('csv_col_unit'),
                                    flex: 2,
                                    isHeader: true),
                              ],
                            ),
                          ),
                          // sample row 1
                          const _CsvRow(cells: [
                            '123456',
                            'Basmati Rice',
                            '150.00',
                            '10',
                            'kg'
                          ]),
                          // sample row 2
                          const _CsvRow(cells: [
                            '789012',
                            'Daal Moong',
                            '250.00',
                            '5',
                            ''
                          ], isLast: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Unit note ──────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ctx.tr('import_csv_unit_note'),
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── CTA button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _importCsv();
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 20),
                        label: Text(ctx.tr('choose_csv_file'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isImporting = true);

    try {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(csvString);

      if (rows.isEmpty) {
        _showImportSnackBar(context.trOnce('csv_empty'), isError: true);
        return;
      }

      final dataRows = rows.first.isNotEmpty &&
              rows.first[0].toString().toLowerCase().contains('barcode')
          ? rows.sublist(1)
          : rows;

      final existingProducts = context.read<ProductBloc>().state.products;
      final existingBarcodes = existingProducts.map((p) => p.barcode).toSet();

      int skipped = 0;
      int errors = 0;
      final toImport = <Product>[];

      for (final row in dataRows) {
        if (row.length < 4) {
          errors++;
          continue;
        }

        try {
          final barcode = row[0].toString().trim();
          final name = row[1].toString().trim();
          final price = double.tryParse(row[2].toString().trim());
          final stock = int.tryParse(row[3].toString().trim());
          final unit = row.length >= 5 ? row[4].toString().trim() : '';

          if (barcode.isEmpty ||
              name.isEmpty ||
              price == null ||
              stock == null) {
            errors++;
            continue;
          }

          if (existingBarcodes.contains(barcode)) {
            skipped++;
            continue;
          }

          toImport.add(Product(
            id: const Uuid().v4(),
            name: name,
            barcode: barcode,
            price: price,
            stock: stock,
            unit: unit,
          ));
          existingBarcodes.add(barcode);
        } catch (_) {
          errors++;
        }
      }

      final imported = toImport.length;

      if (toImport.isNotEmpty && mounted) {
        context.read<ProductBloc>().add(BulkAddProducts(toImport));
      }

      final parts = <String>[];
      if (imported > 0) parts.add('$imported imported');
      if (skipped > 0) parts.add('$skipped skipped (duplicates)');
      if (errors > 0) parts.add('$errors invalid rows');

      _showImportSnackBar(
        parts.join(' · '),
        isError: imported == 0,
      );
    } catch (e) {
      _showImportSnackBar(context.trOnce('csv_read_error'), isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showImportSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state.status == ProductStatus.success) {
          if (!_isImporting) context.pop();
        } else if (state.status == ProductStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message ?? 'Failed to add product'),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(context.tr('add_product_title'),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : const Icon(Icons.upload_file, color: AppTheme.primaryColor),
              tooltip: 'Import CSV',
              onPressed: _isImporting ? null : _showImportBottomSheet,
            ),
          ],
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
                          validator: (value) => null,
                          onSaved: (value) => _barcode = value ?? '',
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
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4C669A))),
                  const SizedBox(height: 24),
                  InputLabel(text: context.tr('product_name')),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: context.tr('product_name_hint'),
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    validator:
                        AppValidators.required(context.trOnce('name_required')),
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
          icon: Icons.add_circle,
          label: context.tr('add_product_btn'),
        ),
      ),
    );
  }
}

// ── Helper widgets for the CSV bottom sheet ───────────────────────────────────

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;
  const _StepTile(
      {required this.icon, required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color = muted ? const Color(0xFFB0B8C8) : AppTheme.primaryColor;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: muted ? 0.07 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: muted ? const Color(0xFFB0B8C8) : const Color(0xFF374151),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 18),
        child: Icon(Icons.chevron_right_rounded,
            size: 14, color: Color(0xFFD1D5DB)),
      );
}

class _CsvCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isHeader;
  const _CsvCell(
      {required this.text, required this.flex, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 10 : 11,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: isHeader ? const Color(0xFF6B7280) : const Color(0xFF1F2937),
          letterSpacing: isHeader ? 0.3 : 0,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CsvRow extends StatelessWidget {
  final List<String> cells;
  final bool isLast;
  const _CsvRow({required this.cells, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
      ),
      child: Row(
        children: [
          _CsvCell(text: cells[0], flex: 2),
          _CsvCell(text: cells[1], flex: 3),
          _CsvCell(text: cells[2], flex: 2),
          _CsvCell(text: cells[3], flex: 2),
          _CsvCell(text: cells[4].isEmpty ? '—' : cells[4], flex: 2),
        ],
      ),
    );
  }
}
