import 'package:cloud_firestore/cloud_firestore.dart';

class RecoveryService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _recoveries =>
      _firestore.collection('recoveries');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  // ============================================================
  // CREATE RECOVERY REQUEST
  // ============================================================

  Future<String> createRecoveryRequest({
    required String lostPostId,
    required String foundPostId,
    required String ownerId,
    required String finderId,
  }) async {
    final recoveryRef = _recoveries.doc();

    final Map<String, dynamic> recoveryData = {
      'recoveryId': recoveryRef.id,

      'lostPostId': lostPostId,
      'foundPostId': foundPostId,

      'ownerId': ownerId,
      'finderId': finderId,

      'ownerConfirmed': false,
      'finderConfirmed': false,

      'status': 'pending',

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await recoveryRef.set(recoveryData);

    return recoveryRef.id;
  }

  // ============================================================
  // GET RECOVERY
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> getRecovery(
    String recoveryId,
  ) async {
    return _recoveries.doc(recoveryId).get();
  }

  // ============================================================
  // GET RECOVERY BY POSTS
  // ============================================================

  Future<QuerySnapshot<Map<String, dynamic>>> getRecoveryByPosts({
    required String lostPostId,
    required String foundPostId,
  }) async {
    return _recoveries
        .where('lostPostId', isEqualTo: lostPostId)
        .where('foundPostId', isEqualTo: foundPostId)
        .limit(1)
        .get();
  }

  // ============================================================
  // OWNER CONFIRMATION
  // ============================================================

  Future<void> confirmByOwner(
    String recoveryId,
  ) async {
    await _recoveries.doc(recoveryId).update({
      'ownerConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _checkAndCompleteRecovery(recoveryId);
  }

  // ============================================================
  // FINDER CONFIRMATION
  // ============================================================

  Future<void> confirmByFinder(
    String recoveryId,
  ) async {
    await _recoveries.doc(recoveryId).update({
      'finderConfirmed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _checkAndCompleteRecovery(recoveryId);
  }

  // ============================================================
  // CHECK BOTH CONFIRMATIONS
  // ============================================================

  Future<void> _checkAndCompleteRecovery(
    String recoveryId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> recoverySnapshot =
        await _recoveries.doc(recoveryId).get();

    if (!recoverySnapshot.exists) {
      return;
    }

    final Map<String, dynamic>? data =
        recoverySnapshot.data();

    if (data == null) {
      return;
    }

    final bool ownerConfirmed =
        data['ownerConfirmed'] == true;

    final bool finderConfirmed =
        data['finderConfirmed'] == true;

    if (!ownerConfirmed || !finderConfirmed) {
      return;
    }

    final String lostPostId =
        data['lostPostId']?.toString() ?? '';

    final String foundPostId =
        data['foundPostId']?.toString() ?? '';

    await _recoveries.doc(recoveryId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ----------------------------------------------------------
    // Mark both posts as completed.
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    if (lostPostId.isNotEmpty) {
      batch.update(
        _posts.doc(lostPostId),
        {
          'status': 'completed',
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    if (foundPostId.isNotEmpty) {
      batch.update(
        _posts.doc(foundPostId),
        {
          'status': 'completed',
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // GET USER RECOVERIES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getUserRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter('ownerId', isEqualTo: userId),
            Filter('finderId', isEqualTo: userId),
          ),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // GET PENDING RECOVERIES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getPendingRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter('ownerId', isEqualTo: userId),
            Filter('finderId', isEqualTo: userId),
          ),
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // GET COMPLETED RECOVERIES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getCompletedRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter('ownerId', isEqualTo: userId),
            Filter('finderId', isEqualTo: userId),
          ),
        )
        .where(
          'status',
          isEqualTo: 'completed',
        )
        .orderBy(
          'completedAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // CANCEL RECOVERY
  // ============================================================

  Future<void> cancelRecovery(
    String recoveryId,
  ) async {
    await _recoveries.doc(recoveryId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE RECOVERY
  // ============================================================

  Future<void> deleteRecovery(
    String recoveryId,
  ) async {
    await _recoveries.doc(recoveryId).delete();
  }

  // ============================================================
  // GET POST
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> getPost(
    String postId,
  ) async {
    return _posts.doc(postId).get();
  }

  // ============================================================
  // CHECK WHETHER RECOVERY EXISTS
  // ============================================================

  Future<bool> recoveryExists({
    required String lostPostId,
    required String foundPostId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _recoveries
            .where(
              'lostPostId',
              isEqualTo: lostPostId,
            )
            .where(
              'foundPostId',
              isEqualTo: foundPostId,
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }
}