import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // Yeni oluşturduğun sayfayı bağladık

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edirne Gezi Rehberi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Edirne'ye yakışır bir kırmızı tema
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      // Uygulama artık TestPage yerine senin havalı HomePage'inden açılacak
      home: const HomePage(), 
    );
  }
}