// Automatically picks the right file based on the platform
export 'upload_stub.dart' if (dart.library.io) 'upload_mobile.dart';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
// Import the platform specific implementation with an alias to avoid namespace collisions
import 'upload_stub.dart' if (dart.library.io) 'upload_mobile.dart' as impl;

class UploadHelper {
  /// Picks a single file using the platform-specific implementation
  static Future<XFile?> pickFile() async {
    return impl.pickFileImpl();
  }

  /// Prepares a file for Dio upload (MultipartFile)
  static Future<MultipartFile> prepareUploadFile(
    String path,
    XFile originalFile,
  ) async {
    // Creates a MultipartFile from the path using Dio
    return await MultipartFile.fromFile(path, filename: originalFile.name);
  }
}
