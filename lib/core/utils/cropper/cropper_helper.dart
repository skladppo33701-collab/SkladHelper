// This file automatically picks the right implementation
export 'cropper_stub.dart' if (dart.library.io) 'cropper_mobile.dart';
