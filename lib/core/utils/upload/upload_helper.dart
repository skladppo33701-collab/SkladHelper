// Automatically picks the right file based on the platform
export 'upload_stub.dart' if (dart.library.io) 'upload_mobile.dart';
