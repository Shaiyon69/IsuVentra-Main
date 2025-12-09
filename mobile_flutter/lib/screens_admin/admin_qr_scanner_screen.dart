import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/participation_provider.dart';
import '../providers/student_provider.dart';

class HollowCenterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    const double scanAreaSize = 250;
    Rect centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );
    Path centerPath = Path()..addRect(centerRect);
    return Path.combine(PathOperation.difference, fullPath, centerPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AdminQRScannerScreen extends StatefulWidget {
  final Event? event;
  const AdminQRScannerScreen({super.key, this.event});

  @override
  State<AdminQRScannerScreen> createState() => _AdminQRScannerScreenState();
}

class _AdminQRScannerScreenState extends State<AdminQRScannerScreen> {
  // Fix: Set autoStart to false to prevent race conditions, let widget handle it
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: true,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;
  bool _qrDetected = false;
  String? _lastScanned;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || widget.event == null) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code == null) continue;
      if (_lastScanned == code) return;

      setState(() {
        _qrDetected = true;
        _lastScanned = code;
        _isProcessing = true;
      });

      _processScan(code);
      break;
    }
  }

  Future<void> _processScan(String code) async {
    try {
      final studentProvider = Provider.of<StudentProvider>(
        context,
        listen: false,
      );
      final student = await studentProvider.fetchStudentByStudentId(code);

      if (student == null) {
        _showFeedback('Student not found in database.', isError: true);
        return;
      }

      if (mounted) {
        // Confirmation Dialog
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${student.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('ID: ${student.studentId}'),
                const Divider(),
                Text('Event: ${widget.event!.title}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final participationProvider = Provider.of<ParticipationProvider>(
            context,
            listen: false,
          );

          try {
            // Perform Scan
            final successMsg = await participationProvider
                .adminRecordParticipation(
                  student.id,
                  widget.event!.id,
                  studentName: student.name,
                );

            if (mounted) {
              _showFeedback(successMsg, isError: false);
            }
          } catch (e) {
            final msg = e.toString().replaceAll('Exception:', '').trim();

            // Handle "Fully Attended" warning
            if (msg.toLowerCase().contains('fully attended') ||
                msg.contains('completed')) {
              _showFeedback(msg, isWarning: true);
            } else {
              _showFeedback(msg, isError: true);
            }
          }
        } else {
          _resetScan();
        }
      }
    } catch (e) {
      _showFeedback('Error: ${e.toString()}', isError: true);
    }
  }

  void _showFeedback(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;

    Color bg;
    IconData icon;

    if (isError) {
      bg = Colors.red;
      icon = Icons.error_outline;
    } else if (isWarning) {
      bg = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
    } else {
      bg = Colors.green;
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
      ),
    );

    // Delay slightly before allowing next scan
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _resetScan();
      }
    });
  }

  void _resetScan() {
    setState(() {
      _isProcessing = false;
      _qrDetected = false;
      _lastScanned = null;
    });
  }

  Widget _buildCorner(Color color, bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isTop ? color : Colors.transparent, width: 4),
          bottom: BorderSide(
            color: isTop ? Colors.transparent : color,
            width: 4,
          ),
          left: BorderSide(
            color: isLeft ? color : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: isLeft ? Colors.transparent : color,
            width: 4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.event?.title ?? 'QR Scanner'),
        backgroundColor: colorScheme.surface.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          ClipPath(
            clipper: HollowCenterClipper(),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(colorScheme.primary, true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(colorScheme.primary, true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(colorScheme.primary, false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(colorScheme.primary, false, false),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "flash",
            onPressed: () => controller.toggleTorch(),
            child: const Icon(Icons.flash_on),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "switch",
            onPressed: () => controller.switchCamera(),
            child: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
    );
  }
}
