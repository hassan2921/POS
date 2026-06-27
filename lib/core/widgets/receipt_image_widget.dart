import 'package:billing_app/features/billing/domain/entities/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Rendered off-screen via RepaintBoundary to produce a receipt PNG.
/// Wrap with RepaintBoundary and pass the key to ReceiptShareService.
class ReceiptImageWidget extends StatelessWidget {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footerText;
  final List<CartItem> cartItems;
  final double total;
  // Localized labels
  final String labelReceipt;
  final String labelItem;
  final String labelQty;
  final String labelPrice;
  final String labelTotal;
  final String labelGrandTotal;
  final String labelThankYou;
  final String labelPoweredBy;

  const ReceiptImageWidget({
    super.key,
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footerText,
    required this.cartItems,
    required this.total,
    required this.labelReceipt,
    required this.labelItem,
    required this.labelQty,
    required this.labelPrice,
    required this.labelTotal,
    required this.labelGrandTotal,
    required this.labelThankYou,
    required this.labelPoweredBy,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6C63FF);
    const bg = Color(0xFFF8F9FF);
    final now = DateFormat('dd MMM yyyy  hh:mm a').format(DateTime.now());

    return Container(
      width: 380,
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B93FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  shopName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (address1.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    address1,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (address2.isNotEmpty)
                  Text(
                    address2,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labelReceipt,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  now,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Items table ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Table header
                Row(
                  children: [
                    Expanded(flex: 4, child: _headerCell(labelItem, TextAlign.left)),
                    Expanded(flex: 1, child: _headerCell(labelQty, TextAlign.center)),
                    Expanded(flex: 2, child: _headerCell(labelPrice, TextAlign.right)),
                    Expanded(flex: 2, child: _headerCell(labelTotal, TextAlign.right)),
                  ],
                ),
                const Divider(height: 16),
                // Items
                ...cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.product.name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: _dataCell(
                              item.product.unit.isNotEmpty
                                  ? '${item.quantity} ${item.product.unit}'
                                  : '${item.quantity}',
                              TextAlign.center,
                            ),
                          ),
                          Expanded(
                              flex: 2,
                              child: _dataCell(
                                  'Rs.${item.product.price.toStringAsFixed(0)}',
                                  TextAlign.right,
                                  isGrey: true)),
                          Expanded(
                              flex: 2,
                              child: _dataCell('Rs.${item.total.toStringAsFixed(0)}',
                                  TextAlign.right,
                                  isBold: true)),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                // Grand total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labelGrandTotal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rs. ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider dashes ─────────────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1.5,
                    color: i.isEven
                        ? primaryColor.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                if (footerText.isNotEmpty)
                  Text(
                    footerText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  labelThankYou,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  labelPoweredBy,
                  style: TextStyle(
                    fontSize: 10,
                    color: primaryColor.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Returns only Text — callers must wrap with Expanded to avoid
  // competing-ParentDataWidgets when nested inside another Expanded.
  Widget _headerCell(String text, TextAlign align) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _dataCell(String text, TextAlign align,
      {bool isBold = false, bool isGrey = false}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: isGrey ? Colors.grey[500] : Colors.black87,
      ),
    );
  }
}
