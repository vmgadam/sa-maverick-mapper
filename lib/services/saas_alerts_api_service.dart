import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SaasAlertsApiService {
  final String baseUrl;
  final String apiKey;

  SaasAlertsApiService({
    this.baseUrl =
        'https://us-central1-the-byway-248217.cloudfunctions.net/reportApi/api/v1',
    required this.apiKey,
  });

  // Helper method for making authenticated requests
  Future<http.Response> _makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    developer.log('Making $method request to: $uri');

    final headers = {
      'api_key': apiKey,
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    developer.log(
        'Using API key: ${apiKey.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey}');

    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: json.encode(body));
          break;
        case 'PUT':
          response =
              await http.put(uri, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      developer.log('Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        developer.log('Error Response Body: ${response.body}');
      }
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'Network error in _makeRequest',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Alerts endpoints
  Future<Map<String, dynamic>> getAlerts({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? severity,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (severity != null) {
        queryParams['severity'] = severity;
      }

      final response = await _makeRequest('/alerts', queryParams: queryParams);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getAlerts', error: e);
      rethrow;
    }
  }

  // Partners endpoints
  Future<Map<String, dynamic>> getPartners({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      final response =
          await _makeRequest('/partners', queryParams: queryParams);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load partners: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getPartners', error: e);
      rethrow;
    }
  }

  // Customers endpoints
  Future<Map<String, dynamic>> getCustomers({
    String? partnerId,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (partnerId != null) {
        queryParams['partnerId'] = partnerId;
      }

      final response =
          await _makeRequest('/customers', queryParams: queryParams);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getCustomers', error: e);
      rethrow;
    }
  }

  // Applications endpoints
  Future<Map<String, dynamic>> getApplications({
    String? customerId,
    String? partnerId,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (customerId != null) {
        queryParams['customerId'] = customerId;
      }
      if (partnerId != null) {
        queryParams['partnerId'] = partnerId;
      }

      final response =
          await _makeRequest('/applications', queryParams: queryParams);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load applications: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getApplications', error: e);
      rethrow;
    }
  }

  // Users endpoints
  Future<Map<String, dynamic>> getUsers({
    String? customerId,
    String? partnerId,
    String? applicationId,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (customerId != null) {
        queryParams['customerId'] = customerId;
      }
      if (partnerId != null) {
        queryParams['partnerId'] = partnerId;
      }
      if (applicationId != null) {
        queryParams['applicationId'] = applicationId;
      }

      final response = await _makeRequest('/users', queryParams: queryParams);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in getUsers', error: e);
      rethrow;
    }
  }

  // Alert Actions
  Future<void> updateAlertStatus(String alertId, String status) async {
    try {
      final response = await _makeRequest(
        '/alerts/$alertId/status',
        method: 'PUT',
        body: {'status': status},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update alert status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in updateAlertStatus', error: e);
      rethrow;
    }
  }

  Future<void> addAlertComment(String alertId, String comment) async {
    try {
      final response = await _makeRequest(
        '/alerts/$alertId/comments',
        method: 'POST',
        body: {'comment': comment},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add alert comment: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in addAlertComment', error: e);
      rethrow;
    }
  }

  // Report Events endpoint
  Future<List<dynamic>> getReportEvents({
    String? timeSort = 'desc',
    String? scroll = '5s',
    int pageSize = 1,
    String? product,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'timeSort': timeSort,
        'scroll': scroll,
        'pageSize': pageSize.toString(),
      };

      if (product != null) {
        queryParams['product.type'] = product;
      }

      developer.log('Fetching report events with params: $queryParams');

      final response =
          await _makeRequest('/reports/events', queryParams: queryParams);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        developer.log('Received ${jsonResponse.length} events');
        //developer.log('Response body: ${response.body}');
        return jsonResponse;
      } else {
        developer.log('Failed to load report events: ${response.statusCode}');
        //developer.log('Response body: ${response.body}');
        throw Exception('Failed to load report events: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('Error in getReportEvents',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<dynamic>> getReportEventsQuery({
    String? timeSort,
    String? scroll = '5s',
    int? pageSize,
    String? product,
  }) async {
    try {
      // Calculate time range for last hour
      final now = DateTime.now().toUtc();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final requestBody = {
        'body': {
          'query': {
            'bool': {
              'must': [],
              'filter': [
                {
                  'range': {
                    'time': {
                      'format': 'strict_date_optional_time',
                      'gte': oneHourAgo.toIso8601String(),
                      'lte': now.toIso8601String(),
                    }
                  }
                },
                if (product != null)
                  {
                    'match_phrase': {'product.type': product}
                  }
              ],
              'should': [],
              'must_not': []
            }
          },
          'sort': {'time': timeSort ?? 'desc'},
          'size': 5000
        },
        'scroll': scroll
      };

      developer.log(
          'Making request to /reports/events/query with body: ${json.encode(requestBody)}');

      final headers = {
        'api_key': apiKey,
        'accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final uri = Uri.parse('$baseUrl/reports/events/query');
      developer.log('Making request to: $uri');
      developer.log('Using headers: ${json.encode(headers)}');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      developer.log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hits'] != null && data['hits']['hits'] != null) {
          final hits = data['hits']['hits'] as List;
          developer.log('Found ${hits.length} hits');
          return hits.map((hit) => hit['_source']).toList();
        } else {
          developer.log('No hits found in response');
        }
      } else {
        developer.log('Request failed with status: ${response.statusCode}');
      }

      return [];
    } catch (e, stackTrace) {
      developer.log('Error in getReportEventsQuery',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getFields() async {
    try {
      // Load fields from local JSON file
      final jsonString = await rootBundle.loadString('config/fields.json');
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading SaaS Alerts fields: $e');
      return null;
    }
  }
}
