import 'package:image_picker/image_picker.dart';

/// Web version: Returns original path (no cropping)
Future<String?> cropImageIfPossible(XFile file) async {
  return file.path;
}
