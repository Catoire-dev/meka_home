import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_guard.dart';
import '../core/network/result.dart';
import '../models/document/document.dart';
import '../models/document/document_type.dart';
import '../services/api/document_api_service.dart';
import 'document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiDocumentRepository(DocumentApiService(client), client);
});

class ApiDocumentRepository implements DocumentRepository {
  ApiDocumentRepository(this._service, this._client);

  final DocumentApiService _service;
  final ApiClient _client;

  @override
  Future<Result<List<Document>>> getDocuments(String vehicleId) =>
      apiGuard(_client, () async {
        final json = await _service.fetchDocuments(vehicleId);
        return json
            .map((e) => Document.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<Document>> uploadDocument({
    required String vehicleId,
    required DocumentType type,
    required List<int> bytes,
    required String filename,
    String? maintenanceId,
    String? comment,
  }) => apiGuard(_client, () async {
    final json = await _service.uploadDocument(
      vehicleId: vehicleId,
      type: type.jsonValue,
      bytes: bytes,
      filename: filename,
      maintenanceId: maintenanceId,
      comment: comment,
    );
    return Document.fromJson(json);
  });

  @override
  Future<Result<void>> deleteDocument(String id) =>
      apiGuard(_client, () => _service.deleteDocument(id));
}
