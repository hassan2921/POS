import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiptShareService {
  /// Captures the widget attached to [boundaryKey] as a PNG,
  /// saves it to a temp file, and shares via the system share sheet.
  static Future<void> shareAsImage({
    required GlobalKey boundaryKey,
    String filename = 'receipt.png',
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: filename,
    );
  }

  /// Sends the receipt as a WhatsApp text message.
  /// Falls back to wa.me web link if the app scheme fails.
  static Future<bool> sendWhatsAppText({
    required String phone,
    required String message,
  }) async {
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final encoded = Uri.encodeComponent(message);
    final appUrl =
        Uri.parse('whatsapp://send?phone=$sanitizedPhone&text=$encoded');
    final webUrl = Uri.parse('https://wa.me/$sanitizedPhone?text=$encoded');

    try {
      final launched =
          await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      if (launched) return true;
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }
}
