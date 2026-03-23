import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:soul_matcher/app/core/constants/cloudinary_config.dart';

class CloudinaryUploadService {
  Future<String> uploadImage({required XFile file, String? folder}) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryUploadException(
        'Cloudinary config missing. Set CLOUDINARY_UPLOAD_PRESET via --dart-define.',
      );
    }

    final Uri uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final List<int> bytes = await file.readAsBytes();

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['resource_type'] = 'image';

    if (folder != null && folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isEmpty ? 'upload.jpg' : file.name,
      ),
    );

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    Map<String, dynamic> payload = <String, dynamic>{};
    if (responseBody.trim().isNotEmpty) {
      final Object decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final String? secureUrl = payload['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw const CloudinaryUploadException(
          'Upload succeeded but image URL missing.',
        );
      }
      return secureUrl;
    }

    final String apiMessage = _extractApiError(payload);
    throw CloudinaryUploadException(
      apiMessage.isNotEmpty
          ? apiMessage
          : 'Cloudinary upload failed (${response.statusCode}).',
    );
  }

  String _extractApiError(Map<String, dynamic> payload) {
    final dynamic error = payload['error'];
    if (error is Map<String, dynamic>) {
      final String? message = error['message'] as String?;
      if (message != null && message.trim().isNotEmpty) return message.trim();
    }
    return '';
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}
