import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

Future<XFile?> pickFileImpl() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true, // Important for bytes access immediately
    );

    if (result != null && result.files.single.path != null) {
      return XFile(result.files.single.path!);
    }
    return null;
  } catch (e) {
    // If withData is true, we might get bytes directly on web, but on mobile path is key.
    // If bytes are available but path is null (rare on mobile unless stream), handle gracefully.
    return null;
  }
}
