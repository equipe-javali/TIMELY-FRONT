import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SimpleHttpClient {
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      if (AppConfig.enableLogging) {
        print('GET request para: $url');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: AppConfig.apiTimeout));

      if (AppConfig.enableLogging) {
        print('Resposta (${response.statusCode}): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha na requisição: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Erro na requisição GET: $e');
      }
      throw Exception('Erro na requisição: $e');
    }
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      if (AppConfig.enableLogging) {
        print('POST request para: $url');
        print('Body: ${jsonEncode(body)}');
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(Duration(milliseconds: AppConfig.apiTimeout));

      if (AppConfig.enableLogging) {
        print('Resposta (${response.statusCode}): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha na requisição: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Erro na requisição POST: $e');
      }
      throw Exception('Erro na requisição: $e');
    }
  }
}