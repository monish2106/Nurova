import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_model.dart';

class ApiService {
  // Change this to your deployed Render/Replit URL
  static String _baseUrl = 'http://localhost:5000';

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'http://localhost:5000';
  }

  static Future<void> saveBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  static Future<PredictionModel> predictDistraction(
      Map<String, dynamic> features) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/predict_distraction'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(features),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return PredictionModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Prediction failed: ${response.statusCode}');
  }

  static Future<PersonalityModel> getPersonality(
      List<Map<String, dynamic>> history) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/get_personality'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'usage_history': history}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return PersonalityModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Personality failed: ${response.statusCode}');
  }

  static Future<List<ContentModel>> getRecommendations({
    required String query,
    required String riskLevel,
    required String cluster,
  }) async {
    final uri = Uri.parse('$_baseUrl/recommend_content').replace(queryParameters: {
      'query': query,
      'risk_level': riskLevel,
      'cluster': cluster,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ContentModel.fromJson(e)).toList();
    }
    throw Exception('Recommendations failed');
  }

  static Future<void> logSession(Map<String, dynamic> sessionData) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/log_session'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sessionData),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Silently fail - offline-first
    }
  }
}
