import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../config/routes/app_routes.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver, RouteAware {
  late MobileScannerController controller;
  bool _isScanned = false;

  // ────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global RouteObserver so we receive route-level
    // visibility callbacks.  This is the reliable way to detect that a
    // push-route covered us or was popped away, especially on MIUI.
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  void _initController() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
      formats: const [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // RouteAware — fired when a route is pushed ON TOP of us / popped away.
  // These are the callbacks MIUI misses with the plain lifecycle observer.
  // ────────────────────────────────────────────────────────────────────

  /// A new route was pushed on top of this one — stop the camera.
  @override
  void didPushNext() {
    controller.stop();
  }

  /// The route that was on top of us was popped — restart the camera.
  @override
  void didPopNext() {
    _restartCamera();
  }

  // ────────────────────────────────────────────────────────────────────
  // App lifecycle — only for true background / foreground transitions
  // that RouteObserver does not cover.
  // ────────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Only restart if we are still the top-most route; the RouteAware
        // callbacks handle the route-push case, so this guards against the
        // app returning from the device home screen / task switcher.
        _restartCamera();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }

  /// Restarts the camera cleanly — recreates the controller if stop/start fails.
  Future<void> _restartCamera() async {
    try {
      await controller.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await controller.start();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(_initController);
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────
  // Barcode detection
  // ────────────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isScanned = true;

        // Stop camera immediately so it doesn't keep scanning
        await controller.stop();

        // Beep and vibrate on successful scan
        SystemSound.play(SystemSoundType.click);
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate();
        }

        if (mounted) {
          context.pop(barcode.rawValue);
        }
        break;
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () async {
            // Capture router before the async gap to satisfy
            // use_build_context_synchronously lint.
            final nav = GoRouter.of(context);
            await controller.stop();
            if (mounted) nav.pop();
          },
        ),
        title: Text(context.tr('scan_barcode'),
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Frame overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent, width: 0),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _corner(0),
                          _corner(1),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _corner(3),
                          _corner(2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              context.tr('align_barcode'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(int index) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
