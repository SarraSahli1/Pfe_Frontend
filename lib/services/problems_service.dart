import 'dart:convert';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;

class ProblemsService {
  final String baseUrl = Config.baseUrl; // Use baseUrl from Config class

  // Create a new problem
  Future<Map<String, dynamic>> createProblem({
    required String nomProblem,
    required String description,
    required String typeEquipmentId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/problem/createProblem');
    final headers = {'Content-Type': 'application/json'};
    final body = {
      'nomProblem': nomProblem,
      'description': description,
      'typeEquipmentId': typeEquipmentId,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create problem: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating problem: $e');
    }
  }

  // Update an existing problem
  Future<Map<String, dynamic>> updateProblem({
    required String id,
    required String nomProblem,
    required String description,
  }) async {
    final Uri url = Uri.parse('$baseUrl/problem/updateProblem');
    final headers = {'Content-Type': 'application/json'};
    final body = {
      '_id': id,
      'nomProblem': nomProblem,
      'description': description,
    };

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update problem: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating problem: $e');
    }
  }

  // Delete a problem
  Future<Map<String, dynamic>> deleteProblem({required String id}) async {
    final Uri url = Uri.parse('$baseUrl/problem/deleteProblem');
    final headers = {'Content-Type': 'application/json'};
    final body = {'_id': id};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete problem: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting problem: $e');
    }
  }

  // Get all problems
  Future<List<dynamic>> getAllProblems({String? typeEquipmentId}) async {
    final queryParams =
        typeEquipmentId != null ? {'typeEquipmentId': typeEquipmentId} : null;
    final Uri url = Uri.parse('$baseUrl/problem/getAllProblems')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rows']; // Retourne la liste des problèmes
      } else {
        throw Exception('Failed to load problems: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching problems: $e');
    }
  }
}
