import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

// Core & Theme
import '../../../../core/theme.dart';
// Corrected path to auth_provider
import '../services/document_service.dart';

enum UploadStep { idle, uploading, scanning, validating, optimizing, complete }

class WebUploadPage extends ConsumerStatefulWidget {
  const WebUploadPage({super.key});

  @override
  ConsumerState<WebUploadPage> createState() => _WebUploadPageState();
}

class _WebUploadPageState extends ConsumerState<WebUploadPage> {
  PlatformFile? _pickedFile;
  UploadStep _currentStep = UploadStep.idle;
  String _docType = 'auto';

  final DocumentService _documentService = DocumentService();

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          final name = _pickedFile!.name.toLowerCase();
          if (name.contains('rot')) {
            _docType = 'rot';
          } else if (name.contains('pot')) {
            _docType = 'pot';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Ошибка выбора файла: $e');
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    // Start the agentic sequence
    setState(() => _currentStep = UploadStep.uploading);

    try {
      // Step 1: Uploading (Artificial delay for UX perception)
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Scanning Structure
      if (!mounted) return;
      setState(() => _currentStep = UploadStep.scanning);
      await Future.delayed(const Duration(milliseconds: 1200));

      // Step 3: Validating Schema (Actual processing happens here)
      if (!mounted) return;
      setState(() => _currentStep = UploadStep.validating);

      // Perform the actual heavy lifting
      await _documentService.processUpload(
        _pickedFile!.bytes!,
        _pickedFile!.name,
      );

      // Step 4: Optimization
      if (!mounted) return;
      setState(() => _currentStep = UploadStep.optimizing);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 5: Complete
      if (!mounted) return;
      setState(() => _currentStep = UploadStep.complete);
      await Future.delayed(const Duration(milliseconds: 500));

      _showSuccessSnackBar('Документ успешно обработан и добавлен в базу');

      if (!mounted) return;
      setState(() {
        _pickedFile = null;
        _docType = 'auto';
        _currentStep = UploadStep.idle;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
      setState(() => _currentStep = UploadStep.idle);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).extension<SkladColors>()?.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: proColors.surfaceLow,
      appBar: AppBar(
        title: Text(
          "Импорт (Web)",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 48),
                _buildDropZone(proColors, isDark),
                const SizedBox(height: 32),
                if (_pickedFile != null) _buildActions(proColors, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          "Автоматизация Склада",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Загрузите накладную в формате Excel или PDF для автоматического распознавания товаров и создания задач.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDropZone(SkladColors proColors, bool isDark) {
    final isProcessing = _currentStep != UploadStep.idle;

    return InkWell(
      onTap: isProcessing ? null : _pickFile,
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: proColors.accentAction.withValues(alpha: 0.3),
          strokeWidth: 2,
          radius: 24,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 280,
          decoration: BoxDecoration(
            color: proColors.surfaceHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_pickedFile == null) ...[
                Icon(
                  Icons.upload_file_rounded,
                  size: 64,
                  color: proColors.accentAction,
                ),
                const SizedBox(height: 20),
                Text(
                  "Выбрать файл",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: proColors.accentAction,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ".xlsx, .xls, .pdf",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: proColors.success,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _pickedFile!.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(SkladColors proColors, bool isDark) {
    if (_currentStep != UploadStep.idle) {
      return _buildAgenticProgress(proColors, isDark);
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _docType,
          decoration: InputDecoration(
            labelText: "Тип документа",
            filled: true,
            fillColor: proColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'auto', child: Text("Автоматически")),
            DropdownMenuItem(value: 'rot', child: Text("Расход (РОТ)")),
            DropdownMenuItem(value: 'pot', child: Text("Приход (ПОТ)")),
          ],
          onChanged: (val) => setState(() => _docType = val!),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _uploadAndProcess,
            style: ElevatedButton.styleFrom(
              backgroundColor: proColors.accentAction,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Импортировать в базу",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _pickedFile = null),
          child: const Text("Сбросить выбор"),
        ),
      ],
    );
  }

  Widget _buildAgenticProgress(SkladColors proColors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: proColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: proColors.accentAction.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "AI Process",
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: proColors.accentAction,
                ),
              ),
              const Spacer(),
              if (_currentStep != UploadStep.complete)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: proColors.accentAction,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            "Загрузка файла",
            UploadStep.uploading,
            proColors,
            isDark,
          ),
          _buildStepRow(
            "Сканирование структуры",
            UploadStep.scanning,
            proColors,
            isDark,
          ),
          _buildStepRow(
            "Валидация схемы",
            UploadStep.validating,
            proColors,
            isDark,
          ),
          _buildStepRow(
            "Оптимизация запасов",
            UploadStep.optimizing,
            proColors,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    String title,
    UploadStep step,
    SkladColors colors,
    bool isDark,
  ) {
    // Determine the state of this specific row
    final stepIndex = UploadStep.values.indexOf(step);
    final currentIndex = UploadStep.values.indexOf(_currentStep);

    bool isCompleted = currentIndex > stepIndex;
    bool isActive = currentIndex == stepIndex;

    Color textColor;
    if (isCompleted || isActive) {
      textColor = isDark ? Colors.white : Colors.black87;
    } else {
      textColor = Colors.grey.shade500;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? colors.success
                  : isActive
                  ? colors.accentAction
                  : colors.surfaceLow,
              border: Border.all(
                color: isCompleted || isActive
                    ? Colors.transparent
                    : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : isActive
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = Path();
    double dashWidth = 10.0;
    double dashSpace = 6.0;
    double distance = 0.0;

    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
