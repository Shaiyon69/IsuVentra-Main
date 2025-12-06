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
              const SnackBar(
                content: Text('Participation recorded successfully!'),
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint('Error processing QR code: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid QR code or error recording participation',
                ),
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
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Scan Student QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
                        backgroundColor: isAuth ? Colors.white : Colors.black54,
                        foregroundColor: isAuth ? Colors.black : Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      iconSize: 28,
                      icon: Icon(isAuth ? Icons.flash_on : Icons.flash_off),
                    );
                  },
                ),
                Text(
                  'Align code in frame',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                IconButton.filled(
                  onPressed: () => cameraController.switchCamera(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
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
      colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
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
