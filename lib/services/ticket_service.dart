import 'dart:convert';
import 'dart:io';
import 'package:helpdeskfrontend/models/ticket.dart';
import 'package:helpdeskfrontend/services/auth_service.dart';
import 'package:helpdeskfrontend/services/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketService {
  static const String _baseUrl =
      '${Config.baseUrl}/ticket'; // Use baseUrl from Config class with '/ticket' suffix

  // Créer un nouveau ticket
  static Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    required String typeTicket,
    String? equipmentId,
    String? problem, // Nouveau paramètre
    List<String>? filePaths,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('User not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/createTicket'),
      );

      // Headers et champs
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['typeTicket'] = typeTicket;

      if (equipmentId != null) {
        request.fields['equipmentId'] = equipmentId;
      }

      if (problem != null) {
        request.fields['problem'] = problem; // Ajout du problème
      }

      // Ajout des fichiers
      if (filePaths != null) {
        for (var filePath in filePaths) {
          var file = File(filePath);
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          request.files.add(http.MultipartFile(
            'files',
            stream,
            length,
            filename: filePath.split('/').last,
          ));
        }
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode != 201) {
        throw Exception('Failed to create ticket: $responseString');
      }

      return json.decode(responseString);
    } catch (e) {
      debugPrint('Error in createTicket: $e');
      rethrow;
    }
  }

  // Add solution to an existing ticket
  static Future<Map<String, dynamic>> addSolutionToTicket({
    required String ticketId,
    required String solutionText,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/$ticketId/solution'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'solutionText': solutionText,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'solution': responseData['solution'],
          'ticket': responseData['ticket'],
        };
      } else {
        throw Exception(
            'Failed to add solution (${response.statusCode}): ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Error in addSolutionToTicket: $e');
      rethrow;
    }
  }

  // Récupérer les tickets de l'utilisateur
  static Future<List<dynamic>> getUserTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$_baseUrl/userTickets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Échec du chargement des tickets');
    }
  }

  static Future<List<Ticket>> getMyTickets() async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('User not authenticated');
    final response = await http.get(
      Uri.parse('$_baseUrl/TechTickets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('API Response: ${response.body}');
      // Check if the response was successful
      if (data['success'] != true) {
        throw Exception('API request was not successful');
      }
      // Ensure the response contains a 'tickets' array
      if (data['tickets'] is! List) {
        throw FormatException(
            'Invalid response format - expected tickets array');
      }
      // Convert each JSON object to a Ticket
      return (data['tickets'] as List).map((json) {
        try {
          // Parse string dates to DateTime objects
          if (json['creationDate'] is String) {
            json['creationDate'] = DateTime.parse(json['creationDate']);
          }
          if (json['assignedDate'] is String) {
            json['assignedDate'] = DateTime.parse(json['assignedDate']);
          }
          if (json['finishDate'] is String) {
            json['finishDate'] = DateTime.parse(json['finishDate']);
          }
          if (json['resolvedDate'] is String) {
            json['resolvedDate'] = DateTime.parse(json['resolvedDate']);
          }
          if (json['closedDate'] is String) {
            json['closedDate'] = DateTime.parse(json['closedDate']);
          }

          return Ticket.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing ticket: $e\nJSON: $json');
          throw FormatException('Failed to parse ticket data');
        }
      }).toList();
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // Add this method to your TicketService class
  static Future<List<Ticket>> getTicketsByClient() async {
    // Get token from AuthService
    final token = await AuthService().getToken();
    if (token == null) {
      throw Exception('User not authenticated - Please login again');
    }

    final Uri url = Uri.parse('$_baseUrl/myTickets');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      // Check for API-level errors (err == true)
      if (responseData['err'] == true) {
        throw Exception(responseData['message'] ?? 'Error retrieving tickets');
      }

      // Check HTTP status code
      if (response.statusCode == 200) {
        final List<dynamic> ticketsJson = responseData['rows'];
        return ticketsJson
            .map<Ticket>((json) => Ticket.fromJson(json))
            .toList();
      } else {
        throw Exception('Server returned ${response.statusCode}: '
            '${responseData['message'] ?? 'No error message'}');
      }
    } catch (e) {
      throw Exception('Failed to get tickets: ${e.toString()}');
    }
  }

  static Future<Ticket> getTicketDetails(String ticketId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Authentication required');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tickets/$ticketId'), // Match backend route!
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      // Handle success (200 OK)
      if (response.statusCode == 200) {
        if (responseData['err'] == false) {
          return Ticket.fromJson(responseData['ticket']);
        } else {
          throw Exception(responseData['message'] ?? 'Invalid ticket data');
        }
      }
      // Handle known error cases
      else if (response.statusCode == 403) {
        throw Exception('Admin access required');
      } else if (response.statusCode == 404) {
        throw Exception('Ticket not found');
      }
      // Catch-all for other errors
      else {
        throw Exception(
          responseData['message'] ??
              'Failed to load ticket (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Ticket fetch failed: ${e.toString()}');
    }
  }

  static Future<List<Ticket>> getAllTicketsAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/all'),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          final List<dynamic> ticketsJson = responseData['data'];
          return ticketsJson
              .map<Ticket>((json) => Ticket.fromJson(json))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load tickets');
        }
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Error in getAllTicketsAdmin: $e');
      rethrow;
    }
  }

  static Future<Ticket> getAdminTicketDetails(String ticketId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('Authentification requise');

      final response = await http.get(
        Uri.parse('$_baseUrl/admin/$ticketId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['err'] == false) {
          return Ticket.fromJson(responseData['ticket']);
        } else {
          throw Exception(
              responseData['message'] ?? 'Échec de la récupération');
        }
      } else {
        throw Exception(
            'Erreur ${response.statusCode}: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Erreur admin récupération détails ticket: $e');
      rethrow;
    }
  }

  static Future<Ticket> assignTechnicianToTicket({
    required String ticketId,
    required String technicienId,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.patch(
        Uri.parse('$_baseUrl/AffecteTechnicienToTicket'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          '_id': ticketId,
          'technicienId': technicienId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['err'] == false) {
          return Ticket.fromJson(responseData['ticket']);
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to assign technician');
        }
      } else {
        throw Exception(
          'Server error (${response.statusCode}): ${responseData['message'] ?? response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error in assignTechnicianToTicket: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveSolution({
    required String ticketId,
    required String solutionContent,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/saveSolution'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ticketId': ticketId,
          'solution': solutionContent,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception('Failed to save solution: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Error in saveSolution: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSolutionDetails({
    required String solutionId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/solution/$solutionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['err'] == false) {
        return responseData['data'];
      } else {
        throw Exception(
            'Failed to load solution details: ${responseData['message']}');
      }
    } catch (e) {
      debugPrint('Error in getSolutionDetails: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> validateSolution({
    required String ticketId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validateSolution'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ticketId': ticketId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['err'] == false) {
          return {
            'success': true,
            'solution': responseData['rows'],
            'message':
                responseData['message'] ?? 'Solution validated successfully',
          };
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to validate solution');
        }
      } else {
        throw Exception(
          'Server error (${response.statusCode}): ${responseData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('Error in validateSolution: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getAllSolutions() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/knowledge-base'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['err'] == false) {
        return responseData['data']; // List of solutions
      } else {
        throw Exception(
            'Failed to load solutions: ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      debugPrint('Error in getAllSolutions: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopTechnicians() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/top-technicians'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load top technicians');
      }
    } catch (e) {
      throw Exception('Error fetching top technicians: $e');
    }
  }
}
