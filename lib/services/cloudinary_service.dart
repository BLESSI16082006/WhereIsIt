import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  // ============================================================
  // CLOUDINARY CONFIGURATION
  // ============================================================

  static const String cloudName = 'djxul5fm';

  static const String uploadPreset = 'whereisit_images';

  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final Uri uri = Uri.parse(uploadUrl);

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    // ----------------------------------------------------------
    // Required Cloudinary unsigned upload preset
    // ----------------------------------------------------------

    request.fields['upload_preset'] = uploadPreset;

    // ----------------------------------------------------------
    // Image file
    // ----------------------------------------------------------

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ),
    );

    // ----------------------------------------------------------
    // Send request
    // ----------------------------------------------------------

    final streamedResponse = await request.send();

    final response =
        await http.Response.fromStream(streamedResponse);

    // ----------------------------------------------------------
    // Successful upload
    // ----------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final String? secureUrl =
          data['secure_url']?.toString();

      if (secureUrl == null ||
          secureUrl.isEmpty) {
        throw Exception(
          'Cloudinary did not return an image URL.',
        );
      }

      return secureUrl;
    }

    // ----------------------------------------------------------
    // Upload failed
    // ----------------------------------------------------------

    String errorMessage =
        'Cloudinary upload failed.';

    try {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final dynamic error =
          data['error'];

      if (error is Map<String, dynamic>) {
        errorMessage =
            error['message']?.toString() ??
                errorMessage;
      }
    } catch (_) {
      // Keep the default error message.
    }

    throw Exception(
      '$errorMessage '
      '(HTTP ${response.statusCode})',
    );
  }
}