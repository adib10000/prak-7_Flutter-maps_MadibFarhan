import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import '../models/location_model.dart';

class ApiService {
  // MockAPI base URL (user-provided)
  static const String _baseUrl =
      'https://69399f35c8d59937aa0886ec.mockapi.io/api/v1/locations';

  // GET: Ambil daftar tempat makan
  Future<List<LocationModel>> getLocations() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // API may return a List or an object containing a list
        if (decoded is List) {
          return decoded.map((e) => LocationModel.fromJson(e)).toList();
        }
        if (decoded is Map && decoded['nearby_restaurants'] is List) {
          return (decoded['nearby_restaurants'] as List)
              .map((e) => LocationModel.fromJson(e))
              .toList();
        }
        // Unexpected shape — fallback to assets
        return _loadFromAssets();
      } else {
        // Non-200 — fallback to local data
        return _loadFromAssets();
      }
    } catch (e) {
      // Network error — fallback to local JSON bundled with the app
      return _loadFromAssets();
    }
  }

  // Load bundled JSON data as fallback
  Future<List<LocationModel>> _loadFromAssets() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/kampus4_30_restaurants.json');
      final decoded = json.decode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => LocationModel.fromJson(e)).toList();
      }
      if (decoded is Map && decoded['nearby_restaurants'] is List) {
        return (decoded['nearby_restaurants'] as List)
            .map((e) => LocationModel.fromJson(e))
            .toList();
      }
      return <LocationModel>[];
    } catch (e) {
      return <LocationModel>[];
    }
  }

  // POST: Kirim rekomendasi baru
  Future<bool> addLocation(LocationModel model) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(model.toJson()),
    );

    return response.statusCode == 201;
  }
}
