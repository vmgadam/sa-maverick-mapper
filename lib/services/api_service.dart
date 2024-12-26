import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ApiService {
  final String baseUrl;
  final String apiToken;

  ApiService({
    required this.baseUrl,
    required this.apiToken,
  });

  Future<Map<String, dynamic>?> getApps() async {
    try {
      final url = '$baseUrl/apps';
      developer.log('GET Request: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        developer
            .log('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('Error in getApps', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getEvents(String appId,
      {int pageSize = 10}) async {
    try {
      final url = '$baseUrl/events?appId=$appId&page=1&pageSize=$pageSize';
      developer.log('GET Request: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        developer
            .log('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('Error in getEvents', error: e);
      rethrow;
    }
  }
}
