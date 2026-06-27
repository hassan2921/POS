import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

/// Products with stock at or below this threshold show a low stock badge.
const int kLowStockThreshold = 5;

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanQR(List<Product> products) async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty) {
      final match = products.where((p) => p.barcode == barcode).firstOrNull;
      _searchController.text = match?.name ?? barcode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final lowStockCount = state.products
                    .where((p) => p.stock <= kLowStockThreshold && p.stock > 0)
                    .length;
                final outOfStockCount =
                    state.products.where((p) => p.stock == 0).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Search or scan barcode',
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.grey[400]),
                            ),
                            validator: AppValidators.required(
                                'Please enter a barcode'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner,
                                color: AppTheme.primaryColor),
                            onPressed: () => _scanQR(state.products),
                            padding: const EdgeInsets.all(15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap the icon to open camera scanner',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF4C669A))),

                    // Stock alert chips
                    if (lowStockCount > 0 || outOfStockCount > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (outOfStockCount > 0)
                            _stockChip(
                              label: '$outOfStockCount Out of stock',
                              color: Colors.red,
                              icon: Icons.remove_shopping_cart,
                            ),
                          if (outOfStockCount > 0 && lowStockCount > 0)
                            const SizedBox(width: 8),
                          if (lowStockCount > 0)
                            _stockChip(
                              label: '$lowStockCount Low stock',
                              color: Colors.orange,
                              icon: Icons.warning_amber_rounded,
                            ),
                          const Spacer(),
                          // Filter toggle
                          GestureDetector(
                            onTap: () => setState(
                                () => _showLowStockOnly = !_showLowStockOnly),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _showLowStockOnly
                                    ? AppTheme.primaryColor
                                    : AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _showLowStockOnly ? 'All' : 'Filter low',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showLowStockOnly
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state.status == ProductStatus.error &&
                    state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message!),
                      backgroundColor: Colors.red));
                }
              },
              builder: (context, state) {
                if (state.status == ProductStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  return const Center(
                      child: Text('No products found. Add some!'));
                }

                var filtered = state.products.where((p) {
                  final matchesSearch =
                      p.name.toLowerCase().contains(_searchQuery) ||
                          p.barcode.toLowerCase().contains(_searchQuery);
                  final matchesFilter =
                      !_showLowStockOnly || p.stock <= kLowStockThreshold;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No products match your search.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isLowStock = product.stock > 0 &&
                        product.stock <= kLowStockThreshold;
                    final isOutOfStock = product.stock == 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOutOfStock
                              ? Colors.red.withValues(alpha: 0.3)
                              : isLowStock
                                  ? Colors.orange.withValues(alpha: 0.3)
                                  : borderColor,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16),
                                      ),
                                    ),
                                    if (isOutOfStock) ...[
                                      const SizedBox(width: 8),
                                      _badge('OUT', Colors.red),
                                    ] else if (isLowStock) ...[
                                      const SizedBox(width: 8),
                                      _badge('LOW', Colors.orange),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Rs. ${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.inventory_2_outlined,
                                        size: 13,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : isLowStock
                                                ? Colors.orange
                                                : Colors.grey[400]),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Stock: ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : isLowStock
                                                ? Colors.orange
                                                : Colors.grey[500],
                                        fontWeight: isOutOfStock || isLowStock
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      color: AppTheme.primaryColor, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  onPressed: () => context.push(
                                      '/products/edit/${product.id}',
                                      extra: product),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.red, size: 20),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  onPressed: () =>
                                      _confirmDelete(context, product),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _stockChip(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(product.id));
              Navigator.pop(innerContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
