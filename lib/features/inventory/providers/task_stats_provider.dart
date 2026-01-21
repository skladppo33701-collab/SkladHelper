import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Total Tasks (Global)
final taskCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// User Scans (Personal)
final userScansProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('scan_logs')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Activity Rank Logic (Derived)
final activityRankProvider = Provider<AsyncValue<String>>((ref) {
  final scansAsync = ref.watch(userScansProvider);
  // We can add task count to the formula if we filter tasks by user later
  // For now, Rank is mostly Scan activity.

  return scansAsync.whenData((scans) {
    if (scans > 100) return "S";
    if (scans > 50) return "A";
    if (scans > 20) return "B";
    if (scans > 0) return "C";
    return "-";
  });
});
