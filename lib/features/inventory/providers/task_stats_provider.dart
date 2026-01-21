import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provides the total count of tasks in real-time
final taskCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
