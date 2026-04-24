import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/main_page.dart';
import 'pages/login_page.dart';
import 'pages/admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool isAdmin = prefs.getBool('isAdmin') ?? false;
  final String? token = prefs.getString('token');

  runApp(
    MyApp(
      isLoggedIn: isLoggedIn && token != null && token.isNotEmpty,
      isAdmin: isAdmin,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isAdmin;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edirne Gezi Rehberi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: isLoggedIn
          ? (isAdmin ? const AdminPage() : const MainPage())
          : const LoginPage(),
    );
  }
}