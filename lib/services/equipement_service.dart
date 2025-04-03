import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EquipmentService {
  static const String baseUrl =
      "http://192.168.1.16:3000"; // Replace with your API URL

  Future<Map<String, dynamic>> createEquipment({
    required Map<String, dynamic> data,
    String? serialNumber,
  }) async {
    final Uri url =
        Uri.parse('$baseUrl/equipmentHelpdesk/createEquipmentHelpdesk');

    try {
      if (serialNumber != null) {
        final checkResponse = await http.get(
          Uri.parse(
              '$baseUrl/equipmentHelpdesk/checkSerial?serialNumber=$serialNumber'),
        );
        if (checkResponse.statusCode == 409) {
          throw Exception('Duplicated Serial Number');
        }
      }

      // Remove owner from data
      final equipmentData = Map<String, dynamic>.from(data)..remove('owner');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serialNumber': serialNumber,
          'data': equipmentData,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
            'Failed to create Equipment: ${responseData['message']}');
      }
    } catch (e) {
      throw Exception('Error creating Equipment: $e');
    }
  }

  Future<Map<String, dynamic>> updateEquipment({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (id.isEmpty) {
        throw Exception('Equipment ID cannot be empty');
      }

      final Uri url = Uri.parse('$baseUrl/equipmentHelpdesk/updateEquipment');

      // Structure corrigée pour matcher Postman
      final requestBody = {
        '_id': id,
        'data': data, // Gardez les données dans un objet 'data'
      };

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ??
            'Update failed with status ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('Invalid JSON format: $e');
    } catch (e) {
      throw Exception('Error updating equipment: $e');
    }
  }

  Future<Map<String, dynamic>> deleteEquipment({required String id}) async {
    final Uri url = Uri.parse('$baseUrl/equipment/deleteEquipment');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          '_id': id,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
            'Échec de la suppression de l\'équipement : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'équipement : $e');
    }
  }

  Future<List<dynamic>> getAllEquipment() async {
    final Uri url = Uri.parse('$baseUrl/equipmentHelpdesk/getAllEquipment');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if the response contains the expected structure
        if (responseData.containsKey('rows')) {
          return responseData['rows']; // Return the list of equipment
        } else {
          throw Exception('Invalid response format: missing "rows" field');
        }
      } else if (response.statusCode == 404) {
        // Handle "not found" case specifically if needed
        throw Exception('No equipment found');
      } else {
        // Try to extract error message from response
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['message'] ?? 'Failed to load equipment';
        throw Exception('$errorMsg (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching equipment: $e');
    }
  }

  Future<Map<String, dynamic>> getEquipmentDetails({required String id}) async {
    final Uri url = Uri.parse(
        '$baseUrl/equipmentHelpdesk/$id'); // Endpoint pour récupérer les détails d'un équipement

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData[
            'rows']; // Retourne uniquement les détails de l'équipement
      } else {
        throw Exception(
            'Failed to fetch equipment details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching equipment details: $e');
    }
  }

  Future<Map<String, dynamic>> createmyEquipment({
    required String serialNumber,
    required String designation,
    String? version,
    String? barcode,
    DateTime? inventoryDate,
    required String typeEquipmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/equipmentHelpdesk/createmyEquipment');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serialNumber': serialNumber,
          'designation': designation,
          'version': version,
          'barcode': barcode,
          'inventoryDate': inventoryDate?.toIso8601String(),
          'TypeEquipment': typeEquipmentId,
          // 'assigned' is automatically set to false by backend
          // 'reference' is automatically set to 'OPM_APP' by backend
          // 'owner' is set by backend using req.user._id
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        print('Equipment created successfully: ${responseData['equipment']}');
        return responseData;
      } else {
        throw Exception(
            'Failed to create Equipment: ${responseData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating Equipment: $e');
    }
  }

  static Future<List<dynamic>> getMyEquipment() async {
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/equipmentHelpdesk/myEquipment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['equipment'];
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> assignEquipmentToUser({
    required String equipmentId,
    required String userId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/equipmentHelpdesk/assignEquipmentUser');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'equipmentId': equipmentId,
          'userId': userId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['rows'];
      } else {
        throw Exception(responseData['message'] ?? 'Assignment failed');
      }
    } catch (e) {
      throw Exception('Error assigning equipment: $e');
    }
  }

  Future<Map<String, dynamic>> unassignEquipment({
    required String equipmentId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/equipmentHelpdesk/unassignEquipment');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'equipmentId': equipmentId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Unassignment failed');
      }
    } catch (e) {
      throw Exception('Error unassigning equipment: $e');
    }
  }
}
