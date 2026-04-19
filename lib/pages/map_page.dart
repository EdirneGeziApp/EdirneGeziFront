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

  List<Place> _allPlaces = [];
  List<Category> _categories = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = true;
  int _selectedCategoryId = 0;
  Place? _selectedPlace;

  static const LatLng _edirneCenter = LatLng(41.6771, 26.5557);

  final Map<int, Color> _categoryColors = {
    1: Color(0xFF922B21),
    2: Color(0xFF1A5276),
    3: Color(0xFF784212),
    4: Color(0xFF145A32),
    5: Color(0xFF6C3483),
    6: Color(0xFF0E6655),
    7: Color(0xFF7D6608),
  };

  final Map<int, IconData> _categoryIcons = {
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
    _loadData();
  }

  Future<void> _loadData() async {
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

  void _filterByCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedPlace = null;
      if (categoryId == 0) {
        _filteredPlaces = _allPlaces;
      } else {
        _filteredPlaces = _allPlaces.where((p) => p.categoryId == categoryId).toList();
      }
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı.')),
        );
      }
    }
  }

  Color _getCategoryColor(int categoryId) {
    return _categoryColors[categoryId] ?? Colors.red[900]!;
  }

  IconData _getCategoryIcon(int categoryId) {
    return _categoryIcons[categoryId] ?? Icons.place_rounded;
  }

  String _getCategoryName(int categoryId) {
    return _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: 0, name: 'Diğer'),
    ).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red[900]))
          : Stack(
              children: [
                // Harita
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _edirneCenter,
                    initialZoom: 14,
                    onTap: (_, __) => setState(() => _selectedPlace = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.edirne_gezi_app',
                    ),
                    MarkerLayer(
                      markers: _filteredPlaces.map((place) {
                        final color = _getCategoryColor(place.categoryId);
                        final icon = _getCategoryIcon(place.categoryId);
                        final isSelected = _selectedPlace?.id == place.id;

                        return Marker(
                          point: LatLng(place.latitude, place.longitude),
                          width: isSelected ? 56 : 44,
                          height: isSelected ? 56 : 44,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedPlace = place);
                              _mapController.move(
                                LatLng(place.latitude, place.longitude),
                                16,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? color : Colors.white,
                                size: isSelected ? 28 : 22,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Üst kısım
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Row(
                              children: [
                                const Text(
                                  '🗺️ Edirne Haritası',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_filteredPlaces.length} mekan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Kategori filtresi
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              children: [
                                _buildFilterChip('Tümü', 0),
                                ..._categories.map((cat) => _buildFilterChip(cat.name, cat.id)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sağ butonlar
                Positioned(
                  right: 16,
                  bottom: _selectedPlace != null ? 220 : 100,
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

                // Seçili mekan kartı
                if (_selectedPlace != null)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailPage(place: _selectedPlace!),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                _selectedPlace!.imageUrl ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported_rounded, color: Colors.grey[400]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(_selectedPlace!.categoryId).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCategoryName(_selectedPlace!.categoryId),
                                      style: TextStyle(
                                        color: _getCategoryColor(_selectedPlace!.categoryId),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedPlace!.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedPlace!.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.red[900], size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, int id) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.red[900]! : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.red[900] : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.red[900], size: 22),
      ),
    );
  }
}