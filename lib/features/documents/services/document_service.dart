import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';
import 'package:sklad_helper_33701/features/assignments/services/assignment_parser.dart';
import 'package:sklad_helper_33701/features/documents/models/warehouse_document.dart';
import 'package:sklad_helper_33701/core/utils/result.dart'; // [PROTOCOL-ARCH-1]

class DocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<WarehouseDocument>> getDocuments() {
    return _db
        .collection('documents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WarehouseDocument.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// [PROTOCOL-ARCH-1] Functional Error Handling
  /// Orchestrates the upload process: parses the file and saves the assignment.
  /// Returns a Result type instead of throwing.
  Future<Result<void, AppFailure>> processUpload(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      Assignment? assignment;

      // 1. Determine parsing logic based on file extension
      if (fileName.toLowerCase().endsWith('.xlsx') ||
          fileName.toLowerCase().endsWith('.xls')) {
        // [PROTOCOL-ARCH-2] Use Isolate for parsing
        final parseResult = await AssignmentParser.parseExcelIsolate(
          bytes,
          fileName,
        );

        if (parseResult is Failure<Assignment, AppFailure>) {
          return Failure(parseResult.value);
        }

        assignment = (parseResult as Success<Assignment, AppFailure>).value;
      } else {
        return const Failure(
          ValidationFailure(
            "Формат файла не поддерживается. Используйте Excel (.xlsx, .xls)",
          ),
        );
      }

      // 2. Persist the parsed assignment to Firestore
      final assignmentData = {
        'title': assignment.name,
        'name': assignment.name,
        'type': assignment.type,
        'status': assignment.status.index,
        'createdAt': assignment.createdAt.toIso8601String(),
        'items': assignment.items
            .map(
              (i) => {
                'name': i.name,
                'code': i.code,
                'requiredQty': i.requiredQty,
                'collectedQty': 0,
              },
            )
            .toList(),
      };

      await _db
          .collection('assignments')
          .doc(assignment.id)
          .set(assignmentData);

      // 3. Create a Document record for history
      await _db.collection('documents').add({
        'name': fileName,
        'type': 'Imported',
        'timestamp': FieldValue.serverTimestamp(),
        'relatedAssignmentId': assignment.id,
      });

      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure("Ошибка сохранения: $e"));
    }
  }

  Future<void> saveDocument(WarehouseDocument doc) async {
    await _db
        .collection('documents')
        .doc(doc.id.isEmpty ? null : doc.id)
        .set(doc.toMap());
  }

  Future<void> deleteDocument(String id) async {
    await _db.collection('documents').doc(id).delete();
  }
}
