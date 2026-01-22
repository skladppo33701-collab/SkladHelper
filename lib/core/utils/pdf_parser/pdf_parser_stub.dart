import 'dart:typed_data';

Map<String, dynamic> parsePdf(Uint8List bytes) {
  // On web: Skip actual parsing (or implement with pdf.js via dart:js if needed later)
  // For now, return dummy data or throw to alert user
  throw UnsupportedError(
    'PDF parsing is not yet supported on web. Use XLSX or contact support.',
  );

  // Alternative: Return dummy if you want to allow upload without parsing
  // return {'itemCount': 0, 'type': 'unknown', 'source': 'Web Upload'};
}
