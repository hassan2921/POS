import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/khata_bloc.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/khata_entry.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/service/receipt_share_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<KhataBloc>()
        .add(LoadCustomerEntriesEvent(widget.customer.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KhataBloc, KhataState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
          ));
        }
      },
      builder: (context, state) {
        // Get latest customer balance from state (it may have changed)
        final customer = state.customers.firstWhere(
          (c) => c.id == widget.customer.id,
          orElse: () => widget.customer,
        );
        final hasBalance = customer.balance > 0;
        final hasAdvance = customer.balance < 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(customer.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // ── Customer header card ────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              if (customer.phone.isNotEmpty)
                                Text(customer.phone,
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13)),
                            ],
                          ),
                        ),
                        // Balance
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${customer.balance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: hasBalance
                                    ? Colors.red[700]
                                    : hasAdvance
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                              ),
                            ),
                            Text(
                              hasBalance
                                  ? context.tr('outstanding')
                                  : hasAdvance
                                      ? context.tr('advance')
                                      : context.tr('no_udhaar'),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasBalance
                                    ? Colors.red[400]
                                    : hasAdvance
                                        ? Colors.blue[400]
                                        : Colors.green[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasBalance && customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(38),
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: Text(
                          context.isUrdu ? 'واٹس ایپ پر یاد دہانی بھیجیں' : 'Send WhatsApp Reminder',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _sendWhatsappReminder(customer),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Entries header ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(context.tr('ledger'),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 1.2)),
                    const Spacer(),
                    Text('${state.selectedEntries.length} ${context.tr('entries')}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),

              // ── Entry list ─────────────────────────────────────────────
              Expanded(
                child: state.isLoadingEntries
                    ? const Center(child: CircularProgressIndicator())
                    : state.selectedEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(context.tr('no_transactions'),
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: state.selectedEntries.length,
                            itemBuilder: (ctx, i) => _buildEntryTile(
                                state.selectedEntries[i]),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 16.0,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
                        foregroundColor: const Color(0xFFE57373),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(context.tr('add_udhaar'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddUdhaarDialog(context, customer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(context.tr('record_payment'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      onPressed: () => _showPaymentDialog(context, customer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryTile(KhataEntry entry) {
    final isCredit = entry.type == KhataEntryType.credit;
    final dateStr = DateFormat('dd MMM yyyy  hh:mm a').format(entry.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          // Icon indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? Colors.red[50] : Colors.green[50],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCredit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isCredit ? Colors.red[600] : Colors.green[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCredit ? context.tr('udhaar_credit') : context.tr('payment_received'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (entry.note.isNotEmpty)
                  Text(entry.note,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                Text(dateStr,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} Rs. ${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isCredit ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUdhaarDialog(BuildContext context, customer) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.add_circle_outline,
              color: Color(0xFFE57373), size: 22),
          const SizedBox(width: 10),
          Text(context.tr('record_udhaar_title'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.tr('amount_given_label'),
                  prefixText: 'Rs. ',
                  prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return context.trOnce('enter_amount');
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) return context.trOnce('enter_valid_amount');
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('note_optional'),
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel'),
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<KhataBloc>().add(AddCreditEntryEvent(
                      customerId: customer.id,
                      amount: double.parse(amountCtrl.text.trim()),
                      note: noteCtrl.text.trim(),
                    ));
                Navigator.pop(ctx);
              }
            },
            child: Text(context.tr('add_udhaar')),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, customer) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.payments_outlined,
              color: Colors.green[600], size: 22),
          const SizedBox(width: 10),
          Text(context.tr('record_payment'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer.balance > 0
                    ? '${context.tr('outstanding_prefix')}${customer.balance.toStringAsFixed(0)}'
                    : customer.balance < 0
                        ? '${context.tr('advance')}: Rs. ${customer.balance.abs().toStringAsFixed(0)}'
                        : context.tr('no_udhaar'),
                style: TextStyle(
                    fontSize: 13,
                    color: customer.balance > 0
                        ? Colors.red[600]
                        : customer.balance < 0
                            ? Colors.blue[600]
                            : Colors.green[600],
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.tr('amount_received'),
                  prefixText: 'Rs. ',
                  prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return context.trOnce('enter_amount');
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) return context.trOnce('enter_valid_amount');
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('note_optional'),
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(context.tr('cancel'), style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<KhataBloc>().add(AddPaymentEvent(
                      customerId: customer.id,
                      amount: double.parse(amountCtrl.text.trim()),
                      note: noteCtrl.text.trim(),
                    ));
                Navigator.pop(ctx);
              }
            },
            child: Text(context.tr('save_payment')),
          ),
        ],
      ),
    );
  }

  String _sanitizePhoneForWhatsApp(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('03') && digitsOnly.length == 11) {
      return '92${digitsOnly.substring(1)}';
    }
    if (digitsOnly.startsWith('3') && digitsOnly.length == 10) {
      return '92$digitsOnly';
    }
    if (digitsOnly.startsWith('0092') && digitsOnly.length == 14) {
      return digitsOnly.substring(2);
    }
    return digitsOnly;
  }

  Future<void> _sendWhatsappReminder(Customer customer) async {
    final outstanding = customer.balance.abs().toStringAsFixed(0);
    final message = context.isUrdu
        ? 'محترم ${customer.name}، یہ ایک دوستانہ یاد دہانی ہے کہ آپ کی بقایا رقم $outstanding روپے ہے۔ براہ کرم جلد از جلد ادائیگی کریں۔ شکریہ!'
        : 'Dear ${customer.name}, this is a friendly reminder that your outstanding balance is Rs. $outstanding. Please clear it at your earliest convenience. Thank you!';

    final formattedPhone = _sanitizePhoneForWhatsApp(customer.phone);
    final ok = await ReceiptShareService.sendWhatsAppText(
        phone: formattedPhone, message: message);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.isUrdu ? 'واٹس ایپ انسٹال نہیں ہے!' : 'WhatsApp is not installed!'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
