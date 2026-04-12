import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/place.dart'; 
import '../constants/api_constants.dart';

class ApiService {
  // Kategori servisi
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

  // 74 MEKANI GETİRECEK OLAN FONKSİYON
  Future<List<Place>> getPlaces() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/Places');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        
        return data.map((item) {
          var place = Place.fromJson(item);
          
          // RESİM DÜZELTME MANTIĞI:
          if (place.imageUrl != null && place.imageUrl!.trim().isNotEmpty) {
            
            // Eğer link zaten "http" veya "https" ile başlıyorsa (Internet linki ise)
            if (place.imageUrl!.toLowerCase().startsWith('http')) {
              // HİÇBİR ŞEY YAPMA - Olduğu gibi kalsın (Senin 74 verin için bu geçerli)
            } 
            else {
              // Eğer yerel yolsa (Örn: images/selimiye_camii.jpg) başına IP ekle
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
}