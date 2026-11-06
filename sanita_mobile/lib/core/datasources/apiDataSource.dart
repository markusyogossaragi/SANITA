import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/apiConstants.dart';

class ApiDataSource {
  static final ApiDataSource _instance = ApiDataSource._internal();
  factory ApiDataSource() => _instance;
  ApiDataSource._internal();

  final http.Client _client = http.Client();
  String? _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final map = {
      'Content-Type': 'application/json',
      'X-Requested-With': 'SANITA-Mobile-App',
      'X-Client-Version': '1.0.0-anti-breach',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  Uri _uri(String endpoint) {
    return Uri.parse('${ApiConstants.baseUrl}$endpoint');
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(_uri(endpoint), headers: _headers, body: jsonEncode(body))
          .timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw Exception(data['message'] ?? 'Permintaan gagal (${response.statusCode})');
    } catch (e) {
      throw Exception('Koneksi aman gagal: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client
          .get(_uri(endpoint), headers: _headers)
          .timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw Exception(data['message'] ?? 'Permintaan gagal (${response.statusCode})');
    } catch (e) {
      throw Exception('Koneksi aman gagal: ${e.toString()}');
    }
  }
}