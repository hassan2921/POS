import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../core/bloc/language_cubit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';
import '../../../../core/service/pin_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  String shopName = 'My Shop';
                  String initials = 'MS';
                  if (state is ShopLoaded && state.shop.name.isNotEmpty) {
                    shopName = state.shop.name;
                    final parts = shopName.split(' ');
                    initials = parts
                        .take(2)
                        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
                        .join('');
                    if (initials.isEmpty) initials = 'S';
                  }
                  return Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1)),
                      ),
                      const SizedBox(height: 16),
                      Text(shopName.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Language
            _buildSectionHeader(context.tr('language_section')),
            _buildListGroup(children: [
              SwitchListTile(
                title: Text(context.tr('urdu_mode')),
                subtitle: Text(context.tr('show_app_in_urdu')),
                value: context.isUrdu,
                onChanged: (_) =>
                    context.read<LanguageCubit>().toggleLanguage(),
                activeThumbColor: AppTheme.primaryColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
            ]),

            const SizedBox(height: 24),

            // Management
            _buildSectionHeader(context.tr('management')),
            _buildListGroup(children: [
              _buildListItem(
                icon: Icons.dashboard,
                title: context.tr('dashboard'),
                subtitle: context.tr('dashboard_description'),
                onTap: () => context.push('/dashboard'),
              ),
              _buildDivider(),
              _buildListItem(
                icon: Icons.qr_code_scanner,
                title: context.tr('products'),
                subtitle: context.tr('manage_products'),
                onTap: () => context.push('/products'),
              ),
              _buildDivider(),
              _buildListItem(
                icon: Icons.storefront,
                title: context.tr('shop_details'),
                subtitle: context.tr('edit_shop_info'),
                onTap: () => context.push('/shop'),
              ),
              _buildDivider(),
              _buildListItem(
                icon: Icons.receipt_long,
                title: context.tr('sales_history'),
                subtitle: context.tr('view_sales_transactions'),
                onTap: () => context.push('/sales'),
              ),
            ]),

            const SizedBox(height: 24),

            // Security
            _buildSectionHeader(context.tr('security')),
            _buildListGroup(children: [
              _buildListItem(
                icon: Icons.lock_outline,
                title: context.tr('change_pin'),
                subtitle: context.tr('update_pin'),
                onTap: () => context.push('/change-pin'),
              ),
              _buildDivider(),
              _buildListItem(
                icon: Icons.lock,
                title: context.tr('lock_app'),
                subtitle: context.tr('lock_app_description'),
                onTap: () {
                  PinService.logout();
                  context.go('/pin');
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Hardware
            _buildSectionHeader(context.tr('hardware')),
            BlocConsumer<PrinterBloc, PrinterState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Colors.red));
                } else if (state.status == PrinterStatus.connected) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.tr('connected_to_printer')),
                      backgroundColor: Colors.green));
                }
              },
              builder: (context, state) {
                return _buildListGroup(children: [
                  _buildListItem(
                    icon: Icons.print,
                    title: context.tr('print_device'),
                    subtitleWidget: Row(
                      children: [
                        Text(
                          state.connectedMac != null
                              ? (state.connectedName ??
                                  context.tr('print_device'))
                              : context.tr('no_printer_connected'),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (state.connectedMac != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.teal[200]!),
                            ),
                            child: Text(context.tr('connected_status'),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700])),
                          ),
                        ]
                      ],
                    ),
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.status == PrinterStatus.scanning ||
                            state.status == PrinterStatus.connecting)
                          const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => context
                                .read<PrinterBloc>()
                                .add(RefreshPrinterEvent()),
                            color: AppTheme.primaryColor,
                          ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => AppSettings.openAppSettings(
                              type: AppSettingsType.bluetooth),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ]);
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                "To connect a new device, tap on the Settings gear to pair in phone's Bluetooth settings, then return and hit Refresh.",
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500]),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[50], indent: 64);
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ],
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
