import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../logic/pdf_form_service.dart';
import '../../../../core/widgets/common_button.dart';

class PdfFormScreen extends StatefulWidget {
  final String pdfPath;
  const PdfFormScreen({super.key, required this.pdfPath});

  @override
  State<PdfFormScreen> createState() => _PdfFormScreenState();
}

class _PdfFormScreenState extends State<PdfFormScreen> {
  final _service = PdfFormService();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _selections = {};
  List<PdfFormFieldInfo> _fields = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fields = await _service.readFields(widget.pdfPath);
      for (final f in fields) {
        if (f.type == 'text') {
          _controllers[f.index] = TextEditingController(text: f.currentValue);
        } else {
          _selections[f.index] = f.currentValue;
        }
      }
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّرت قراءة حقول هذا الملف';
        _loading = false;
      });
    }
  }

  Future<void> _saveAndShare({required bool print}) async {
    setState(() => _saving = true);
    try {
      final values = <int, String>{};
      for (final f in _fields) {
        values[f.index] = f.type == 'text' ? (_controllers[f.index]?.text ?? '') : (_selections[f.index] ?? '');
      }
      final outPath = await _service.fillAndSave(widget.pdfPath, values);
      if (!mounted) return;
      if (print) {
        await Printing.layoutPdf(onLayout: (_) => File(outPath).readAsBytes());
      } else {
        await Share.shareXFiles([XFile(outPath)], text: 'نموذج معبّى من MN Doc');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ النموذج المعبّى')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعبئة النموذج')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _fields.isEmpty
                  ? const Center(child: Text('هذا الملف لا يحتوي حقولاً قابلة للتعبئة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _fields.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildFieldWidget(_fields[i]),
                      ),
                    ),
      bottomNavigationBar: _fields.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        label: 'حفظ ومشاركة',
                        variant: CommonButtonVariant.outlined,
                        isLoading: _saving,
                        onPressed: () => _saveAndShare(print: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonButton(
                        label: 'حفظ وطباعة',
                        isLoading: _saving,
                        onPressed: () => _saveAndShare(print: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldWidget(PdfFormFieldInfo field) {
    switch (field.type) {
      case 'checkbox':
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.name),
          value: _selections[field.index] == '1',
          onChanged: (v) => setState(() => _selections[field.index] = (v ?? false) ? '1' : '0'),
        );
      case 'combo':
      case 'radio':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: field.name),
          value: _selections[field.index]?.isNotEmpty == true ? _selections[field.index] : null,
          items: field.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => setState(() => _selections[field.index] = v ?? ''),
        );
      default:
        return TextField(
          controller: _controllers[field.index],
          decoration: InputDecoration(labelText: field.name),
        );
    }
  }
}