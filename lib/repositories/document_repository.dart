import '../core/network/result.dart';
import '../models/document/document.dart';
import '../models/document/document_type.dart';

/// Contrat d'accès aux documents liés à un véhicule, indépendant du
/// backend qui l'implémente.
abstract interface class DocumentRepository {
  Future<Result<List<Document>>> getDocuments(String vehicleId);

  Future<Result<Document>> uploadDocument({
    required String vehicleId,
    required DocumentType type,
    required List<int> bytes,
    required String filename,
    String? maintenanceId,
    String? comment,
  });

  Future<Result<void>> deleteDocument(String id);
}
