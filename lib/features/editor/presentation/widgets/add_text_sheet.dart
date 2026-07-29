import 'package:flutter/material.dart';
import '../../logic/editor_provider.dart';

/// نافذة إضافة نص — Bottom Sheet بدل Dialog تقليدي.
class AddTextSheet extends StatefulWidget {
  final EditorProvider editor;
  const AddTextSheet({super.key, required this.editor});

  static Future<void> show(BuildContext context, EditorProvider editor) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddTextSheet(editor: editor),
      ),
    );
  }

  @override
  State<AddTextSheet> createState() => _AddTextSheetState();
}

class _AddTextSheetState extends State<AddTextSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = widget.editor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('أضف نصاً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'اكتب النص هنا')),
          const SizedBox(height: 16),
          Row(children: [
            const Text('الحجم: '),
            Expanded(
              child: AnimatedBuilder(
                animation: editor,
                builder: (context, _) => Slider(
                  value: editor.textSize,
                  min: 12,
                  max: 48,
                  divisions: 9,
                  label: editor.textSize.round().toString(),
                  onChanged: editor.setTextSize,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: AnimatedBuilder(
              animation: editor,
              builder: (context, _) => ListView(
                scrollDirection: Axis.horizontal,
                children: Colors.primaries
                    .map((color) => GestureDetector(
                          onTap: () => editor.setTextColor(color),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: editor.textColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                editor.addText(_controller.text, const Offset(50, 50));
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}