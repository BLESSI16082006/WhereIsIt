import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  // ----------------------------------------------------------
  // CREATE MODEL FROM FIRESTORE
  // ----------------------------------------------------------

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return NotificationModel(
      notificationId:
          data['notificationId']?.toString() ?? doc.id,

      userId:
          data['userId']?.toString() ?? '',

      title:
          data['title']?.toString() ?? 'Notification',

      message:
          data['message']?.toString() ?? '',

      type:
          data['type']?.toString() ?? 'general',

      isRead:
          data['isRead'] == true,

      createdAt:
          _readDateTime(data['createdAt']),
    );
  }

  // ----------------------------------------------------------
  // CONVERT MODEL TO FIRESTORE DATA
  // ----------------------------------------------------------

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ----------------------------------------------------------
  // DATE/TIME HELPER
  // ----------------------------------------------------------

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  // ----------------------------------------------------------
  // COPY WITH
  // ----------------------------------------------------------

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId:
          notificationId ?? this.notificationId,

      userId:
          userId ?? this.userId,

      title:
          title ?? this.title,

      message:
          message ?? this.message,

      type:
          type ?? this.type,

      isRead:
          isRead ?? this.isRead,

      createdAt:
          createdAt ?? this.createdAt,
    );
  }
}