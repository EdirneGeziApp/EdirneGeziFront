import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/place.dart'; 
import '../constants/api_constants.dart';

class ApiService {
  // Kategori servisi
  Future<List<Category>> getCategories() async {
    // Adreslerin sonuna / ekleyerek çakışmayı önledik
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

  // 74 VERİNİ GETİRECEK OLAN FONKSİYON
  Future<List<Place>> getPlaces() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Place.fromJson(json)).toList();
      } else {
        throw Exception('Hata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mekanlar çekilemedi: $e');
    }
  }
}