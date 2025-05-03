import 'dart:convert';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class TypeEquipmentService {
  final String baseUrl = Config.baseUrl; // Use baseUrl from Config class

  // Méthode pour créer un TypeEquipment
  Future<Map<String, dynamic>> createTypeEquipment({
    required String typeName,
    required String typeEquip,
    required File logoFile,
  }) async {
    final Uri url = Uri.parse('$baseUrl/typeEquipment/createTypeEquipment');

    try {
      // Créez une requête multipart
      var request = http.MultipartRequest('POST', url)
        ..fields['typeName'] = typeName
        ..fields['typeEquip'] = typeEquip;

      // Ajoutez le fichier logo
      request.files.add(
        await http.MultipartFile.fromPath(
          'logo', // Doit correspondre au nom du champ attendu par l'API
          logoFile.path,
          contentType: MediaType.parse(
              lookupMimeType(logoFile.path) ?? 'application/octet-stream'),
        ),
      );

      // Envoyez la requête
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // Affichez la réponse JSON dans la console
      print('Response from createTypeEquipment: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception(
            'Failed to create TypeEquipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating TypeEquipment: $e');
    }
  }

  Future<List<dynamic>> getAllTypeEquipment() async {
    final Uri url = Uri.parse('$baseUrl/typeEquipment/getAllTypeEquipment');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['rows']; // Retourne la liste des TypeEquipment
      } else {
        throw Exception('Failed to load TypeEquipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching TypeEquipment: $e');
    }
  }

  Future<Map<String, dynamic>> getFileInfo(String fileId) async {
    final response = await http.get(Uri.parse('$baseUrl/files/$fileId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load file info');
    }
  }

  Future<Map<String, dynamic>> deleteTypeEquipment({required String id}) async {
    final Uri url = Uri.parse('$baseUrl/typeEquipment/deleteTypeEquipment');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'_id': id}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
            'Failed to delete TypeEquipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting TypeEquipment: $e');
    }
  }

  Future<Map<String, dynamic>> updateTypeEquipment({
    required String id,
    required String typeName,
    required String typeEquip,
    File? logoFile, // Nouveau fichier logo (optionnel)
  }) async {
    final Uri url = Uri.parse('$baseUrl/typeEquipment/updateTypeEquipment');

    try {
      // Créez une requête multipart
      var request = http.MultipartRequest('PUT', url)
        ..fields['_id'] = id
        ..fields['typeName'] = typeName
        ..fields['typeEquip'] = typeEquip;

      // Ajoutez le fichier logo si fourni
      if (logoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo', // Doit correspondre au nom du champ attendu par l'API
            logoFile.path,
            contentType: MediaType.parse(
                lookupMimeType(logoFile.path) ?? 'application/octet-stream'),
          ),
        );
      }

      // Envoyez la requête
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // Affichez la réponse JSON dans la console
      print('Response from updateTypeEquipment: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception(
            'Failed to update TypeEquipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating TypeEquipment: $e');
    }
  }
}
