import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'place_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Place> _allPlaces = [];
  List<Category> _categories = [];
  List<Place> _filteredPlaces = [];

  bool _isLoading = true;
  int _selectedCategoryId = 0;
  Place? _selectedPlace;
  String _searchQuery = '';

  static const LatLng _edirneCenter = LatLng(41.6771, 26.5557);

  final Map<int, Color> _categoryColors = {
    1: Color(0xFF8E2A2A),
    2: Color(0xFF1565C0),
    3: Color(0xFFE67E22),
    4: Color(0xFF2E7D32),
    5: Color(0xFF6D4C41),
    6: Color(0xFF00897B),
    7: Color(0xFF8E24AA),
    8: Color(0xFF795548),
    9: Color(0xFFD84315),
    10: Color(0xFF455A64),
  };

  final Map<int, IconData> _categoryIcons = {
    1: Icons.account_balance_rounded,
    2: Icons.museum_rounded,
    3: Icons.restaurant_menu_rounded,
    4: Icons.park_rounded,
    5: Icons.storefront_rounded,
    6: Icons.hot_tub_rounded,
    7: Icons.celebration_rounded,
    8: Icons.local_cafe_rounded,
    9: Icons.restaurant_rounded,
    10: Icons.hotel_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isValidEdirneCoordinate(Place place) {
    return place.latitude >= 41.55 &&
        place.latitude <= 41.85 &&
        place.longitude >= 26.35 &&
        place.longitude <= 26.85;
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _apiService.getPlaces(),
        _apiService.getCategories(),
      ]);

      final places =
          (results[0] as List<Place>).where(_isValidEdirneCoordinate).toList();

      if (!mounted) return;

      setState(() {
        _allPlaces = places;
        _filteredPlaces = places;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mekanlar yüklenirken hata oluştu.')),
      );
    }
  }

  void _applyFilters({bool moveMap = false}) {
    List<Place> result = List.from(_allPlaces);

    if (_selectedCategoryId != 0) {
      result = result.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();

      result = result.where((place) {
        final name = place.name.toLowerCase();
        final description = place.description.toLowerCase();
        final categoryName = _getCategoryName(place.categoryId).toLowerCase();

        return name.contains(query) ||
            description.contains(query) ||
            categoryName.contains(query);
      }).toList();
    }

    setState(() {
      _filteredPlaces = result;
      _selectedPlace = null;
    });

    if (result.length == 1) {
      _mapController.move(
        LatLng(result.first.latitude, result.first.longitude),
        17,
      );
    } else if (moveMap && result.isNotEmpty) {
      _mapController.move(
        LatLng(result.first.latitude, result.first.longitude),
        14,
      );
    }
  }

  void _filterByCategory(int categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters(moveMap: true);
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı.')),
      );
    }
  }

  Color _getCategoryColor(int categoryId) {
    return _categoryColors[categoryId] ?? const Color(0xFFB71C1C);
  }

  IconData _getCategoryIcon(int categoryId) {
    return _categoryIcons[categoryId] ?? Icons.place_rounded;
  }

  String _getCategoryName(int categoryId) {
    return _categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => Category(id: 0, name: 'Diğer'),
        )
        .name;
  }

  List<Marker> _buildMarkers() {
    return _filteredPlaces.map((place) {
      final color = _getCategoryColor(place.categoryId);
      final icon = _getCategoryIcon(place.categoryId);
      final isSelected = _selectedPlace?.id == place.id;

      return Marker(
        point: LatLng(place.latitude, place.longitude),
        width: isSelected ? 58 : 46,
        height: isSelected ? 58 : 46,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedPlace = place);
            _mapController.move(LatLng(place.latitude, place.longitude), 16);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: isSelected ? 38 : 31,
                  height: isSelected ? 38 : 31,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isSelected ? 22 : 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchQuery = '';
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red[900]))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _edirneCenter,
                    initialZoom: 14,
                    onTap: (_, __) {
                      setState(() => _selectedPlace = null);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.edirne_gezi_app',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.red[900],
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.map_rounded,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Edirne Haritası',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Mekanları kategoriye göre keşfet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${_filteredPlaces.length} mekan',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  _searchQuery = value;
                                  _applyFilters();
                                },
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Mekan ara...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.red[900],
                                    size: 22,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          onPressed: _clearSearch,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              height: 38,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildFilterChip('Tümü', 0),
                                  ..._categories.map(
                                    (cat) => _buildFilterChip(cat.name, cat.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: _selectedPlace != null ? 220 : 105,
                  child: Column(
                    children: [
                      _buildMapButton(
                        icon: Icons.my_location_rounded,
                        onTap: _goToMyLocation,
                      ),
                      const SizedBox(height: 10),
                      _buildMapButton(
                        icon: Icons.home_rounded,
                        onTap: () => _mapController.move(_edirneCenter, 14),
                      ),
                      const SizedBox(height: 10),
                      _buildMapButton(
                        icon: Icons.add_rounded,
                        onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMapButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_filteredPlaces.isEmpty) _buildEmptyResultCard(),

                if (_selectedPlace != null) _buildSelectedPlaceCard(),
              ],
            ),
    );
  }

  Widget _buildEmptyResultCard() {
    return Positioned(
      top: 235,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: Colors.red[900]),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Aramanıza uygun mekan bulunamadı.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlaceCard() {
    final place = _selectedPlace!;
    final color = _getCategoryColor(place.categoryId);

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  place.imageUrl ?? '',
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 86,
                      height: 86,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getCategoryName(place.categoryId),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.red[900],
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int id) {
    final isSelected = _selectedCategoryId == id;

    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? Colors.red[900]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.red[900], size: 23),
      ),
    );
  }
}