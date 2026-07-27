import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(ImageProvider?) onSignatureSaved;
  const SignaturePadWidget({Key? key, required this.onSignatureSaved})
      : super(key: key);

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

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
                if (imageBytes != null) {
                  final image = MemoryImage(imageBytes);
                  widget.onSignatureSaved(image);
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