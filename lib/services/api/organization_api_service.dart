import '../../core/network/api_client.dart';

/// Accès HTTP brut aux endpoints des organisations (garages / intervenants),
/// de leurs types et de leurs adresses.
class OrganizationApiService {
  OrganizationApiService(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchOrganizationTypes() async {
    final response = await _client.dio.get('/organization-types');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/addresses', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.put('/addresses/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchOrganizations() async {
    final response = await _client.dio.get('/organizations');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createOrganization(
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.post('/organizations', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOrganization(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.put('/organizations/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteOrganization(String id) async {
    await _client.dio.delete('/organizations/$id');
  }
}
