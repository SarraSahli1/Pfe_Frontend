import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // For MIME type detection

class AuthService {
  final String baseUrl =
      "http://192.168.1.18:3000"; // Replace with your backend URL

  // Method to register a user
  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String authority,
    required String phoneNumber,
    required bool permisConduire,
    required bool passeport,
    required String expiredAt,
    String? signature,
    required String secondEmail,
    String? birthDate,
    String? image,
    String? about,
    String? company,
  }) async {
    final Uri url = Uri.parse('$baseUrl/auth/register');
    var request = http.MultipartRequest('POST', url)
      ..fields['firstName'] = firstName
      ..fields['lastName'] = lastName
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['authority'] = authority
      ..fields['phoneNumber'] = phoneNumber
      ..fields['permisConduire'] = permisConduire.toString()
      ..fields['passeport'] = passeport.toString()
      ..fields['expiredAt'] = expiredAt
      ..fields['secondEmail'] = secondEmail
      ..fields['birthDate'] = birthDate ?? ''
      ..fields['about'] = about ?? ''
      ..fields['company'] = company ?? '';

    // Add profile picture if provided
    if (image != null) {
      var profileImageFile = await http.MultipartFile.fromPath(
        'profilePicture',
        image,
        contentType: MediaType.parse(
            lookupMimeType(image) ?? 'application/octet-stream'),
      );
      request.files.add(profileImageFile);
    }

    // Add signature if provided
    if (signature != null) {
      var signatureFile = await http.MultipartFile.fromPath(
        'signature',
        signature,
        contentType: MediaType.parse(
            lookupMimeType(signature) ?? 'application/octet-stream'),
      );
      request.files.add(signatureFile);
    }

    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        return {"success": true, "message": "Technician created successfully"};
      } else {
        final responseData = await response.stream.bytesToString();
        return {
          "success": false,
          "message": jsonDecode(responseData)['message']
        };
      }
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  // Method to log in a user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final Uri url =
        Uri.parse('$baseUrl/auth/login'); // Adjust the endpoint if necessary

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          "success": true,
          "message": "Login successful",
          "payload": responseData['payload'],
          "accessToken": responseData['accessToken'],
          "refreshToken": responseData['refreshToken'],
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "success": false,
          "message": responseData['message'] ?? "Login failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  // Method to verify a token
  Future<Map<String, dynamic>> verifyToken(String accessToken) async {
    final Uri url =
        Uri.parse('$baseUrl/auth/verify'); // Adjust the endpoint if necessary

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": "Token is valid",
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          "success": false,
          "message": responseData['message'] ?? "Token verification failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
