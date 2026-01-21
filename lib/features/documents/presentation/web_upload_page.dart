import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart'; // Add dotted_border to pubspec.yaml for the UI effect
import 'package:sklad_helper_33701/core/theme.dart';
import '../services/excel_service.dart'; // Make sure this file exists from previous steps

class WebUploadPage extends StatefulWidget {
  const WebUploadPage({super.key});

  @override
  State<WebUploadPage> createState() => _WebUploadPageState();
}

class _WebUploadPageState extends State<WebUploadPage> {
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String _docType = 'auto'; // 'auto', 'rot', 'pot'

  final ExcelService _excelService = ExcelService();

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // IMPORTANT: Required for Web to get bytes
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          // Auto-detect type from filename
          if (_pickedFile!.name.toLowerCase().contains('rot')) {
            _docType = 'rot';
          } else if (_pickedFile!.name.toLowerCase().contains('pot')) {
            _docType = 'pot';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    setState(() => _isUploading = true);

    try {
      // Pass the bytes directly to the service
      await _excelService.uploadAndParseExcel(
        _pickedFile!.bytes!,
        _pickedFile!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл успешно загружен и обработан')),
        );
        setState(() => _pickedFile = null); // Reset
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обработки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      appBar: AppBar(
        title: const Text("Загрузка документов (Web)"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Web-friendly width
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER
              Text(
                "Импорт накладных (Excel)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Загрузите файлы РОТ или ПОТ для автоматического создания задач на складе.",
                textAlign: TextAlign.center,
                style: TextStyle(color: proColors.neutralGray, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // 2. DROP ZONE (Visual)
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(20),
                child: DottedBorder(
                  color: proColors.accentAction.withOpacity(0.5),
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(20),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: proColors.surfaceHigh.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_pickedFile == null) ...[
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: proColors.accentAction,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Нажмите чтобы выбрать файл",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: proColors.accentAction,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Поддерживаются .xlsx, .xls",
                            style: TextStyle(color: proColors.neutralGray),
                          ),
                        ] else ...[
                          Icon(
                            Icons.description,
                            size: 64,
                            color: proColors.success,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pickedFile!.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                            style: TextStyle(color: proColors.neutralGray),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 3. SETTINGS & ACTION
              if (_pickedFile != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _docType,
                        decoration: InputDecoration(
                          labelText: "Тип документа",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'auto',
                            child: Text("Автоматически"),
                          ),
                          DropdownMenuItem(
                            value: 'rot',
                            child: Text("РОТ (Расход)"),
                          ),
                          DropdownMenuItem(
                            value: 'pot',
                            child: Text("ПОТ (Приход)"),
                          ),
                        ],
                        onChanged: (val) => setState(() => _docType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadAndProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: proColors.accentAction,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Загрузить и Обработать",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
