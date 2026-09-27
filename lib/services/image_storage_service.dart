import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class ImageStorageService {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // UPLOAD POST IMAGE
  // ============================================================

  Future<String> uploadPostImage({
    required String userId,
    required String postId,
    required Uint8List imageBytes,
    String fileExtension = 'jpg',
  }) async {
    final String fileName =
        'post_image_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final Reference imageRef = _storage
        .ref()
        .child('post_images')
        .child(userId)
        .child(postId)
        .child(fileName);

    final SettableMetadata metadata = SettableMetadata(
      contentType: 'image/$fileExtension',
    );

    await imageRef.putData(
      imageBytes,
      metadata,
    );

    return imageRef.getDownloadURL();
  }

  // ============================================================
  // DELETE POST IMAGE
  // ============================================================

  Future<void> deleteImageByUrl(
    String imageUrl,
  ) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    try {
      final Reference imageRef =
          _storage.refFromURL(imageUrl);

      await imageRef.delete();
    } catch (_) {
      // Ignore if image does not exist.
    }
  }
}