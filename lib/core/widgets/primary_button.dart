import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.elevation = 8.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.isFullWidth = true,
    this.textStyle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
      minimumSize: isFullWidth ? const Size.fromHeight(44) : null,
    );

    Widget buttonWidget;
    if (icon != null) {
      buttonWidget = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          label,
          style: textStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        style: style,
      );
    } else {
      buttonWidget = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: textStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottomPadding > 0 ? bottomPadding + 12 : 24.0,
      ),
      child: buttonWidget,
    );
  }
}
