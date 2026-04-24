import 'dart:io';

class ApiConstants {
  // API istekleri için otomatik adres seçici
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5174/api"; // Arkadaşının Android emülatörü için
    } else {
      return "http://127.0.0.1:5174/api"; // Senin iOS simülatörün için
    }
  }

  // Resimler için otomatik adres seçici (sonunda /api olmaz)
  static String get imageBaseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5174";
    } else {
      return "http://127.0.0.1:5174";
    }
  }
}