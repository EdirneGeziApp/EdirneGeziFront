import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/place.dart';
import '../constants/api_constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {
      "Content-Type": "application/json",
    };

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

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

  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    double radiusKm = 3,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/Places/nearby?lat=$lat&lng=$lng&radiusKm=$radiusKm',
    );

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

  Future<void> postReview(
    int placeId,
    String userName,
    String comment,
    int rating,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/$placeId/reviews');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(withAuth: true),
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
        headers: await _getHeaders(),
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final body = json.decode(response.body);
          throw Exception(body is String ? body : "Giriş başarısız.");
        } catch (_) {
          throw Exception(response.body.isNotEmpty ? response.body : "Giriş başarısız.");
        }
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>?> register(
    String userName,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/register');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          "userName": userName,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final body = json.decode(response.body);
          throw Exception(body is String ? body : "Kayıt başarısız.");
        } catch (_) {
          throw Exception(response.body.isNotEmpty ? response.body : "Kayıt başarısız.");
        }
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Admin: Tüm kullanıcıları getir
  Future<List<Map<String, dynamic>>> getUsers() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/users');

    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Admin: Kullanıcı sil
  Future<bool> deleteUser(int userId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/users/$userId');

    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(withAuth: true),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Admin: Tüm yorumları getir
  Future<List<Map<String, dynamic>>> getAllReviews() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/allreviews');

    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(withAuth: true),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Admin: Yorum sil
  Future<bool> deleteReview(int placeId, int reviewId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/Places/$placeId/reviews/$reviewId',
    );

    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(withAuth: true),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Admin: Mekan sil
  Future<bool> deletePlace(int placeId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places/$placeId');

    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(withAuth: true),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Admin: İstatistikler
  Future<Map<String, dynamic>> getStats() async {
    try {
      final results = await Future.wait([
        getPlaces(),
        getUsers(),
        getAllReviews(),
      ]);

      final places = results[0] as List<Place>;
      final users = results[1] as List<Map<String, dynamic>>;
      final reviews = results[2] as List<Map<String, dynamic>>;

      final reviewCounts = <int, int>{};

      for (var r in reviews) {
        final pid = r['placeId'] as int? ?? 0;
        reviewCounts[pid] = (reviewCounts[pid] ?? 0) + 1;
      }

      Place? mostReviewed;

      if (reviewCounts.isNotEmpty && places.isNotEmpty) {
        final topId = reviewCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        try {
          mostReviewed = places.firstWhere((p) => p.id == topId);
        } catch (_) {}
      }

      return {
        'totalPlaces': places.length,
        'totalUsers': users.length,
        'totalReviews': reviews.length,
        'mostReviewedPlace': mostReviewed?.name ?? 'Henüz yorum yok',
        'mostReviewedCount':
            mostReviewed != null ? (reviewCounts[mostReviewed.id] ?? 0) : 0,
      };
    } catch (e) {
      return {
        'totalPlaces': 0,
        'totalUsers': 0,
        'totalReviews': 0,
        'mostReviewedPlace': '-',
        'mostReviewedCount': 0,
      };
    }
  }
}