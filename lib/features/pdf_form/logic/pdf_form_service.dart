import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfFormFieldInfo {
  final int index;
  final String name;
  final String type; // 'text' | 'checkbox' | 'combo' | 'radio'
  final String currentValue;
  final List<String> options;

  PdfFormFieldInfo({
    required this.index,
    required this.name,
    required this.type,
    required this.currentValue,
    this.options = const [],
  });
}

/// قراءة/تعبئة/حفظ حقول PDF التفاعلية (AcroForm) عبر Syncfusion.
class PdfFormService {
  Future<bool> hasFillableFields(String path) async {
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.form.fields.count;
    doc.dispose();
    return count > 0;
  }

  Future<List<PdfFormFieldInfo>> readFields(String path) async {
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final fields = <PdfFormFieldInfo>[];

    for (var i = 0; i < doc.form.fields.count; i++) {
      final field = doc.form.fields[i];
      final label = field.name;

      if (field is PdfTextBoxField) {
        fields.add(PdfFormFieldInfo(index: i, name: label, type: 'text', currentValue: field.text));
      } else if (field is PdfCheckBoxField) {
        fields.add(PdfFormFieldInfo(
            index: i, name: label, type: 'checkbox', currentValue: field.isChecked ? '1' : '0'));
      } else if (field is PdfComboBoxField) {
        fields.add(PdfFormFieldInfo(
          index: i,
          name: label,
          type: 'combo',
          currentValue: field.selectedValue ?? '',
          options: List<String>.generate(field.items.count, (j) => field.items[j].text),
        ));
      } else if (field is PdfRadioButtonListField) {
        fields.add(PdfFormFieldInfo(
          index: i,
          name: label,
          type: 'radio',
          currentValue: field.selectedIndex >= 0 ? field.selectedIndex.toString() : '',
          options: List<String>.generate(
              field.items.count, (j) => field.items[j].value),
        ));
      }
    }
    doc.dispose();
    return fields;
  }

  Future<String> fillAndSave(String sourcePath, Map<int, String> values,
      {bool flatten = true}) async {
    final bytes = await File(sourcePath).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);

    values.forEach((index, value) {
      final field = doc.form.fields[index];
      if (field is PdfTextBoxField) {
        field.text = value;
      } else if (field is PdfCheckBoxField) {
        field.isChecked = value == '1';
      } else if (field is PdfComboBoxField) {
        field.selectedValue = value;
      } else if (field is PdfRadioButtonListField) {
        final i = int.tryParse(value);
        if (i != null) field.selectedIndex = i;
      }
    });

    if (flatten) doc.form.flattenAllFields();

    final outBytes = await doc.save();
    doc.dispose();

    final dir = sourcePath.substring(0, sourcePath.lastIndexOf('/'));
    final outPath = '$dir/filled_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(outPath).writeAsBytes(outBytes, flush: true);
    return outPath;
  }
}