import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future<MultipartFile> prepareUploadFile(String path, XFile originalFile) async {
  // Mobile: Read directly from filesystem path (dart:io)
  return await MultipartFile.fromFile(path);
}
