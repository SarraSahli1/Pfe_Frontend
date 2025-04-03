import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helpdeskfrontend/models/user.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://192.168.1.16:3000";

  String getImageUrl(String fileId) {
    return '$baseUrl/files/$fileId';
  }

  Future<Map<String, dynamic>> getFileInfo(String fileId) async {
    final response = await http.get(Uri.parse('$baseUrl/files/$fileId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load file info');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/all'), // Adaptez cette URL à votre endpoint
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      // Extract just the ID if the input contains the full object
      final cleanId = userId.contains('_id')
          ? userId.split('_id:')[1].split(',')[0].trim()
          : userId;

      final response = await http.get(
        Uri.parse('$baseUrl/user/getUserById/$cleanId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return User.fromMap(jsonResponse);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getUserById: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> userData,
      {http.MultipartFile? image}) async {
    final Uri url = Uri.parse('$baseUrl/user/updateUser/$userId');
    try {
      var request = http.MultipartRequest('PUT', url);

      // Add fields to the request
      userData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add image file if provided
      if (image != null) {
        request.files.add(image);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // Afficher la réponse JSON dans la console
      print('Response from updateUser: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<Map<String, dynamic>> updateClient(
      String clientId, Map<String, dynamic> clientData,
      {http.MultipartFile? profilePicture}) async {
    final Uri url = Uri.parse('$baseUrl/client/updateClient/$clientId');
    try {
      var request = http.MultipartRequest('PUT', url);

      // Add fields to the request
      clientData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add profile picture file if provided
      if (profilePicture != null) {
        request.files.add(profilePicture);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      // Display the JSON response in the console
      print('Response from updateClient: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to update client: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating client: $e');
    }
  }

  Future<Map<String, dynamic>> updateTechnician(
      String technicianId, Map<String, dynamic> technicianData,
      {http.MultipartFile? profilePicture,
      http.MultipartFile? signature}) async {
    final Uri url = Uri.parse('$baseUrl/tech/updateTechnician/$technicianId');
    try {
      var request = http.MultipartRequest('PUT', url);

      // Add fields to the request
      technicianData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add profile picture file if provided
      if (profilePicture != null) {
        request.files.add(profilePicture);
      }

      // Add signature file if provided
      if (signature != null) {
        request.files.add(signature);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('Response from updateTechnician: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to update technician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating technician: $e');
    }
  }

  Future<Map<String, dynamic>> deleteUser(String email) async {
    final Uri url = Uri.parse('$baseUrl/user/delete/$email');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<List<User>> getPendingUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/user/pending'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> usersJson = responseBody['rows'];
      return usersJson.map((userJson) => User.fromMap(userJson)).toList();
    } else {
      throw Exception('Failed to load pending users');
    }
  }

  Future<void> validateUser(String userId) async {
    final response =
        await http.put(Uri.parse('$baseUrl/user/validate/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to validate user');
    }
  }

  Future<void> rejectUser(String userId) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/user/reject/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to reject user');
    }
  }

  Future<List<Map<String, dynamic>>> getAllClients() async {
    final Uri url = Uri.parse('$baseUrl/client/getListClient');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.cast<
            Map<String, dynamic>>(); // Convertir en List<Map<String, dynamic>>
      } else {
        throw Exception(
            'Échec du chargement des clients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }
}
