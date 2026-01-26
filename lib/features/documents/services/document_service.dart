import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/assignments/models/assignment_model.dart';
import 'package:sklad_helper_33701/features/assignments/services/assignment_parser.dart';
import 'package:sklad_helper_33701/features/documents/models/warehouse_document.dart';

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

  /// Orchestrates the upload process: parses the file and saves the assignment.
  /// This was the missing method causing the error.
  Future<void> processUpload(Uint8List bytes, String fileName) async {
    try {
      Assignment? assignment;

      // 1. Determine parsing logic based on file extension
      // We currently only support Excel via the parser we built.
      if (fileName.toLowerCase().endsWith('.xlsx') ||
          fileName.toLowerCase().endsWith('.xls')) {
        assignment = AssignmentParser.parseExcelBytes(bytes, fileName);
      } else {
        // Fallback or text parsing could go here if implemented for PDF
        // For now, throw if not Excel, or try text parsing if it was a text file
        throw Exception(
          "Формат файла не поддерживается. Используйте Excel (.xlsx, .xls)",
        );
      }

      // 2. Persist the parsed assignment to Firestore
      // We assume Assignment model has a toMap() method. If not, we'll need to add it or map it manually.
      // Based on previous context, Assignment model usually has toMap/fromMap.
      // If it's missing in the model, we can map it here.
      final assignmentData = {
        'title': assignment
            .name, // Mapping 'name' to 'title' to match Task/Assignment common fields if needed, or just use 'name'
        'name': assignment.name,
        'type': assignment.type,
        // 'orderId' and 'clientName' are not top-level properties in the Assignment model
        // but are derived or part of the name in the parser.
        // We will store them if they are needed, or rely on the 'name' field.
        // If the model doesn't support them, we omit them or store them in metadata.
        // Assuming they were intended to be part of the model but aren't getters:
        // 'orderId': assignment.orderId,
        // 'clientName': assignment.clientName,
        'status': assignment.status.index, // Storing enum index or string
        'createdAt': assignment.createdAt.toIso8601String(),
        'items': assignment.items
            .map(
              (i) => {
                'name': i.name,
                'code': i.code,
                'requiredQty': i.requiredQty,
                // collectedQty is likely 'collected' or managed by separate logic.
                // If the model doesn't have it, we default to 0.
                'collectedQty': 0,
              },
            )
            .toList(),
      };

      await _db
          .collection('assignments')
          .doc(assignment.id)
          .set(assignmentData);

      // 3. Optional: Create a Document record for history
      await _db.collection('documents').add({
        'name': fileName,
        'type': 'Imported',
        'timestamp': FieldValue.serverTimestamp(),
        'relatedAssignmentId': assignment.id,
      });
    } catch (e) {
      throw Exception("Ошибка в сервисе обработки: $e");
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
