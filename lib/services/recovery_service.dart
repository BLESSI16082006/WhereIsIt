
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class RecoveryService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final NotificationService _notificationService =
      NotificationService();

  CollectionReference<Map<String, dynamic>> get _recoveries =>
      _firestore.collection('recoveries');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // ------------------------------------------------------------
  // CREATE RECOVERY REQUEST
  // ------------------------------------------------------------

  Future<String> createRecoveryRequest({
    required String lostPostId,
    required String foundPostId,
    required String ownerId,
    required String finderId,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to start item return.',
      );
    }

    if (user.uid != ownerId && user.uid != finderId) {
      throw Exception(
        'You are not part of this recovery.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> existing =
        await getRecoveryByPosts(
      lostPostId: lostPostId,
      foundPostId: foundPostId,
    );

    if (existing.docs.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> document =
          existing.docs.first;

      final Map<String, dynamic>? data = document.data();

      if (data == null) {
        throw Exception(
          'Existing recovery information is unavailable.',
        );
      }

      final String existingOwnerId =
          data['ownerId']?.toString() ?? '';

      final String existingFinderId =
          data['finderId']?.toString() ?? '';

      if (user.uid != existingOwnerId &&
          user.uid != existingFinderId) {
        throw Exception(
          'You are not part of this recovery.',
        );
      }

      if (data['status'] == 'pending') {
        await _updateCurrentUsersPost(
          lostPostId: lostPostId,
          foundPostId: foundPostId,
          ownerId: existingOwnerId,
          finderId: existingFinderId,
          recoveryId: document.id,
        );
      }

      return document.id;
    }

    final DocumentSnapshot<Map<String, dynamic>> lostSnapshot =
        await _posts.doc(lostPostId).get();

    final DocumentSnapshot<Map<String, dynamic>> foundSnapshot =
        await _posts.doc(foundPostId).get();

    if (!lostSnapshot.exists) {
      throw Exception(
        'Lost item post was not found.',
      );
    }

    if (!foundSnapshot.exists) {
      throw Exception(
        'Found item post was not found.',
      );
    }

    final Map<String, dynamic>? lostData =
        lostSnapshot.data();

    final Map<String, dynamic>? foundData =
        foundSnapshot.data();

    if (lostData == null || foundData == null) {
      throw Exception(
        'Post information is unavailable.',
      );
    }

    if (lostData['userId']?.toString() != ownerId) {
      throw Exception(
        'The selected lost post does not belong to the specified owner.',
      );
    }

    if (foundData['userId']?.toString() != finderId) {
      throw Exception(
        'The selected found post does not belong to the specified finder.',
      );
    }

    if (lostData['postType']?.toString() != 'Lost') {
      throw Exception(
        'The selected post is not a Lost item post.',
      );
    }

    if (foundData['postType']?.toString() != 'Found') {
      throw Exception(
        'The selected post is not a Found item post.',
      );
    }

    final bool isValuableFound =
        foundData['category']?.toString() == 'Valuable Items';

    if (isValuableFound) {
      final bool ownerVerified =
          foundData['ownerVerified'] == true;

      final String verifiedUserId =
          foundData['verifiedUserId']?.toString() ?? '';

      if (!ownerVerified ||
          verifiedUserId != user.uid) {
        throw Exception(
          'Owner verification must be completed before starting item return.',
        );
      }
    }

    final DocumentReference<Map<String, dynamic>> recoveryRef =
        _recoveries.doc();

    await recoveryRef.set({
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
    });

    await _updateCurrentUsersPost(
      lostPostId: lostPostId,
      foundPostId: foundPostId,
      ownerId: ownerId,
      finderId: finderId,
      recoveryId: recoveryRef.id,
    );

    return recoveryRef.id;
  }

  // ------------------------------------------------------------
  // UPDATE CURRENT USER'S POST
  // ------------------------------------------------------------

  Future<void> _updateCurrentUsersPost({
    required String lostPostId,
    required String foundPostId,
    required String ownerId,
    required String finderId,
    required String recoveryId,
  }) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    if (user.uid == ownerId) {
      await _posts.doc(lostPostId).update({
        'matchedPostId': foundPostId,
        'matchFound': true,
        'recoveryStatus': 'return_pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (user.uid == finderId) {
      await _posts.doc(foundPostId).update({
        'matchedPostId': lostPostId,
        'matchFound': true,
        'recoveryStatus': 'return_pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    throw Exception(
      'You are not part of this recovery.',
    );
  }

  // ------------------------------------------------------------
  // GET RECOVERY
  // ------------------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>> getRecovery(
    String recoveryId,
  ) {
    return _recoveries.doc(recoveryId).get();
  }

  // ------------------------------------------------------------
  // GET RECOVERY BY POSTS
  // ------------------------------------------------------------

  Future<QuerySnapshot<Map<String, dynamic>>> getRecoveryByPosts({
    required String lostPostId,
    required String foundPostId,
  }) {
    return _recoveries
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
  }

  // ------------------------------------------------------------
  // OWNER CONFIRMATION
  // ------------------------------------------------------------

  Future<void> confirmByOwner(
    String recoveryId,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to confirm the recovery.',
      );
    }

    final DocumentReference<Map<String, dynamic>> recoveryRef =
        _recoveries.doc(recoveryId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await recoveryRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Recovery request not found.',
      );
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw Exception(
        'Recovery information is unavailable.',
      );
    }

    final String ownerId =
        data['ownerId']?.toString() ?? '';

    final String finderId =
        data['finderId']?.toString() ?? '';

    if (ownerId != user.uid) {
      throw Exception(
        'Only the lost item owner can confirm item received.',
      );
    }

    if (data['status'] == 'completed') {
      return;
    }

    if (data['status'] == 'cancelled') {
      throw Exception(
        'This recovery has already been cancelled.',
      );
    }

    if (data['ownerConfirmed'] == true) {
      return;
    }

    await recoveryRef.update({
      'ownerConfirmed': true,
      'ownerConfirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String lostPostId =
        data['lostPostId']?.toString() ?? '';

    if (lostPostId.isNotEmpty) {
      await _posts.doc(lostPostId).update({
        'status': 'completed',
        'isCompleted': true,
        'recoveryStatus': 'owner_confirmed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ----------------------------------------------------------
    // ITEM RETURN CONFIRMED
    // Notify the owner who confirmed.
    // ----------------------------------------------------------

    await _createSafeNotification(
      userId: ownerId,
      title: 'Item Return Confirmed',
      message:
          'You confirmed that you received the item from the finder.',
      type: 'item_confirmation',
    );

    // ----------------------------------------------------------
    // CHECK WHETHER BOTH SIDES HAVE CONFIRMED
    // ----------------------------------------------------------

    final bool finderConfirmed =
        data['finderConfirmed'] == true;

    if (finderConfirmed) {
      await _createRecoverySuccessNotifications(
        ownerId: ownerId,
        finderId: finderId,
      );
    } else {
      // --------------------------------------------------------
      // RECOVERY WAITING
      // Notify finder that owner has confirmed and
      // finder confirmation is still required.
      // --------------------------------------------------------

      await _createSafeNotification(
        userId: finderId,
        title: 'Recovery Waiting',
        message:
            'The owner has confirmed receiving the item. '
            'Please confirm that the item was returned.',
        type: 'recovery_waiting',
      );
    }

    await _checkAndCompleteRecovery(recoveryId);
  }

  // ------------------------------------------------------------
  // FINDER CONFIRMATION
  // ------------------------------------------------------------

  Future<void> confirmByFinder(
    String recoveryId,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to confirm the recovery.',
      );
    }

    final DocumentReference<Map<String, dynamic>> recoveryRef =
        _recoveries.doc(recoveryId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await recoveryRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Recovery request not found.',
      );
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw Exception(
        'Recovery information is unavailable.',
      );
    }

    final String ownerId =
        data['ownerId']?.toString() ?? '';

    final String finderId =
        data['finderId']?.toString() ?? '';

    if (finderId != user.uid) {
      throw Exception(
        'Only the finder can confirm item returned.',
      );
    }

    if (data['status'] == 'completed') {
      return;
    }

    if (data['status'] == 'cancelled') {
      throw Exception(
        'This recovery has already been cancelled.',
      );
    }

    if (data['finderConfirmed'] == true) {
      return;
    }

    await recoveryRef.update({
      'finderConfirmed': true,
      'finderConfirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String foundPostId =
        data['foundPostId']?.toString() ?? '';

    if (foundPostId.isNotEmpty) {
      await _posts.doc(foundPostId).update({
        'status': 'completed',
        'isCompleted': true,
        'recoveryStatus': 'finder_confirmed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ----------------------------------------------------------
    // ITEM RETURN CONFIRMED
    // Notify the finder who confirmed.
    // ----------------------------------------------------------

    await _createSafeNotification(
      userId: finderId,
      title: 'Item Return Confirmed',
      message:
          'You confirmed that you returned the item to the owner.',
      type: 'item_confirmation',
    );

    // ----------------------------------------------------------
    // CHECK WHETHER BOTH SIDES HAVE CONFIRMED
    // ----------------------------------------------------------

    final bool ownerConfirmed =
        data['ownerConfirmed'] == true;

    if (ownerConfirmed) {
      await _createRecoverySuccessNotifications(
        ownerId: ownerId,
        finderId: finderId,
      );
    } else {
      // --------------------------------------------------------
      // RECOVERY WAITING
      // Notify owner that finder has confirmed and
      // owner confirmation is still required.
      // --------------------------------------------------------

      await _createSafeNotification(
        userId: ownerId,
        title: 'Recovery Waiting',
        message:
            'The finder has confirmed returning the item. '
            'Please confirm that you received it.',
        type: 'recovery_waiting',
      );
    }

    await _checkAndCompleteRecovery(recoveryId);
  }

  // ------------------------------------------------------------
  // CREATE RECOVERY SUCCESS NOTIFICATIONS
  // ------------------------------------------------------------

  Future<void> _createRecoverySuccessNotifications({
    required String ownerId,
    required String finderId,
  }) async {
    await _createSafeNotification(
      userId: ownerId,
      title: 'Recovery Successful',
      message:
          'Both you and the finder have confirmed the item return. '
          'The recovery is now completed.',
      type: 'recovery_success',
    );

    await _createSafeNotification(
      userId: finderId,
      title: 'Recovery Successful',
      message:
          'Both you and the owner have confirmed the item return. '
          'The recovery is now completed.',
      type: 'recovery_success',
    );
  }

  // ------------------------------------------------------------
  // SAFE NOTIFICATION CREATION
  // ------------------------------------------------------------
  //
  // Notification failure must never stop the actual recovery
  // confirmation process.
  // ------------------------------------------------------------

  Future<void> _createSafeNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
      );
    } catch (_) {
      // Keep recovery flow working even if notification creation
      // temporarily fails.
    }
  }

  // ------------------------------------------------------------
  // CHECK AND COMPLETE RECOVERY
  // ------------------------------------------------------------

  Future<void> _checkAndCompleteRecovery(
    String recoveryId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _recoveries.doc(recoveryId).get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return;
    }

    if (data['status'] == 'completed' ||
        data['status'] == 'cancelled') {
      return;
    }

    final bool ownerConfirmed =
        data['ownerConfirmed'] == true;

    final bool finderConfirmed =
        data['finderConfirmed'] == true;

    if (!ownerConfirmed || !finderConfirmed) {
      return;
    }

    await _recoveries.doc(recoveryId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // USER RECOVERIES
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter(
              'ownerId',
              isEqualTo: userId,
            ),
            Filter(
              'finderId',
              isEqualTo: userId,
            ),
          ),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ------------------------------------------------------------
  // PENDING RECOVERIES
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter(
              'ownerId',
              isEqualTo: userId,
            ),
            Filter(
              'finderId',
              isEqualTo: userId,
            ),
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

  // ------------------------------------------------------------
  // COMPLETED RECOVERIES
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getCompletedRecoveries(
    String userId,
  ) {
    return _recoveries
        .where(
          Filter.or(
            Filter(
              'ownerId',
              isEqualTo: userId,
            ),
            Filter(
              'finderId',
              isEqualTo: userId,
            ),
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

  // ------------------------------------------------------------
  // CANCEL RECOVERY
  // ------------------------------------------------------------

  Future<void> cancelRecovery(
    String recoveryId,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _recoveries.doc(recoveryId).get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return;
    }

    final String ownerId =
        data['ownerId']?.toString() ?? '';

    final String finderId =
        data['finderId']?.toString() ?? '';

    if (user.uid != ownerId && user.uid != finderId) {
      throw Exception(
        'You are not part of this recovery.',
      );
    }

    if (data['status'] == 'completed') {
      throw Exception(
        'Completed recovery cannot be cancelled.',
      );
    }

    if (data['status'] == 'cancelled') {
      return;
    }

    await _recoveries.doc(recoveryId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String lostPostId =
        data['lostPostId']?.toString() ?? '';

    final String foundPostId =
        data['foundPostId']?.toString() ?? '';

    if (user.uid == ownerId && lostPostId.isNotEmpty) {
      await _posts.doc(lostPostId).update({
        'matchedPostId': null,
        'matchFound': false,
        'recoveryStatus': 'not_started',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (user.uid == finderId && foundPostId.isNotEmpty) {
      await _posts.doc(foundPostId).update({
        'matchedPostId': null,
        'matchFound': false,
        'recoveryStatus': 'not_started',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ------------------------------------------------------------
  // DELETE RECOVERY
  // ------------------------------------------------------------

  Future<void> deleteRecovery(
    String recoveryId,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _recoveries.doc(recoveryId).get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return;
    }

    final String ownerId =
        data['ownerId']?.toString() ?? '';

    final String finderId =
        data['finderId']?.toString() ?? '';

    if (user.uid != ownerId && user.uid != finderId) {
      throw Exception(
        'You are not part of this recovery.',
      );
    }

    throw Exception(
      'Recovery history cannot be deleted.',
    );
  }

  // ------------------------------------------------------------
  // GET POST
  // ------------------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>> getPost(
    String postId,
  ) {
    return _posts.doc(postId).get();
  }

  // ------------------------------------------------------------
  // CHECK RECOVERY EXISTS
  // ------------------------------------------------------------

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
