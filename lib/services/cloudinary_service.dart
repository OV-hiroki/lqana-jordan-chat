// lib/services/cloudinary_service.dart
// رفع صور بدون توقيع عبر preset (لا يُخزَّن API secret في التطبيق).
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const _cloudName = 'dx262huam';
const _uploadPreset = 'jordan-audio-forum';

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  /// يرجع secure_url أو يرمي استثناء عند الفشل.
  Future<String> uploadImage(XFile file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'upload.jpg';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
    } else {
      final path = file.path;
      if (path.isEmpty) throw StateError('مسار الملف فارغ');
      request.files.add(await http.MultipartFile.fromPath('file', path));
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary HTTP ${streamed.statusCode}: $body');
    }
    // استجابة JSON بسيطة بدون اعتماد على package json كامل
    final secure = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (secure == null) {
      throw Exception('لم يُعثر على secure_url في الاستجابة');
    }
    return secure.group(1)!;
  }
}
