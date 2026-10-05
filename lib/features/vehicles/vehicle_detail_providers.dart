import '../../core/network/sticky_result_provider.dart';
import '../../models/document/document.dart';
import '../../repositories/api_document_repository.dart';

final vehicleDocumentsProvider =
    stickyResultProviderFamily<List<Document>, String>(
      (ref, vehicleId) =>
          ref.watch(documentRepositoryProvider).getDocuments(vehicleId),
    );
