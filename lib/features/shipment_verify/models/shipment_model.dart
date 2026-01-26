import 'package:cloud_firestore/cloud_firestore.dart';

class ShipmentVerification {
  final String id;
  final String orderId;
  final String verifierId;
  final List<String> verifiedBarcodes;
  final bool isComplete;
  final DateTime timestamp;

  ShipmentVerification({
    required this.id,
    required this.orderId,
    required this.verifierId,
    required this.verifiedBarcodes,
    required this.isComplete,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'verifierId': verifierId,
      'verifiedBarcodes': verifiedBarcodes,
      'isComplete': isComplete,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory ShipmentVerification.fromMap(Map<String, dynamic> map, String docId) {
    return ShipmentVerification(
      id: docId,
      orderId: map['orderId'] ?? '',
      verifierId: map['verifierId'] ?? '',
      verifiedBarcodes: List<String>.from(map['verifiedBarcodes'] ?? []),
      isComplete: map['isComplete'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
