
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------------------------------------
  // CREATE NOTIFICATION
  // ----------------------------------------------------------

  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final DocumentReference<Map<String, dynamic>> notificationRef =
        _firestore.collection('notifications').doc();

    final Map<String, dynamic> notificationData = {
      'notificationId': notificationRef.id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await notificationRef.set(notificationData);

    return notificationRef.id;
  }

  // ----------------------------------------------------------
  // GET CURRENT USER NOTIFICATIONS
  // ----------------------------------------------------------

  Stream<List<NotificationModel>> getUserNotifications() {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(<NotificationModel>[]);
    }

    return _firestore
        .collection('notifications')
        .where(
          'userId',
          isEqualTo: currentUser.uid,
        )
        .snapshots()
        .map((snapshot) {
      final List<NotificationModel> notifications =
          snapshot.docs
              .map(
                (doc) => NotificationModel.fromFirestore(doc),
              )
              .toList();

      notifications.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return notifications;
    });
  }

  // ----------------------------------------------------------
  // GET UNREAD NOTIFICATION COUNT
  // ----------------------------------------------------------

  Stream<int> getUnreadNotificationCount() {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where(
          'userId',
          isEqualTo: currentUser.uid,
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ----------------------------------------------------------
  // MARK ONE NOTIFICATION AS READ
  // ----------------------------------------------------------

  Future<void> markAsRead(
    String notificationId,
  ) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        notificationRef =
        _firestore
            .collection('notifications')
            .doc(notificationId);

    final DocumentSnapshot<Map<String, dynamic>>
        notificationSnapshot =
        await notificationRef.get();

    if (!notificationSnapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        notificationSnapshot.data() ?? {};

    if (data['userId'] != currentUser.uid) {
      return;
    }

    await notificationRef.update({
      'isRead': true,
    });
  }

  // ----------------------------------------------------------
  // MARK ALL CURRENT USER NOTIFICATIONS AS READ
  // ----------------------------------------------------------

  Future<void> markAllAsRead() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final QuerySnapshot<Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('notifications')
            .where(
              'userId',
              isEqualTo: currentUser.uid,
            )
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch =
        _firestore.batch();

    for (
      final QueryDocumentSnapshot<Map<String, dynamic>>
          doc
      in snapshot.docs
    ) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  // ----------------------------------------------------------
  // DELETE NOTIFICATION
  // ----------------------------------------------------------

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        notificationRef =
        _firestore
            .collection('notifications')
            .doc(notificationId);

    final DocumentSnapshot<Map<String, dynamic>>
        notificationSnapshot =
        await notificationRef.get();

    if (!notificationSnapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        notificationSnapshot.data() ?? {};

    if (data['userId'] != currentUser.uid) {
      return;
    }

    await notificationRef.delete();
  }
}

