import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  rot, // Rashod (Expense/Outbound)
  pot, // Prihod (Income/Inbound)
  transfer, // Peremeshenie
  unknown,
}

class WarehouseDocument {
  final String id;
  final String uploaderId;
  final String uploaderName;
  final String? uploaderPhotoUrl;
  final DateTime uploadTime;
  final DocumentType type;
  final String sourceStorage;
  final String destinationStorage;
  final int itemsCount;
  final String status; // 'pending', 'processing', 'completed'
  final String rawFileUrl; // URL to the file in Storage (optional)

  WarehouseDocument({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderPhotoUrl,
    required this.uploadTime,
    required this.type,
    required this.sourceStorage,
    required this.destinationStorage,
    required this.itemsCount,
    this.status = 'pending',
    this.rawFileUrl = '',
  });

  factory WarehouseDocument.fromMap(Map<String, dynamic> map, String id) {
    return WarehouseDocument(
      id: id,
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? 'Unknown',
      uploaderPhotoUrl: map['uploaderPhotoUrl'],
      uploadTime: (map['uploadTime'] as Timestamp).toDate(),
      type: _parseType(map['type']),
      sourceStorage: map['sourceStorage'] ?? 'Unknown',
      destinationStorage: map['destinationStorage'] ?? 'Unknown',
      itemsCount: map['itemsCount'] ?? 0,
      status: map['status'] ?? 'pending',
      rawFileUrl: map['rawFileUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploaderPhotoUrl': uploaderPhotoUrl,
      'uploadTime': Timestamp.fromDate(uploadTime),
      'type': type.name,
      'sourceStorage': sourceStorage,
      'destinationStorage': destinationStorage,
      'itemsCount': itemsCount,
      'status': status,
      'rawFileUrl': rawFileUrl,
    };
  }

  static DocumentType _parseType(String? val) {
    return DocumentType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DocumentType.unknown,
    );
  }
}
