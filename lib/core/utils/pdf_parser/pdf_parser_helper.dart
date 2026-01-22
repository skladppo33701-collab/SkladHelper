// Correct way: Default to STUB (Web), switch to MOBILE if dart.io exists
export 'pdf_parser_stub.dart' if (dart.library.io) 'pdf_parser_mobile.dart';
