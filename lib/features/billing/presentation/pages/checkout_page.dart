import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/utils/app_localizations.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../shop/domain/entities/shop.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../bloc/billing_bloc.dart';
import '../../../../core/widgets/receipt_image_widget.dart';
import '../../../../core/service/receipt_share_service.dart';
import '../../../khata/presentation/bloc/khata_bloc.dart';
import '../../../khata/domain/entities/customer.dart';

// ── Payment method enum ────────────────────────────────────────────────────
enum _PayMethod { jazzcash, easypaisa, nayapay, bank }

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  _PayMethod? _selectedMethod;
  final GlobalKey _receiptKey = GlobalKey();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns only methods that have data configured in shop settings
  List<_PayMethod> _availableMethods(Shop shop) {
    return [
      if (shop.jazzCashNumber.isNotEmpty) _PayMethod.jazzcash,
      if (shop.easypaisaNumber.isNotEmpty) _PayMethod.easypaisa,
      if (shop.nayapayNumber.isNotEmpty) _PayMethod.nayapay,
      if (shop.bankAccountNumber.isNotEmpty || shop.bankIban.isNotEmpty)
        _PayMethod.bank,
    ];
  }

  String _methodLabel(_PayMethod m) => switch (m) {
        _PayMethod.jazzcash => 'JazzCash',
        _PayMethod.easypaisa => 'Easypaisa',
        _PayMethod.nayapay => 'Nayapay',
        _PayMethod.bank => 'Bank',
      };

  Color _methodColor(_PayMethod m) => switch (m) {
        _PayMethod.jazzcash => const Color(0xFFE31837),
        _PayMethod.easypaisa => const Color(0xFF4CAF50),
        _PayMethod.nayapay => const Color(0xFF7B2FBE),
        _PayMethod.bank => const Color(0xFF1565C0),
      };

  IconData _methodIcon(_PayMethod m) => switch (m) {
        _PayMethod.jazzcash => Icons.phone_android,
        _PayMethod.easypaisa => Icons.phone_android,
        _PayMethod.nayapay => Icons.phone_android,
        _PayMethod.bank => Icons.account_balance,
      };

  /// Builds the QR data string or bank details widget for a method
  Widget _buildPaymentDetail(Shop shop, double amount) {
    if (_selectedMethod == null) return const SizedBox.shrink();

    switch (_selectedMethod!) {
      case _PayMethod.jazzcash:
        return _buildPhoneQr(
          number: shop.jazzCashNumber,
          label: 'JazzCash',
          color: const Color(0xFFE31837),
          amount: amount,
        );
      case _PayMethod.easypaisa:
        return _buildPhoneQr(
          number: shop.easypaisaNumber,
          label: 'Easypaisa',
          color: const Color(0xFF4CAF50),
          amount: amount,
        );
      case _PayMethod.nayapay:
        return _buildPhoneQr(
          number: shop.nayapayNumber,
          label: 'Nayapay',
          color: const Color(0xFF7B2FBE),
          amount: amount,
        );
      case _PayMethod.bank:
        return _buildBankDetails(shop);
    }
  }

  Widget _buildPhoneQr({
    required String number,
    required String label,
    required Color color,
    required double amount,
  }) {
    // Generic QR encoding — scanner apps like JazzCash/Easypaisa read phone QR
    final qrData = 'tel:$number';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              'Scan to pay via $label',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 180,
          height: 180,
          child: PrettyQrView.data(data: qrData),
        ),
        const SizedBox(height: 8),
        // Copyable number
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: number));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$label ${context.trOnce('number_copied')}'),
              duration: const Duration(seconds: 1),
              backgroundColor: color,
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 14, color: color),
                const SizedBox(width: 6),
                Text(number,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(context.tr('tap_to_copy'),
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildBankDetails(Shop shop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance,
                  color: Color(0xFF1565C0), size: 18),
              const SizedBox(width: 8),
              Text(
                shop.bankName.isNotEmpty ? shop.bankName : context.tr('bank_transfer'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                    fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 20),
          if (shop.bankAccountTitle.isNotEmpty)
            _bankRow(context.tr('account_title_label'), shop.bankAccountTitle),
          if (shop.bankAccountNumber.isNotEmpty)
            _bankRow(context.tr('account_no_label'), shop.bankAccountNumber, copyable: true),
          if (shop.bankIban.isNotEmpty)
            _bankRow('IBAN', shop.bankIban, copyable: true),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$label ${context.trOnce('copied')}'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: const Color(0xFF1565C0),
                      ));
                    }
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  if (copyable)
                    const Icon(Icons.copy, size: 14, color: Color(0xFF1565C0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  Future<void> _shareReceiptImage() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await ReceiptShareService.shareAsImage(
      boundaryKey: _receiptKey,
      filename: 'receipt.png',
    );
  }

  Future<void> _showWhatsAppDialog(
      BillingState billingState, ShopState shopState) async {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
            ),
            const SizedBox(width: 12),
            Text(context.trOnce('send_receipt'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.trOnce('whatsapp_number_hint'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '92XXXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                  helperText: context.trOnce('whatsapp_country_code_hint'),
                  helperStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.trOnce('whatsapp_number_empty');
                  }
                  if (val.trim().length < 10) {
                    return context.trOnce('whatsapp_number_short');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.trOnce('cancel'),
                style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send, size: 16),
            label: Text(context.trOnce('send')),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                _sendWhatsAppText(
                    phone: phoneController.text.trim(),
                    billingState: billingState,
                    shopState: shopState);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppText({
    required String phone,
    required BillingState billingState,
    required ShopState shopState,
  }) async {
    String shopName = 'Shop';
    String address = '';
    String footer = '';
    if (shopState is ShopLoaded) {
      shopName = shopState.shop.name;
      address = [shopState.shop.addressLine1, shopState.shop.addressLine2]
          .where((s) => s.isNotEmpty)
          .join(', ');
      footer = shopState.shop.footerText;
    }

    final sb = StringBuffer();
    sb.writeln('🧾 *${context.trOnce('receipt_title')} — $shopName*');
    if (address.isNotEmpty) sb.writeln('📍 $address');
    sb.writeln('');
    for (final item in billingState.cartItems) {
      sb.writeln(
          '• ${item.product.name} ×${item.quantity}  Rs. ${item.total.toStringAsFixed(2)}');
    }
    sb.writeln('');
    sb.writeln('━━━━━━━━━━━━━━━━');
    sb.writeln(
        '*${context.trOnce('receipt_grand_total')}: Rs. ${billingState.totalAmount.toStringAsFixed(2)}*');
    sb.writeln('━━━━━━━━━━━━━━━━');
    if (footer.isNotEmpty) sb.writeln('_${footer}_');

    final ok = await ReceiptShareService.sendWhatsAppText(
        phone: phone, message: sb.toString());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.trOnce('whatsapp_not_installed')),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showShareOptions(BillingState billingState, ShopState shopState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(context.trOnce('share_receipt'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.image_outlined,
                      color: Color(0xFF6C63FF)),
                ),
                title: Text(context.trOnce('share_as_image')),
                subtitle:
                    Text(context.trOnce('png_any_app'), style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareReceiptImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                ),
                title: Text(context.trOnce('whatsapp')),
                subtitle: Text(context.trOnce('text_msg_with_items'),
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWhatsAppDialog(billingState, shopState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        context.pop();
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
              context.pop();
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.error!), backgroundColor: Colors.red));
            }
            if (state.orderConfirmed &&
                !state.isPrinting &&
                !state.printSuccess) {
              context.read<ProductBloc>().add(LoadProducts());
              context.read<DashboardBloc>().add(LoadDashboardEvent());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.trOnce('order_confirmed_stock')),
                backgroundColor: Colors.green,
              ));
            }
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.trOnce('printed_successfully')),
                backgroundColor: Colors.green,
              ));
              context.read<BillingBloc>().add(ClearCartEvent());
              context.pop();
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                final shop =
                    shopState is ShopLoaded ? shopState.shop : const Shop();
                final methods = _availableMethods(shop);

                // Auto-select first available method if none selected
                if (_selectedMethod == null && methods.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedMethod = methods.first);
                    }
                  });
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              children: [
                                // Low-stock banner
                                Builder(builder: (ctx) {
                                  final low = billingState.cartItems
                                      .where((i) =>
                                          i.product.stock > 0 &&
                                          (i.product.stock - i.quantity) <= 5)
                                      .toList();
                                  if (low.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.amber[200]!),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Colors.amber[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          context.tr('low_stock_warning').replaceAll('{n}', '${low.length}'),
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber[900]),
                                        ),
                                      ),
                                    ]),
                                  );
                                }),

                                // Items table
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
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
                                                bottom: BorderSide(
                                                    color: borderColor)),
                                          ),
                                          children: [
                                            _hCell(context.tr('product_name'),
                                                TextAlign.left),
                                            _hCell(context.tr('price'),
                                                TextAlign.right),
                                            _hCell(context.tr('total'),
                                                TextAlign.right),
                                          ],
                                        ),
                                        ...billingState.cartItems
                                            .map((item) => TableRow(
                                                  children: [
                                                    _dCell(
                                                        '${item.quantity} x ${item.product.name}',
                                                        TextAlign.left),
                                                    _dCell(
                                                        'Rs. ${item.product.price.toStringAsFixed(2)}',
                                                        TextAlign.right,
                                                        isSubtitle: true),
                                                    _dCell(
                                                        'Rs. ${item.total.toStringAsFixed(2)}',
                                                        TextAlign.right,
                                                        isBold: true),
                                                  ],
                                                )),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Payment method selector ──────────
                                if (methods.isNotEmpty) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      context.tr('select_payment_method'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[500],
                                          letterSpacing: 1),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Method chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: methods.map((m) {
                                      final selected = _selectedMethod == m;
                                      final color = _methodColor(m);
                                      return GestureDetector(
                                        onTap: () =>
                                            setState(() => _selectedMethod = m),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? color
                                                : color.withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: color.withValues(
                                                  alpha: selected ? 1 : 0.3),
                                              width: selected ? 2 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_methodIcon(m),
                                                  size: 16,
                                                  color: selected
                                                      ? Colors.white
                                                      : color),
                                              const SizedBox(width: 6),
                                              Text(
                                                _methodLabel(m),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: selected
                                                      ? Colors.white
                                                      : color,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 20),

                                  // QR / bank details for selected method
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _selectedMethod != null
                                        ? Container(
                                            key: ValueKey(_selectedMethod),
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.05),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4))
                                              ],
                                            ),
                                            child: _buildPaymentDetail(
                                                shop, billingState.totalAmount),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ] else
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.grey[400], size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            context.tr('no_payment_methods'),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                        ),

                        // ── Bottom bar ──────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(24),
                                right: Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -4))
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.tr('grand_total'),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[400],
                                          letterSpacing: 1.2),
                                    ),
                                    Text(
                                      'Rs. ${billingState.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                          color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                              if (!billingState.orderConfirmed) ...[
                                // ── Normal confirm ───────────────────────
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
                              ],
                              if (billingState.orderConfirmed) ...[
                                if (shopState is ShopLoaded)
                                  PrimaryButton(
                                    onPressed: billingState.isPrinting
                                        ? null
                                        : () => context
                                            .read<BillingBloc>()
                                            .add(PrintReceiptEvent(
                                              shopName: shop.name,
                                              address1: shop.addressLine1,
                                              address2: shop.addressLine2,
                                              phone: shop.phoneNumber,
                                              footer: shop.footerText,
                                            )),
                                    label: context.tr('print_receipt'),
                                    icon: Icons.print,
                                    isLoading: billingState.isPrinting,
                                  ),
                                // ── Save to Udhaar ───────────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showUdhaarSheet(
                                        context, billingState),
                                    icon: const Icon(
                                        Icons.menu_book_rounded,
                                        size: 18),
                                    label: Text(context.tr('save_to_udhaar_btn')),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize:
                                          const Size.fromHeight(48),
                                      side: const BorderSide(
                                          color: Color(0xFFE57373),
                                          width: 1.5),
                                      foregroundColor:
                                          const Color(0xFFE57373),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showShareOptions(
                                              billingState, shopState),
                                          icon:
                                              const Icon(Icons.share, size: 18),
                                          label:
                                              Text(context.tr('share_receipt')),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 1.5),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            context
                                                .read<BillingBloc>()
                                                .add(ClearCartEvent());
                                            context.pop();
                                          },
                                          icon:
                                              const Icon(Icons.check, size: 18),
                                          label: Text(
                                              context.tr('done_skip_printing')),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Off-screen receipt for image capture
                    Positioned(
                      left: -2000,
                      top: 0,
                      child: RepaintBoundary(
                        key: _receiptKey,
                        child: ReceiptImageWidget(
                          shopName: shop.name,
                          address1: shop.addressLine1,
                          address2: shop.addressLine2,
                          phone: shop.phoneNumber,
                          footerText: shop.footerText,
                          cartItems: billingState.cartItems,
                          total: billingState.totalAmount,
                          labelReceipt: context.trOnce('receipt_title'),
                          labelItem: context.trOnce('receipt_item_header'),
                          labelQty: context.trOnce('receipt_qty_header'),
                          labelPrice: context.trOnce('receipt_price_header'),
                          labelTotal: context.trOnce('receipt_total_header'),
                          labelGrandTotal:
                              context.trOnce('receipt_grand_total'),
                          labelThankYou: context.trOnce('receipt_thank_you'),
                          labelPoweredBy: context.trOnce('receipt_powered_by'),
                        ),
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

  Widget _hCell(String text, TextAlign align) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text.toUpperCase(),
            textAlign: align,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.grey)),
      );

  Widget _dCell(String text, TextAlign align,
          {bool isBold = false, bool isSubtitle = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Text(text,
            textAlign: align,
            style: TextStyle(
                fontSize: isSubtitle ? 12 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isSubtitle ? Colors.grey[500] : Colors.black87)),
      );

  // ── Udhaar / Khata Sheet ──────────────────────────────────────────────────

  void _showUdhaarSheet(BuildContext context, BillingState billingState) {
    final khataState = context.read<KhataBloc>().state;
    final customers = khataState.customers;

    final paidNowCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Customer? selected;
        double paidNow = 0;
        return StatefulBuilder(builder: (ctx, setSheet) {
          final total = billingState.totalAmount;
          final udhaarAmount = (total - paidNow).clamp(0.0, double.infinity);
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: Colors.red[400], size: 22),
                    const SizedBox(width: 10),
                    Text(context.trOnce('save_to_udhaar_title'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.trOnce('udhaar_sheet_desc').replaceAll('{amount}', billingState.totalAmount.toStringAsFixed(0)),
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                if (customers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off,
                              size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(context.trOnce('no_customers_khata'),
                              style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (_, i) {
                        final c = customers[i];
                        final isSelected = selected?.id == c.id;
                        return GestureDetector(
                          onTap: () =>
                              setSheet(() => selected = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red[300]!
                                    : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[400],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      if (c.phone.isNotEmpty)
                                        Text(c.phone,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                if (c.balance > 0)
                                  Text(
                                    'Rs. ${c.balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red[400],
                                        fontWeight: FontWeight.w600),
                                  ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(Icons.check_circle,
                                        color: Colors.red[400], size: 20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // ── Partial payment field ──────────────────────────────
                const SizedBox(height: 8),
                TextField(
                  controller: paidNowCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: context.trOnce('paid_now_label'),
                    prefixText: 'Rs. ',
                    prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v.trim()) ?? 0;
                    setSheet(() => paidNow = val < 0 ? 0 : val);
                  },
                ),
                const SizedBox(height: 8),
                // ── Udhaar summary row ────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: udhaarAmount > 0
                        ? Colors.red[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.trOnce('udhaar_amount_row'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: udhaarAmount > 0
                                ? Colors.red[700]
                                : Colors.green[700]),
                      ),
                      Text(
                        'Rs. ${udhaarAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: udhaarAmount > 0
                                ? Colors.red[700]
                                : Colors.green[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          udhaarAmount > 0 ? Colors.red[400] : Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                        udhaarAmount > 0 ? Icons.save_outlined : Icons.check_circle_outline),
                    label: Text(
                      selected == null
                          ? context.trOnce('select_customer_first')
                          : udhaarAmount <= 0
                              ? context.trOnce('confirm_fully_paid')
                              : context.trOnce('save_to_name_khata').replaceAll('{name}', selected!.name),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: selected == null
                        ? null
                        : () {
                            final chosenCustomer = selected!;
                            final khataBloc = context.read<KhataBloc>();

                            Navigator.of(ctx).pop();

                            if (udhaarAmount > 0) {
                              khataBloc.add(AddCreditEntryEvent(
                                customerId: chosenCustomer.id,
                                amount: udhaarAmount,
                                note:
                                    'Sale — ${billingState.cartItems.map((i) => i.product.name).join(', ')}',
                              ));

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      context.trOnce('udhaar_saved_msg')
                                          .replaceAll('{amount}', udhaarAmount.toStringAsFixed(0))
                                          .replaceAll('{name}', chosenCustomer.name)),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

