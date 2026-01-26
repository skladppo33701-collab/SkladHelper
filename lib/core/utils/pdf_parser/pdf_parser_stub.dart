/// Web-safe stub for PDF parsing.
/// This prevents 'UnsupportedError' crashes when the app runs in a browser.
Future<String?> getPdfText(dynamic file) async {
  // We return null to gracefully signal that PDF parsing
  // is currently unavailable on this platform.
  return null;
}
