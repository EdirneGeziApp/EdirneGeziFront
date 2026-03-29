import 'dart:io';

class ApiConstants {
  // Emülatörler için doğru localhost adresini otomatik seçen yapı
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5174/api'; 
    } else {
      return 'http://127.0.0.1:5174/api'; 
    }
  }
}