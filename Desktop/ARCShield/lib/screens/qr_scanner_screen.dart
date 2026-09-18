import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'send_money_screen.dart';
import '../models/account.dart';

class QrScannerScreen extends StatefulWidget {
  final Account account;
  const QrScannerScreen({super.key, required this.account});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);
    final raw = barcode.rawValue!;

    // Parse UPI deep-link: upi://pay?pa=abc@bank&pn=Name&am=500
    String? upiId;
    String? payeeName;
    String? amount;

    if (raw.startsWith('upi://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        upiId = uri.queryParameters['pa'];
        payeeName = uri.queryParameters['pn'];
        amount = uri.queryParameters['am'];
      }
    } else if (raw.contains('@')) {
      // Plain UPI ID
      upiId = raw.trim();
    }

    _controller.stop();

    if (upiId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendMoneyScreen(
            account: widget.account,
            prefillUpiId: upiId,
            prefillName: payeeName,
            prefillAmount: amount,
          ),
        ),
      );
    } else {
      // Non-UPI QR — show raw content
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QR Code Scanned',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(raw, style: const TextStyle(color: Color(0xFF5F6368))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _scanned = false);
                    _controller.start();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B57D0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Scan Again',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ).then((_) {
        setState(() => _scanned = false);
        _controller.start();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dimming overlay with square cutout
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ScannerOverlayPainter(),
          ),

          // Instruction text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Point camera at any UPI QR code',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a semi-transparent overlay with a clear square in the center.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double cutoutSize = 260;
    final Rect cutout = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cutoutSize,
      height: cutoutSize,
    );

    // Dim everything outside the cutout
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas
      ..drawRect(
          Rect.fromLTWH(0, 0, size.width, cutout.top), dimPaint)
      ..drawRect(
          Rect.fromLTWH(0, cutout.bottom, size.width, size.height - cutout.bottom),
          dimPaint)
      ..drawRect(
          Rect.fromLTWH(0, cutout.top, cutout.left, cutoutSize), dimPaint)
      ..drawRect(
          Rect.fromLTWH(cutout.right, cutout.top, size.width - cutout.right,
              cutoutSize),
          dimPaint);

    // Corner brackets
    const double cornerLen = 28;
    const double cornerThick = 3.5;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerThick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final List<List<Offset>> corners = [
      // Top-left
      [cutout.topLeft, Offset(cutout.left + cornerLen, cutout.top),
          cutout.topLeft, Offset(cutout.left, cutout.top + cornerLen)],
      // Top-right
      [cutout.topRight, Offset(cutout.right - cornerLen, cutout.top),
          cutout.topRight, Offset(cutout.right, cutout.top + cornerLen)],
      // Bottom-left
      [cutout.bottomLeft, Offset(cutout.left + cornerLen, cutout.bottom),
          cutout.bottomLeft, Offset(cutout.left, cutout.bottom - cornerLen)],
      // Bottom-right
      [cutout.bottomRight, Offset(cutout.right - cornerLen, cutout.bottom),
          cutout.bottomRight, Offset(cutout.right, cutout.bottom - cornerLen)],
    ];

    for (final pts in corners) {
      canvas.drawLine(pts[0], pts[1], cornerPaint);
      canvas.drawLine(pts[2], pts[3], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
