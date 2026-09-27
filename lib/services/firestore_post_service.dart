import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class FirestorePostService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // VERIFICATION HELPERS
  // ------------------------------------------------------------

  String _normalizeAnswer(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _hashAnswer(String answer) {
    final String normalized =
        _normalizeAnswer(answer);

    return sha256
        .convert(utf8.encode(normalized))
        .toString();
  }

  // ------------------------------------------------------------
  // CREATE POST
  // ------------------------------------------------------------

  Future<String> createPost({
    required String userId,
    required String postType,
    required String category,
    required String itemName,
    required DateTime date,
    required String location,
    required String phone,
    required String email,
    required String description,
    String? reward,
    String? imageUrl,
    String? ocrText,
  }) async {
    final DocumentReference<Map<String, dynamic>> postRef =
        _firestore.collection('posts').doc();

    // Found Valuable Items contain private finder information.
    final bool isFoundValuable =
        postType == 'Found' &&
        category == 'Valuable Items';

    final Map<String, dynamic> postData = {
      'postId': postRef.id,
      'userId': userId,

      // ==========================================================
      // PUBLIC POST INFORMATION
      // ==========================================================

      'postType': postType,
      'category': category,
      'itemName': itemName,
      'date': Timestamp.fromDate(date),
      'location': location,

      // ==========================================================
      // STORED INFORMATION
      // ==========================================================

      'phone': phone,
      'email': email,
      'description': description,
      'imageUrl': imageUrl ?? '',
      'ocrText': ocrText ?? '',

      // ==========================================================
      // REWARD
      // ==========================================================

      'reward': reward ?? '',

      // ==========================================================
      // PRIVACY
      // ==========================================================

      'isPrivateFinderData': isFoundValuable,

      // ==========================================================
      // STATUS
      // ==========================================================

      'status': 'active',
      'isCompleted': false,

      // ==========================================================
      // MATCHING
      // ==========================================================

      'matchFound': false,
      'matchedPostId': null,

      // ==========================================================
      // OWNER VERIFICATION
      // ==========================================================

      'ownerVerified': false,
      'verificationStatus':
          isFoundValuable ? 'pending' : 'not_required',

      // ==========================================================
      // RECOVERY / RETURN
      // ==========================================================

      'finderConfirmedReturn': false,
      'ownerConfirmedReturn': false,
      'recoveryStatus': 'not_started',

      // ==========================================================
      // TIMESTAMPS
      // ==========================================================

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await postRef.set(postData);

    return postRef.id;
  }

  // ------------------------------------------------------------
  // SAVE VALUABLE ITEM VERIFICATION ANSWERS
  // ------------------------------------------------------------

  Future<void> saveValuableVerificationAnswers({
    required String postId,
    required String userId,
    required List<String> answers,
  }) async {
    if (answers.length != 5) {
      throw Exception(
        'Exactly 5 verification answers are required.',
      );
    }

    for (final answer in answers) {
      if (answer.trim().isEmpty) {
        throw Exception(
          'All 5 verification answers are required.',
        );
      }
    }

    final List<String> answerHashes = answers
        .map(_hashAnswer)
        .toList();

    await _firestore
        .collection('post_verification')
        .doc(postId)
        .set({
      'postId': postId,
      'userId': userId,
      'answerHashes': answerHashes,
      'questionCount': 5,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // GET ALL ACTIVE POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getActivePosts() {
    return _firestore
        .collection('posts')
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET LOST POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getLostPosts() {
    return _firestore
        .collection('posts')
        .where(
          'postType',
          isEqualTo: 'Lost',
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET FOUND POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getFoundPosts() {
    return _firestore
        .collection('posts')
        .where(
          'postType',
          isEqualTo: 'Found',
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET USER POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET SINGLE POST
  // ------------------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .get();
  }

  // ------------------------------------------------------------
  // UPDATE POST
  // ------------------------------------------------------------

  Future<void> updatePost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // DELETE POST
  // ------------------------------------------------------------

  Future<void> deletePost(String postId) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .delete();
  }

  // ------------------------------------------------------------
  // MARK POST AS COMPLETED
  // ------------------------------------------------------------

  Future<void> markPostCompleted(
    String postId,
  ) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'status': 'completed',
      'isCompleted': true,
      'completedAt':
          FieldValue.serverTimestamp(),
      'recoveryStatus': 'completed',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // SET MATCH
  // ------------------------------------------------------------

  Future<void> setMatch({
    required String postId,
    required String matchedPostId,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'matchFound': true,
      'matchedPostId': matchedPostId,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}