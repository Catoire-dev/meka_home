import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

/// Accès HTTP brut aux endpoints véhicules. Ne connaît que du JSON — la
/// conversion vers/depuis [Vehicle] est faite par le repository.
class VehicleApiService {
  VehicleApiService(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchVehicles() async {
    final response = await _client.dio.get('/vehicles');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchVehicle(String id) async {
    final response = await _client.dio.get('/vehicles/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/vehicles', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.put('/vehicles/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteVehicle(String id) async {
    await _client.dio.delete('/vehicles/$id');
  }

  Future<Map<String, dynamic>> uploadPhoto({
    required String id,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.dio.post(
      '/vehicles/$id/photo',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}
