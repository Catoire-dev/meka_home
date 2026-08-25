import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

/// Accès HTTP brut aux endpoints documents.
class DocumentApiService {
  DocumentApiService(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchDocuments(String vehicleId) async {
    final response = await _client.dio.get('/vehicles/$vehicleId/documents');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String vehicleId,
    required String type,
    required List<int> bytes,
    required String filename,
    String? maintenanceId,
    String? comment,
  }) async {
    final formData = FormData.fromMap({
      'type': type,
      'maintenance_id': ?maintenanceId,
      'comment': ?comment,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.dio.post(
      '/vehicles/$vehicleId/documents',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDocument(String id) async {
    await _client.dio.delete('/documents/$id');
  }
}
