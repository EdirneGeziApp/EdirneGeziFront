import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'login_page.dart';
import 'suggest_place_page.dart';
import 'suggest_route_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = '';
  String _userEmail = '';

  int _favoriteCount = 0;
  int _placeSuggestionCount = 0;
  int _routeSuggestionCount = 0;

  bool _isStatsLoading = true;

  final Color mainRed = const Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _loadUserAndStats();
  }

  Future<void> _loadUserAndStats() async {
    await _loadUser();
    await _loadProfileStats();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('userName') ?? 'Gezgin';
      _userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  Future<int> _getCount(String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    }

    return 0;
  }

  Future<void> _loadProfileStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isStatsLoading = false;
      });
      return;
    }

    try {
      final favoriteCount = await _getCount('/Favorites/count', token);
      final placeSuggestionCount =
          await _getCount('/PlaceSuggestions/count', token);
      final routeSuggestionCount =
          await _getCount('/RouteSuggestions/count', token);

      if (!mounted) return;

      setState(() {
        _favoriteCount = favoriteCount;
        _placeSuggestionCount = placeSuggestionCount;
        _routeSuggestionCount = routeSuggestionCount;
        _isStatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStatsLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('role');
    await prefs.remove('isLoggedIn');
    await prefs.remove('isAdmin');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? mainRed;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: itemColor, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: mainRed, size: 22),
            const SizedBox(height: 7),
            _isStatsLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: mainRed,
                    ),
                  )
                : Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(
            color: mainRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: mainRed,
          onRefresh: _loadProfileStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        mainRed,
                        const Color(0xFFD32F2F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: mainRed.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: 38,
                            color: mainRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_userEmail.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _infoBox(
                            icon: Icons.favorite_rounded,
                            title: 'Favoriler',
                            value: _favoriteCount,
                          ),
                          const SizedBox(width: 10),
                          _infoBox(
                            icon: Icons.add_location_alt_rounded,
                            title: 'Mekan Öneri',
                            value: _placeSuggestionCount,
                          ),
                          const SizedBox(width: 10),
                          _infoBox(
                            icon: Icons.alt_route_rounded,
                            title: 'Rota Öneri',
                            value: _routeSuggestionCount,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hesap İşlemleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _actionCard(
                  icon: Icons.add_location_alt_rounded,
                  title: 'Mekan Öner',
                  subtitle: 'Edirne için yeni bir gezilecek yer öner',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuggestPlacePage(),
                      ),
                    );
                    _loadProfileStats();
                  },
                ),
                _actionCard(
                  icon: Icons.alt_route_rounded,
                  title: 'Rota Öner',
                  subtitle: 'Kullanıcılar için yeni bir gezi rotası oluştur',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SuggestRoutePage(),
                      ),
                    );
                    _loadProfileStats();
                  },
                ),
                _actionCard(
                  icon: Icons.logout_rounded,
                  title: 'Çıkış Yap',
                  subtitle: 'Hesabından güvenli şekilde çıkış yap',
                  color: Colors.black87,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}