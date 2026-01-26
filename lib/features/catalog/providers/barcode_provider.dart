import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mapping: "Barcode" -> "Articul"
// Now synced via Firebase!
class BarcodeNotifier extends Notifier<Map<String, String>> {
  final _db = FirebaseFirestore.instance.collection('barcode_links');
  StreamSubscription? _subscription;

  @override
  Map<String, String> build() {
    // 1. Listen to real-time updates from Firebase
    _subscription = _db.snapshots().listen((snapshot) {
      final newMap = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('articul')) {
          newMap[doc.id] = data['articul'] as String;
        }
      }
      state = newMap;
    });

    // Clean up subscription when provider is destroyed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return {};
  }

  // Get Articul from Barcode
  String? getArticul(String barcode) {
    return state[barcode];
  }

  // Link a new Barcode to an Articul (Saves to Cloud)
  Future<void> linkBarcode(String barcode, String articul) async {
    // Optimistically update local state for instant UI feedback
    state = {...state, barcode: articul};

    try {
      await _db.doc(barcode).set({
        'articul': articul,
        'updatedAt': FieldValue.serverTimestamp(),
        // Optional: 'author': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      // If offline, Firestore queues it automatically,
      // but if it fails permanently, you might want to handle it.
      debugPrint("Error saving barcode link: $e");
    }
  }
}

final barcodeProvider = NotifierProvider<BarcodeNotifier, Map<String, String>>(
  () {
    return BarcodeNotifier();
  },
);
