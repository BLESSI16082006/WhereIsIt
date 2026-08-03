import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUserService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    await _usersCollection.doc(userId).set(
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(
    String userId,
  ) async {
    final document =
        await _usersCollection.doc(userId).get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    await _usersCollection.doc(userId).set(
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}