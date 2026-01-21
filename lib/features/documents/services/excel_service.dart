import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/warehouse_document.dart';

class ExcelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> uploadAndParseExcel(Uint8List fileBytes, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // 1. Parse Excel
    var excel = Excel.decodeBytes(fileBytes);
    var sheet = excel.tables[excel.tables.keys.first]; // Get first sheet

    if (sheet == null) throw Exception("Excel sheet is empty");

    // 2. Extract Metadata (You need to adjust these coordinates based on your 1C template)
    // Example: Cell A1 might contain "ROT No 123", Cell B3 might be "Main Warehouse"

    // Simple heuristic parsing logic:
    String docTypeStr = 'rot'; // Default or parsed from fileName/header
    String source = "Основной склад";
    String dest = "Магазин 1";
    int count = 0;

    // Iterate rows to count items (assuming data starts at row 8 like your CSV)
    for (var i = 8; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isNotEmpty && row[0]?.value != null) {
        count++;
      }
    }

    // 3. Detect Type from Filename or Header
    if (fileName.toLowerCase().contains('pot') ||
        fileName.toLowerCase().contains('приход')) {
      docTypeStr = 'pot';
    } else if (fileName.toLowerCase().contains('rot') ||
        fileName.toLowerCase().contains('расход')) {
      docTypeStr = 'rot';
    }

    // 4. Create Document Object
    final docRef = _firestore.collection('warehouse_documents').doc();

    // Fetch current user details for the record
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Staff';
    final userPfp = userDoc.data()?['photoUrl'];

    final newDoc = WarehouseDocument(
      id: docRef.id,
      uploaderId: user.uid,
      uploaderName: userName,
      uploaderPhotoUrl: userPfp,
      uploadTime: DateTime.now(),
      type: DocumentType.values.byName(docTypeStr), // Ensure matches enum
      sourceStorage: source,
      destinationStorage: dest,
      itemsCount: count,
      status: 'pending',
    );

    // 5. Save to Firestore
    await docRef.set(newDoc.toMap());

    // Optional: Upload raw items to a subcollection if you need individual item tracking immediately
    // _uploadItems(docRef, sheet);
  }
}
