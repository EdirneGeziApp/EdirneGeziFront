import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/place.dart';
import '../constants/api_constants.dart';

class ApiService {
  Future<List<Category>> getCategories() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Categories');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Hata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<List<Place>> getPlaces() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          var place = Place.fromJson(item);
          if (place.imageUrl != null && place.imageUrl!.trim().isNotEmpty) {
            if (!place.imageUrl!.toLowerCase().startsWith('http')) {
              place.imageUrl = "${ApiConstants.imageBaseUrl}/${place.imageUrl}";
            }
          }
          return place;
        }).toList();
      } else {
        throw Exception('Hata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mekanlar çekilemedi: $e');
    }
  }

  Future<List<Place>> getNearbyPlaces(double lat, double lng, {double radiusKm = 3}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/nearby?lat=$lat&lng=$lng&radiusKm=$radiusKm');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReviews(int placeId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/$placeId/reviews');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> postReview(int placeId, String userName, String comment, int rating) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/$placeId/reviews');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userName": userName,
          "comment": comment,
          "rating": rating,
          "placeId": placeId,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Yorum gönderilemedi.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body is String ? body : "Giriş başarısız.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>?> register(String userName, String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userName": userName, "email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body is String ? body : "Kayıt başarısız.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}