import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/participation_provider.dart';

class AdminQRScannerScreen extends StatefulWidget {
  final Event? event;

  const AdminQRScannerScreen({super.key, this.event});

  @override
  State<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || widget.event == null) return;

    final List<Barcode> qrCodes = capture.barcodes;
    for (final qrCode in qrCodes) {
      if (qrCode.format == BarcodeFormat.qrCode && qrCode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        final code = qrCode.rawValue!;
        debugPrint('QR Code found: $code');

        try {
          final studentId = int.parse(code);
          final participationProvider = Provider.of<ParticipationProvider>(
            context,
            listen: false,
          );
          await participationProvider.adminRecordParticipation(
            studentId,
            widget.event!.id,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Attendance recorded for ${widget.event!.title}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint('Error processing QR code: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Invalid QR code or error recording participation',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            setState(() {
              _isProcessing = false;
            });
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          const _ScannerOverlay(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surface.withOpacity(0.5),
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Scan for: ${widget.event?.title ?? 'Event'}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ValueListenableBuilder(
                  valueListenable: cameraController,
                  builder: (context, state, child) {
                    final isAuth = state.torchState == TorchState.on;
                    return IconButton.filled(
                      onPressed: () => cameraController.toggleTorch(),
                      style: IconButton.styleFrom(
                        backgroundColor: isAuth
                            ? colorScheme.primary
                            : colorScheme.surface.withOpacity(0.5),
                        foregroundColor: isAuth
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        padding: const EdgeInsets.all(16),
                      ),
                      iconSize: 28,
                      icon: Icon(isAuth ? Icons.flash_on : Icons.flash_off),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isProcessing ? 'Processing...' : 'Align code in frame',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => cameraController.switchCamera(),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surface.withOpacity(0.5),
                    foregroundColor: colorScheme.onSurface,
                    padding: const EdgeInsets.all(16),
                  ),
                  iconSize: 28,
                  icon: const Icon(Icons.cameraswitch_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.scrim.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
