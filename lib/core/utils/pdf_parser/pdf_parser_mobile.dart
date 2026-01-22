import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';

Map<String, dynamic> parsePdf(Uint8List bytes) {
  String type = 'rot';
  String source = "Основной Склад";
  int count = 0;

  final document = PdfDocument(inputBytes: bytes);
  final extractor = PdfTextExtractor(document);
  final text = extractor.extractText();

  // Detect Type
  if (text.contains('Приходный ордер') || text.contains('ПОТ')) {
    type = 'pot';
  }

  // Identify Storage (Regex based on your PDF snippet)
  final storageMatch = RegExp(r'Склад:\s*([^\n]+)').firstMatch(text);
  if (storageMatch != null) {
    source = storageMatch.group(1)?.trim() ?? source;
  }

  // Count items by looking for SKU-like patterns (6-digit numbers)
  final skuMatches = RegExp(r'\b\d{6}\b').allMatches(text);
  count = skuMatches.length;

  return {'itemCount': count, 'type': type, 'source': source};
}
