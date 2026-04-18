// ============================================================
// Jordan Audio Forum — Cloudinary Service
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CloudinaryResult {
  final bool success;
  final String? url;
  final String? publicId;
  final String? error;

  const CloudinaryResult({
    required this.success,
    this.url,
    this.publicId,
    this.error,
  });
}

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  /// رفع من الذاكرة (مناسب للويب ولمسارات XFile)
  Future<CloudinaryResult> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    required String folder,
    String? publicId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.cloudinaryBaseUrl}/${AppConstants.cloudinaryCloudName}/image/upload',
      );
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryResult(
          success: true,
          url: data['secure_url'] as String?,
          publicId: data['public_id'] as String?,
        );
      }
      final err = jsonDecode(response.body);
      return CloudinaryResult(
        success: false,
        error: err['error']?['message'] ?? 'Upload failed',
      );
    } catch (e) {
      return CloudinaryResult(success: false, error: e.toString());
    }
  }

  Future<CloudinaryResult> uploadImage(
    File imageFile, {
    required String folder,
    String? publicId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.cloudinaryBaseUrl}/${AppConstants.cloudinaryCloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryResult(
          success: true,
          url: data['secure_url'] as String?,
          publicId: data['public_id'] as String?,
        );
      } else {
        final error = jsonDecode(response.body);
        return CloudinaryResult(
          success: false,
          error: error['error']?['message'] ?? 'Upload failed',
        );
      }
    } catch (e) {
      return CloudinaryResult(success: false, error: e.toString());
    }
  }

  Future<CloudinaryResult> uploadProfileImage(File imageFile, String userId) =>
      uploadImage(
        imageFile,
        folder: AppConstants.folderProfileImages,
        publicId: 'profile_$userId',
      );

  Future<CloudinaryResult> uploadRoomImage(File imageFile, String roomId) =>
      uploadImage(
        imageFile,
        folder: AppConstants.folderRoomImages,
        publicId: 'room_$roomId',
      );

  String buildUrl(String publicId, {String transformation = ''}) {
    final t = transformation.isNotEmpty ? '$transformation/' : '';
    return 'https://res.cloudinary.com/${AppConstants.cloudinaryCloudName}/image/upload/$t$publicId';
  }

  String avatarUrl(String userId) => buildUrl(
    '${AppConstants.folderProfileImages}/profile_$userId',
    transformation: AppConstants.transformAvatar,
  );
}
