import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    final DocumentReference<Map<String, dynamic>> postRef =
        _firestore.collection('posts').doc();

    final Map<String, dynamic> postData = {
      'postId': postRef.id,
      'userId': userId,

      'postType': postType,
      'category': category,
      'itemName': itemName,

      'date': Timestamp.fromDate(date),
      'location': location,

      'phone': phone,
      'email': email,

      'description': description,

      'reward': reward ?? '',
      'imageUrl': imageUrl ?? '',

      'status': 'active',
      'isCompleted': false,

      'matchFound': false,
      'matchedPostId': null,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await postRef.set(postData);

    return postRef.id;
  }

  // ------------------------------------------------------------
  // GET ALL ACTIVE POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getActivePosts() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET LOST POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getLostPosts() {
    return _firestore
        .collection('posts')
        .where('postType', isEqualTo: 'Lost')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET FOUND POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getFoundPosts() {
    return _firestore
        .collection('posts')
        .where('postType', isEqualTo: 'Found')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET USER POSTS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(
    String userId,
  ) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // ------------------------------------------------------------
  // GET SINGLE POST
  // ------------------------------------------------------------

  Future<DocumentSnapshot<Map<String, dynamic>>> getPost(
    String postId,
  ) {
    return _firestore.collection('posts').doc(postId).get();
  }

  // ------------------------------------------------------------
  // UPDATE POST
  // ------------------------------------------------------------

  Future<void> updatePost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('posts').doc(postId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // DELETE POST
  // ------------------------------------------------------------

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // ------------------------------------------------------------
  // MARK POST AS COMPLETED
  // ------------------------------------------------------------

  Future<void> markPostCompleted(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'status': 'completed',
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // SET MATCH
  // ------------------------------------------------------------

  Future<void> setMatch({
    required String postId,
    required String matchedPostId,
  }) async {
    await _firestore.collection('posts').doc(postId).update({
      'matchFound': true,
      'matchedPostId': matchedPostId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}