import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<Category> _categories = [];
  List<int> _favoriteIds = [];

  int _selectedCategoryId = 0;
  bool _isLoading = true;
  bool _isNearbyMode = false;

  String _userName = '';
  String _activeSearchLabel = '';

  String _weatherTemp = '--';
  String _weatherDesc = 'Yükleniyor...';
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  final Map<int, IconData> _categoryIcons = {
    0: Icons.apps_rounded,
    1: Icons.mosque_rounded,
    2: Icons.museum_rounded,
    3: Icons.restaurant_rounded,
    4: Icons.park_rounded,
    5: Icons.storefront_rounded,
    6: Icons.hot_tub_rounded,
    7: Icons.celebration_rounded,
    8: Icons.local_cafe_rounded,
    9: Icons.restaurant_rounded,
    10: Icons.hotel_rounded,
  };

  final List<String> _quickSearches = [
    'Yakınımdaki kafeler',
    'Tarihi yerler',
    'Yöresel lezzetler',
    'Parklar',
    'Müzeler',
    'Ciğer',
    'Köfte',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadFavorites();
    _loadUserName();
    _fetchWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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

        if (!mounted) return;

        setState(() {
          _weatherTemp = '${temp.round()}°C';
          _weatherDesc = _getWeatherDesc(code);
          _weatherIcon = _getWeatherIcon(code);
        });
      }
    } catch (e) {
      if (!mounted) return;
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

      if (!mounted) return;

      setState(() {
        _allPlaces = results[0] as List<Place>;
        _filteredPlaces = _allPlaces;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _apiService.getFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = ids);
  }

  Future<void> _toggleFavorite(int placeId) async {
    final isFav = _favoriteIds.contains(placeId);

    if (isFav) {
      await _apiService.removeFavorite(placeId);
    } else {
      await _apiService.addFavorite(placeId);
    }

    await _loadFavorites();
  }

  String _categoryName(int categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return '';
    }
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool _matchesSmartKeyword(Place place, String query) {
    final q = _normalize(query);
    final category = _normalize(_categoryName(place.categoryId));
    final name = _normalize(place.name);
    final desc = _normalize(place.description);

    final searchText = '$name $desc $category';

    if (searchText.contains(q)) return true;

    final Map<String, List<String>> smartWords = {
      'kafe': ['kafe', 'cafe', 'kahve', 'tatli', 'lezzet', 'restaurant'],
      'cafe': ['kafe', 'cafe', 'kahve', 'tatli', 'lezzet', 'restaurant'],
      'camii': ['camii', 'cami', 'selimiye', 'tarihi eser'],
      'cami': ['camii', 'cami', 'selimiye', 'tarihi eser'],
      'muze': ['muze', 'müze'],
      'park': ['park', 'doga', 'doğa', 'bahce'],
      'doga': ['doga', 'doğa', 'park'],
      'ciğer': ['ciger', 'ciğer', 'lezzet', 'restaurant'],
      'ciger': ['ciger', 'ciğer', 'lezzet', 'restaurant'],
      'kofte': ['kofte', 'köfte', 'lezzet', 'restaurant'],
      'köfte': ['kofte', 'köfte', 'lezzet', 'restaurant'],
      'tatli': ['tatli', 'tatlı', 'lezzet', 'kafe'],
      'tatlı': ['tatli', 'tatlı', 'lezzet', 'kafe'],
      'tarihi': ['tarihi', 'tarihi eser', 'camii'],
      'lezzet': ['lezzet', 'restaurant', 'kafe', 'ciğer', 'köfte'],
    };

    for (final entry in smartWords.entries) {
      if (q.contains(_normalize(entry.key))) {
        return entry.value.any((word) => searchText.contains(_normalize(word)));
      }
    }

    return false;
  }

  void _runFilter(String query) {
    final cleanQuery = query.trim();

    if (_normalize(cleanQuery).contains('yakinim') ||
        _normalize(cleanQuery).contains('yakindaki')) {
      _searchNearby(cleanQuery);
      return;
    }

    setState(() {
      _isNearbyMode = false;
      _activeSearchLabel = cleanQuery.isEmpty ? '' : cleanQuery;

      _filteredPlaces = _allPlaces.where((place) {
        final categoryMatch =
            _selectedCategoryId == 0 || place.categoryId == _selectedCategoryId;

        final queryMatch =
            cleanQuery.isEmpty || _matchesSmartKeyword(place, cleanQuery);

        return categoryMatch && queryMatch;
      }).toList();
    });
  }

  void _filterByCategory(int categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _runFilter(_searchController.text);
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage('Konum servisi kapalı. Lütfen konumu aç.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Yakındaki mekanlar için konum izni gerekli.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _searchNearby(String query) async {
    setState(() {
      _isLoading = true;
      _isNearbyMode = true;
      _activeSearchLabel = query;
    });

    final position = await _getCurrentPosition();

    if (position == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final nearbyPlaces = await _apiService.getNearbyPlaces(
      position.latitude,
      position.longitude,
      radiusKm: 5,
    );

    final cleanQuery = _normalize(query)
        .replaceAll('yakinimdaki', '')
        .replaceAll('yakinimda', '')
        .replaceAll('yakinim', '')
        .replaceAll('yakindaki', '')
        .replaceAll('yakinda', '')
        .trim();

    final filtered = nearbyPlaces.where((place) {
      final categoryMatch =
          _selectedCategoryId == 0 || place.categoryId == _selectedCategoryId;

      final queryMatch =
          cleanQuery.isEmpty || _matchesSmartKeyword(place, cleanQuery);

      return categoryMatch && queryMatch;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredPlaces = filtered;
      _isLoading = false;
    });
  }

  void _quickSearch(String text) {
    _searchController.text = text;
    _runFilter(text);
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _selectedCategoryId = 0;
      _isNearbyMode = false;
      _activeSearchLabel = '';
      _filteredPlaces = _allPlaces;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _listTitle() {
    if (_isNearbyMode) return '📍 Yakındaki Mekanlar';
    if (_activeSearchLabel.isNotEmpty) return '🔎 Arama Sonuçları';
    return '📍 Tüm Mekanlar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red[900]!, Colors.red[700]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, $_userName! 👋',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Edirne'yi Keşfet",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _weatherDesc,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _runFilter,
                        decoration: InputDecoration(
                          hintText: 'Mekan, lezzet veya “yakınımdaki kafe” ara...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.red[900],
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: _clearSearch,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.grey[500],
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickSearches.length,
                        itemBuilder: (context, index) {
                          final text = _quickSearches[index];

                          return GestureDetector(
                            onTap: () => _quickSearch(text),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCategoryChip('Tümü', 0, Icons.apps_rounded),
                  ..._categories.map(
                    (cat) => _buildCategoryChip(
                      cat.name,
                      cat.id,
                      _categoryIcons[cat.id] ?? Icons.place_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.red[900],
              onRefresh: () async {
                await _loadInitialData();
                await _loadFavorites();
                await _fetchWeather();
                _runFilter(_searchController.text);
              },
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPlaces.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 130),
                            Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sonuç bulunamadı.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '“kafe”, “ciğer”, “tarihi yerler” veya “yakınımdaki kafe” deneyebilirsin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: _filteredPlaces.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _listTitle(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_filteredPlaces.length} mekan',
                                        style: TextStyle(
                                          color: Colors.red[900],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
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

  Widget _buildCategoryChip(String label, int id, IconData icon) {
    final bool isSelected = _selectedCategoryId == id;

    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.red[900]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.red[900],
            ),
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
    final bool isFav = _favoriteIds.contains(place.id);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailPage(place: place),
          ),
        );

        _loadFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    place.imageUrl ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _categoryName(place.categoryId).isEmpty
                          ? 'Diğer'
                          : _categoryName(place.categoryId),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(place.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
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
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.red[900],
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Edirne',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        'Detayları Gör →',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
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