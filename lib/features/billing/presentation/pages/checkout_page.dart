import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (!context.read<BillingBloc>().state.orderConfirmed) {
          context.read<BillingBloc>().add(ClearCartEvent());
        }
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('review_order'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () {
              if (!context.read<BillingBloc>().state.orderConfirmed) {
                context.read<BillingBloc>().add(ClearCartEvent());
              }
              context.go('/home');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ));
            }
            if (state.orderConfirmed &&
                !state.isPrinting &&
                !state.printSuccess) {
              context.read<ProductBloc>().add(LoadProducts());
              context.read<DashboardBloc>().add(LoadDashboardEvent());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.trOnce('order_confirmed_stock')), // ✅ fixed
                backgroundColor: Colors.green,
              ));
            }
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.trOnce('printed_successfully')), // ✅ fixed
                backgroundColor: Colors.green,
              ));
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/home');
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Shop';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                return Column(
                  children: [
                    // ── Order items table ────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // Stock warning banner
                            Builder(builder: (context) {
                              final lowStockItems = billingState.cartItems
                                  .where((item) =>
                                      item.product.stock > 0 &&
                                      (item.product.stock - item.quantity) <= 5)
                                  .toList();
                              if (lowStockItems.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.amber[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${lowStockItems.length} item${lowStockItems.length > 1 ? 's have' : ' has'} low stock remaining',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        border: Border(
                                            bottom:
                                                BorderSide(color: borderColor)),
                                      ),
                                      children: [
                                        _buildHeaderCell(
                                            context.tr('product_name'),
                                            TextAlign.left),
                                        _buildHeaderCell(context.tr('price'),
                                            TextAlign.right),
                                        _buildHeaderCell(context.tr('total'),
                                            TextAlign.right),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) {
                                      return TableRow(
                                        children: [
                                          _buildDataCell(
                                            '${item.quantity} x ${item.product.name}',
                                            TextAlign.left,
                                          ),
                                          _buildDataCell(
                                              'Rs. ${item.product.price.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isSubtitle: true),
                                          _buildDataCell(
                                              'Rs. ${item.total.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isBold: true),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom bar ───────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(24),
                            right: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                // QR code
                                upiId.isNotEmpty
                                    ? Column(
                                        children: [
                                          Text(
                                            context.tr('scan_to_pay'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: PrettyQrView.data(
                                              data:
                                                  'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=PKR',
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                                const SizedBox(height: 15),
                                // Grand total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr('grand_total'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[400],
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${billingState.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Confirm button (before confirmed) ──────
                          if (!billingState.orderConfirmed)
                            PrimaryButton(
                              onPressed: billingState.isConfirming
                                  ? null
                                  : () => context
                                      .read<BillingBloc>()
                                      .add(ConfirmOrderEvent()),
                              label: context.tr('confirm_order'),
                              icon: Icons.check_circle,
                              isLoading: billingState.isConfirming,
                            ),

                          // ── Print + Done (after confirmed) ─────────
                          if (billingState.orderConfirmed) ...[
                            if (shopState is ShopLoaded)
                              PrimaryButton(
                                onPressed: billingState.isPrinting
                                    ? null
                                    : () => context.read<BillingBloc>().add(
                                          PrintReceiptEvent(
                                            shopName: shopState.shop.name,
                                            address1:
                                                shopState.shop.addressLine1,
                                            address2:
                                                shopState.shop.addressLine2,
                                            phone: shopState.shop.phoneNumber,
                                            footer: shopState.shop.footerText,
                                          ),
                                        ),
                                label: context.tr('print_receipt'),
                                icon: Icons.print,
                                isLoading: billingState.isPrinting,
                              ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextButton.icon(
                                onPressed: () {
                                  context
                                      .read<BillingBloc>()
                                      .add(ClearCartEvent());
                                  context.pop();
                                },
                                icon: const Icon(Icons.check),
                                label: Text(context.tr('done_skip_printing')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}
