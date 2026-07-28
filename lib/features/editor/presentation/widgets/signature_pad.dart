import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(ImageProvider?, Uint8List?) onSignatureSaved;
  const SignaturePadWidget({super.key, required this.onSignatureSaved});

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Signature(
          controller: _controller,
          height: 200,
          width: double.infinity,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _controller.clear(),
              child: const Text('مسح'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controller.isEmpty) return;
                final imageBytes = await _controller.toPngBytes();
                if (!mounted) return;
                if (imageBytes != null) {
                  final image = MemoryImage(imageBytes);
                  widget.onSignatureSaved(image, imageBytes);
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ التوقيع'),
            ),
          ],
        ),
      ],
    );
  }
}