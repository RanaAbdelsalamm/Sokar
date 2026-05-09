import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // Initialize Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save manual test reading to Firestore
  Future<bool> saveManualReading({required String testType, required double result}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Add a new document to the user's 'readings' sub-collection
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .add({
          'testType': testType,
          'result': result,
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'Manual',
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving reading: $e");
      return false;
    }
  }
}