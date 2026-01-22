import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Mobile version: Opens native cropper
Future<String?> cropImageIfPossible(XFile file) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: file.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Редактировать',
        toolbarColor: Colors.black,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
      ),
      IOSUiSettings(title: 'Редактировать', aspectRatioLockEnabled: true),
    ],
  );
  return croppedFile?.path;
}
