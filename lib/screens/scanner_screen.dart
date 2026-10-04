import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../utils/qr_payload.dart';

/// Camera-based scanner screen for reading HTD payment and wallet QR codes.
///
/// Returns the parsed [QrPayload] when a valid QR code is scanned or entered.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;

      final payload = QrPayload.decode(raw);
      if (payload != null) {
        _hasScanned = true;
        Navigator.of(context).pop(payload);
        return;
      }
    }
  }

  Future<void> _showManualEntryDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Paste or Enter QR Payload',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'For testing or environments without a camera:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'htd:0x... or 0x...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                textController.text = 'htd:0x71C8394A84e52514d7a9bA7879e604f323B049B2?amount=25.00&ref=DEMO-101';
              },
              child: const Text('Use Sample Invoice (H\$ 25.00)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCC419),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(textController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final payload = QrPayload.decode(result);
      if (payload != null) {
        _hasScanned = true;
        Navigator.of(context).pop(payload);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR format. Expected htd:<address> or 0x...'),
            backgroundColor: Color(0xFFE03131),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Payment QR',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Manual entry / Demo QR',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        size: 54,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera unavailable (${error.errorCode.name})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ensure camera permission is granted in your browser or device settings, or use manual entry for testing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFCC419),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _showManualEntryDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Enter QR Payload Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Central viewfinder reticle
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFCC419), width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Helper instruction text
          const Positioned(
            left: 20,
            right: 20,
            bottom: 60,
            child: Text(
              'Point the camera at the merchant\'s or recipient\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
