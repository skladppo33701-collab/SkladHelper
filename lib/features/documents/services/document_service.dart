import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:sklad_helper_33701/core/utils/pdf_parser/pdf_parser_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/warehouse_document.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> processUpload(Uint8List fileBytes, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    String docTypeStr = 'rot';
    String source = "Unknown Source";
    String dest = "Unknown Destination";
    int itemCount = 0;

    // Detect file type and parse accordingly
    if (fileName.toLowerCase().endsWith('.pdf')) {
      final pdfData = _parsePdf(fileBytes);
      itemCount = pdfData['itemCount'];
      docTypeStr = pdfData['type'];
      source = pdfData['source'];
    } else {
      final excelData = _parseExcel(fileBytes, fileName);
      itemCount = excelData['itemCount'];
      docTypeStr = excelData['type'];
      source = excelData['source'];
    }

    // Create the Firestore record
    final docRef = _firestore.collection('warehouse_documents').doc();
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    final newDoc = WarehouseDocument(
      id: docRef.id,
      uploaderId: user.uid,
      uploaderName: userDoc.data()?['name'] ?? 'Staff',
      uploaderPhotoUrl: userDoc.data()?['photoUrl'],
      uploadTime: DateTime.now(),
      type: DocumentType.values.byName(docTypeStr),
      sourceStorage: source,
      destinationStorage: dest,
      itemsCount: itemCount,
      status: 'pending',
    );

    await docRef.set(newDoc.toMap());
  }

  // --- PDF PARSING LOGIC ---
  Map<String, dynamic> _parsePdf(Uint8List bytes) {
    return parsePdf(bytes); // Now safe on web (uses stub)
  }

  // --- EXCEL PARSING LOGIC ---
  Map<String, dynamic> _parseExcel(Uint8List bytes, String fileName) {
    var excel = excel_pkg.Excel.decodeBytes(bytes);
    var sheet = excel.tables[excel.tables.keys.first];
    int count = 0;

    if (sheet != null) {
      for (var i = 8; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.isNotEmpty && row[0]?.value != null) {
          count++;
        }
      }
    }

    String type = (fileName.toLowerCase().contains('pot')) ? 'pot' : 'rot';
    return {'itemCount': count, 'type': type, 'source': "Excel Export"};
  }
}
