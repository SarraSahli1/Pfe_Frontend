import 'dart:convert';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EquipmentService {
  Future<Map<String, dynamic>> createEquipment({
    required Map<String, dynamic> data,
    String? serialNumber,
  }) async {
    final Uri url = Uri.parse(
        '${Config.baseUrl}/equipmentHelpdesk/createEquipmentHelpdesk');

    try {
      if (serialNumber != null) {
        final checkResponse = await http.get(
          Uri.parse(
              '${Config.baseUrl}/equipmentHelpdesk/checkSerial?serialNumber=$serialNumber'),
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

      final Uri url =
          Uri.parse('${Config.baseUrl}/equipmentHelpdesk/updateEquipment');

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
    final Uri url = Uri.parse('${Config.baseUrl}/equipment/deleteEquipment');

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
    final Uri url =
        Uri.parse('${Config.baseUrl}/equipmentHelpdesk/getAllEquipment');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('rows')) {
          return responseData['rows'];
        } else {
          throw Exception('Invalid response format: missing "rows" field');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No equipment found');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['message'] ?? 'Failed to load equipment';
        throw Exception('$errorMsg (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching equipment: $e');
    }
  }

  Future<Map<String, dynamic>> getEquipmentDetails({required String id}) async {
    final Uri url = Uri.parse('${Config.baseUrl}/equipmentHelpdesk/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['rows'];
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
    final Uri url =
        Uri.parse('${Config.baseUrl}/equipmentHelpdesk/createmyEquipment');

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
      Uri.parse('${Config.baseUrl}/equipmentHelpdesk/myEquipment'),
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

  Future<Map<String, dynamic>> unassignEquipment({
    required String equipmentId,
  }) async {
    final Uri url =
        Uri.parse('${Config.baseUrl}/equipmentHelpdesk/unassignEquipment');

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

  // Add to EquipmentService class
  Future<List<dynamic>> getUnassignedEquipment() async {
    try {
      print(
          'Fetching unassigned equipment from ${Config.baseUrl}/equipmentHelpdesk/getUnassignedEquipment');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/equipmentHelpdesk/getUnassignedEquipment'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['err'] == false) {
          return data['rows'] as List;
        }
      }
      throw Exception('Failed to load unassigned equipment');
    } catch (e) {
      print('Error fetching unassigned equipment: $e');
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> assignEquipmentToUser(String equipmentId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/equipmentHelpdesk/assignEquipmentUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'equipmentId': equipmentId, 'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to assign equipment');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getUserEquipment(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/equipmentHelpdesk/getUserEquipment/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['err'] == false) {
          return data['rows'] as List;
        }
      }
      throw Exception('Failed to load user equipment');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  Future<void> toggleEquipmentActiveStatus(
      String equipmentId, bool newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${Config.baseUrl}/equipment/$equipmentId/toggle-active'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isActive': newStatus}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to toggle equipment status');
      }
    } catch (e) {
      throw Exception('Error toggling equipment status: $e');
    }
  }
}
