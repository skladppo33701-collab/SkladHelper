import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

Future<MultipartFile> prepareUploadFile(String path, XFile originalFile) async {
  // Web: Read bytes from the original XFile (safe for browser)
  final bytes = await originalFile.readAsBytes();
  return MultipartFile.fromBytes(bytes, filename: 'pfp_upload.jpg');
}
