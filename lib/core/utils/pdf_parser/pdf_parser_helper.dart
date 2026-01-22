// This file automatically picks the right implementation
export 'pdf_parser_stub.dart' if (dart.library.io) 'pdf_parser_mobile.dart';
