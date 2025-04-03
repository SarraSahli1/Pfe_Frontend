import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final String baseUrl = "http://192.168.1.16:3000";
  static const String _tokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

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

    if (image != null) {
      var profileImageFile = await http.MultipartFile.fromPath(
        'profilePicture',
        image,
        contentType: MediaType.parse(
            lookupMimeType(image) ?? 'application/octet-stream'),
      );
      request.files.add(profileImageFile);
    }

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

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse('$baseUrl/auth/login');

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
        final token = responseData['accessToken'];
        final payload = responseData['payload'] ?? JwtDecoder.decode(token);
        await saveAuthData(token, payload);
        return {
          "success": true,
          "message": "Login successful",
          "payload": payload,
          "accessToken": token,
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

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
  }

  Future<void> saveAuthData(String token, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    if (payload['_id'] != null) {
      await prefs.setString(_userIdKey, payload['_id']);
    } else {
      final decodedToken = JwtDecoder.decode(token);
      if (decodedToken['_id'] != null) {
        await prefs.setString(_userIdKey, decodedToken['_id']);
      }
    }

    await prefs.setString(_userDataKey, jsonEncode(payload));
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId != null) return userId;

    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      if (userData['_id'] != null) return userData['_id'];
    }

    final token = await getToken();
    if (token != null) {
      final decodedToken = JwtDecoder.decode(token);
      if (decodedToken['_id'] != null) {
        await prefs.setString(_userIdKey, decodedToken['_id']);
        return decodedToken['_id'];
      }
    }

    return null;
  }
}
