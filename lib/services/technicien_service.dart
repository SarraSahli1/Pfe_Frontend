import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:helpdeskfrontend/models/technicien.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:http/http.dart' as http;

class TechnicienService {
  static const String baseUrl = 'http://192.168.1.16:3000/tech';

  static Future<List<Technicien>> getTechnicians() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('User not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getListTechnician'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Technicians API Response: $responseData');

        // Vérification complète de la structure de réponse
        if (responseData is! Map) {
          throw Exception('Response is not a Map');
        }

        if (responseData['err'] == true) {
          throw Exception(responseData['message'] ?? 'Error from API');
        }

        if (responseData['rows'] is! List) {
          throw Exception('"rows" field is missing or not a List');
        }

        return (responseData['rows'] as List)
            .map((json) => Technicien.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load technicians: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getTechnicians: $e');
      rethrow;
    }
  }

  static Future<Technicien> getTechnicianById(String id) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('User not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getTechnicianById/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle direct object or wrapped in 'data'
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            return Technicien.fromJson(responseData['data']);
          }
          return Technicien.fromJson(responseData);
        }

        throw Exception('Invalid technician data format');
      } else {
        throw Exception('Failed to load technician: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getTechnicianById: $e');
      rethrow;
    }
  }
}
