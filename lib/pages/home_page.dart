import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'place_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<Category> _categories = [];
  List<String> _favoriteIds = [];
  int _selectedCategoryId = 0;
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  String _userName = '';

  String _weatherTemp = '--';
  String _weatherDesc = 'Yükleniyor...';
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  final TextEditingController _searchController = TextEditingController();

  final Map<int, IconData> _categoryIcons = {
    0: Icons.apps_rounded,
    1: Icons.mosque_rounded,
    2: Icons.museum_rounded,
    3: Icons.restaurant_rounded,
    4: Icons.park_rounded,
    5: Icons.storefront_rounded,
    6: Icons.hot_tub_rounded,
    7: Icons.celebration_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFavorites();
    _loadUserName();
    _fetchWeather();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'Gezgin');
  }

  Future<void> _fetchWeather() async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=41.6771&longitude=26.5557&current_weather=true&timezone=Europe%2FIstanbul',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final code = current['weathercode'] as int;
        setState(() {
          _weatherTemp = '${temp.round()}°C';
          _weatherDesc = _getWeatherDesc(code);
          _weatherIcon = _getWeatherIcon(code);
        });
      }
    } catch (e) {
      setState(() {
        _weatherDesc = 'Alınamadı';
        _weatherIcon = Icons.cloud_off_rounded;
      });
    }
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return 'Açık ve Güneşli ☀️';
    if (code <= 3) return 'Parçalı Bulutlu ⛅';
    if (code <= 49) return 'Sisli 🌫️';
    if (code <= 59) return 'Çiseleyen Yağmur 🌦️';
    if (code <= 69) return 'Yağmurlu 🌧️';
    if (code <= 79) return 'Karlı ❄️';
    if (code <= 82) return 'Sağanaklı 🌧️';
    if (code <= 99) return 'Fırtınalı ⛈️';
    return 'Değişken';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 49) return Icons.foggy;
    if (code <= 69) return Icons.grain;
    if (code <= 79) return Icons.ac_unit_rounded;
    if (code <= 99) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _apiService.getPlaces(),
        _apiService.getCategories(),
      ]);
      setState(() {
        _allPlaces = results[0] as List<Place>;
        _filteredPlaces = _allPlaces;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favoriteIds = prefs.getStringList('favorites') ?? []);
  }

  Future<void> _toggleFavorite(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(placeId)) {
        _favoriteIds.remove(placeId);
      } else {
        _favoriteIds.add(placeId);
      }
    });
    await prefs.setStringList('favorites', _favoriteIds);
  }

  void _runFilter(String query) {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final nameMatch = place.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = _selectedCategoryId == 0 || place.categoryId == _selectedCategoryId;
        final favMatch = !_showOnlyFavorites || _favoriteIds.contains(place.id.toString());
        return nameMatch && categoryMatch && favMatch;
      }).toList();
    });
  }

  void _filterByCategory(int categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _runFilter(_searchController.text);
  }

  void _toggleFavoritesFilter() {
    setState(() => _showOnlyFavorites = !_showOnlyFavorites);
    _runFilter(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ÜST KISIM - Sabit kalır, kaydırılmaz
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red[900]!, Colors.red[700]!],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Karşılama + Hava Durumu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, $_userName! 👋',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Edirne'yi Keşfet",
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(_weatherIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weatherTemp,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _weatherDesc,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ARAMA KUTUSU - Sabit kalır
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _runFilter,
                        decoration: InputDecoration(
                          hintText: 'Mekan veya lezzet ara...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.red[900]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // KATEGORİLER - Sabit kalır
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildFavChip(),
                  const SizedBox(width: 6),
                  _buildCategoryChip('Tümü', 0, Icons.apps_rounded),
                  ...(_categories.map((cat) => _buildCategoryChip(
                        cat.name,
                        cat.id,
                        _categoryIcons[cat.id] ?? Icons.place_rounded,
                      ))),
                ],
              ),
            ),
          ),

          // MEKAN LİSTESİ - Sadece bu kısım kaydırılır
          Expanded(
            child: RefreshIndicator(
              color: Colors.red[900],
              onRefresh: () async {
                await _loadInitialData();
                await _fetchWeather();
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPlaces.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                _showOnlyFavorites ? 'Henüz favori eklemediniz.' : 'Sonuç bulunamadı.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: _filteredPlaces.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _showOnlyFavorites ? '❤️ Favorilerim' : '📍 Tüm Mekanlar',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_filteredPlaces.length} mekan',
                                        style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return _buildPlaceCard(_filteredPlaces[index - 1]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavChip() {
    return GestureDetector(
      onTap: _toggleFavoritesFilter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _showOnlyFavorites ? Colors.red[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _showOnlyFavorites ? Colors.red[900]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_rounded, size: 16, color: _showOnlyFavorites ? Colors.white : Colors.red[900]),
            const SizedBox(width: 5),
            Text(
              'Favoriler',
              style: TextStyle(
                color: _showOnlyFavorites ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int id, IconData icon) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.red[900]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.red[900]),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    bool isFav = _favoriteIds.contains(place.id.toString());
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaceDetailPage(place: place)),
        );
        _loadFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    place.imageUrl ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported_rounded, size: 50, color: Colors.grey[400]),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _categories.firstWhere(
                        (c) => c.id == place.categoryId,
                        orElse: () => Category(id: 0, name: 'Diğer'),
                      ).name,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(place.id.toString()),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: Colors.red[900],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    place.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.red[900]),
                      const SizedBox(width: 4),
                      const Text('Edirne', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text(
                        'Detayları Gör →',
                        style: TextStyle(fontSize: 13, color: Colors.red[900], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}