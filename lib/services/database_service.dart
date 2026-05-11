import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Save manual test reading to Firestore
  Future<bool> saveManualReading({
    required String testType, 
    required double result, 
    String source = 'Manual'
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .add({
          'testType': testType, 
          'result': result,
          'timestamp': FieldValue.serverTimestamp(),
          'source': source, 
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error saving reading: $e");
      return false;
    }
  }

  // 2. Fetch the LATEST HbA1c reading
  Future<double?> getLatestHbA1c() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot query = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .where('testType', whereIn: ['HbA1c', 'HbA1C']) 
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          return query.docs.first['result']?.toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching latest HbA1c: $e");
      return null;
    }
  }

  // 3. Fetch Blood Glucose Average
  Future<double> getBloodGlucoseAverage() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot query = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('readings')
            .where('testType', whereIn: ['BloodGlucose', 'Fasting Blood Sugar', 'Fasting Sugar'])
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        if (query.docs.isNotEmpty) {
          double total = 0;
          for (var doc in query.docs) {
            total += doc['result']?.toDouble() ?? 0;
          }
          return double.parse((total / query.docs.length).toStringAsFixed(2));
        }
      }
      return 100.0; 
    } catch (e) {
      debugPrint("Error fetching glucose average: $e");
      return 100.0;
    }
  }
}