import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import 'place_detail_page.dart';
import 'route_map_page.dart';

enum TransportMode { walking, car, publicTransport }

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ApiService _apiService = ApiService();

  List<Place> _allPlaces = [];
  List<Category> _categories = [];
  List<Place> _nearbyPlaces = [];
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _approvedUserRoutes = [];
  List<Map<String, dynamic>> _topFavoritePlaces = [];

  final TextEditingController _userRouteSearchController =
      TextEditingController();
  String _userRouteFilterText = '';

  List<Place> _suggestedRoutePlaces = [];
  int _selectedRouteCategoryId = 0;
  TransportMode _selectedTransportMode = TransportMode.walking;

  Place? _randomPlace;
  Place? _todayRecommendation;

  bool _isLoading = true;
  bool _isLoadingNearby = false;
  bool _isGeneratingRoute = false;
  String _locationStatus = '';

  final List<Map<String, dynamic>> _factCards = [
    {
      'icon': Icons.history_edu_rounded,
      'color': Color(0xFF6C3483),
      'title': 'Tarihin Başkenti',
      'fact':
          'Edirne, Osmanlı İmparatorluğu\'nun 1363-1458 yılları arasında başkentliğini yapmıştır.',
    },
    {
      'icon': Icons.architecture_rounded,
      'color': Color(0xFF1A5276),
      'title': 'Mimar Sinan\'ın Şaheseri',
      'fact':
          'Selimiye Camii, Mimar Sinan\'ın kendi ifadesiyle "ustalık eserim" dediği yapıdır ve UNESCO Dünya Mirası listesindedir.',
    },
    {
      'icon': Icons.sports_rounded,
      'color': Color(0xFF145A32),
      'title': 'Dünyanın En Eski Sporu',
      'fact':
          'Kırkpınar Yağlı Güreşleri, 1346\'dan beri kesintisiz düzenlenen dünyanın en eski spor organizasyonudur.',
    },
    {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF784212),
      'title': 'Tava Ciğerin Vatanı',
      'fact':
          'Edirne tava ciğeri, ince dilimlenmiş kuzu ciğerinin yüksek ateşte pişirilmesiyle yapılan eşsiz bir lezzettir.',
    },
    {
      'icon': Icons.water_rounded,
      'color': Color(0xFF1F618D),
      'title': 'Üç Nehrin Şehri',
      'fact':
          'Edirne, Meriç, Tunca ve Arda nehirlerinin kavşağında kurulmuş, suyla iç içe bir şehirdir.',
    },
    {
      'icon': Icons.synagogue_rounded,
      'color': Color(0xFF7D6608),
      'title': 'Hoşgörünün Şehri',
      'fact':
          'Edirne\'deki Büyük Sinagog, restore edilerek Avrupa\'nın en büyük sinagoglarından biri haline gelmiştir.',
    },
  ];

  final Map<int, IconData> _categoryIcons = {
    1: Icons.mosque_rounded,
    2: Icons.museum_rounded,
    3: Icons.restaurant_rounded,
    4: Icons.park_rounded,
    5: Icons.storefront_rounded,
    6: Icons.hot_tub_rounded,
    7: Icons.celebration_rounded,
  };

  final Map<int, Color> _categoryColors = {
    1: Color(0xFF922B21),
    2: Color(0xFF1A5276),
    3: Color(0xFF784212),
    4: Color(0xFF145A32),
    5: Color(0xFF6C3483),
    6: Color(0xFF0E6655),
    7: Color(0xFF7D6608),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _userRouteSearchController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    return '${ApiConstants.imageBaseUrl}$imageUrl';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getPlaces(),
        _apiService.getCategories(),
        _apiService.getApprovedRouteSuggestions(),
        _apiService.getTopFavoritePlaces(),
      ]);

      final places = results[0] as List<Place>;
      final categories = results[1] as List<Category>;
      final approvedUserRoutes = results[2] as List<Map<String, dynamic>>;
      final topFavoritePlaces = results[3] as List<Map<String, dynamic>>;

      List<Map<String, dynamic>> allReviews = [];

      for (var place in places) {
        final reviews = await _apiService.getReviews(place.id);

        for (var review in reviews) {
          allReviews.add({...review, 'placeId': place.id});
        }
      }

      if (!mounted) return;

      setState(() {
        _allPlaces = places;
        _categories = categories;
        _approvedUserRoutes = approvedUserRoutes;
        _allReviews = allReviews;
        _topFavoritePlaces = topFavoritePlaces;
        _randomPlace = places.isNotEmpty
            ? places[Random().nextInt(places.length)]
            : null;
        _isLoading = false;
      });

      await _loadTodayRecommendation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodayRecommendation() async {
    final data = await _apiService.getTodayRecommendation();

    if (!mounted) return;

    if (data == null || _allPlaces.isEmpty) {
      setState(() {
        _todayRecommendation = _randomPlace;
      });
      return;
    }

    final recommendedId = data['id'];
    Place? recommendedPlace;

    try {
      recommendedPlace = _allPlaces.firstWhere(
        (place) => place.id == recommendedId,
      );
    } catch (_) {
      recommendedPlace = _randomPlace;
    }

    setState(() {
      _todayRecommendation = recommendedPlace;
    });
  }

  Future<void> _newRandomPlace() async {
    await _loadTodayRecommendation();
  }

  String _getCategoryName(int categoryId) {
    return _categories
        .firstWhere(
          (category) => category.id == categoryId,
          orElse: () => Category(id: 0, name: 'Diğer'),
        )
        .name;
  }

  double _calculateDistanceFromCoordinates(
    double lat1Value,
    double lon1Value,
    double lat2Value,
    double lon2Value,
  ) {
    const double earthRadius = 6371;

    final double lat1 = lat1Value * pi / 180;
    final double lon1 = lon1Value * pi / 180;
    final double lat2 = lat2Value * pi / 180;
    final double lon2 = lon2Value * pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return earthRadius * c;
  }

  double _calculateDistance(Place a, Place b) {
    return _calculateDistanceFromCoordinates(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  double _calculateDistanceFromUser(Position position, Place place) {
    return _calculateDistanceFromCoordinates(
      position.latitude,
      position.longitude,
      place.latitude,
      place.longitude,
    );
  }

  double _getStartRadiusByTransportMode() {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return 2.0;
      case TransportMode.publicTransport:
        return 5.0;
      case TransportMode.car:
        return 15.0;
    }
  }

  double _getStepDistanceByTransportMode() {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return 1.5;
      case TransportMode.publicTransport:
        return 4.0;
      case TransportMode.car:
        return 10.0;
    }
  }

  int _getRouteLimitByTransportMode() {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return 4;
      case TransportMode.publicTransport:
        return 5;
      case TransportMode.car:
        return 6;
    }
  }

  String _getTransportInfoText() {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return 'Yaya rota: Konumuna en yakın 2 km içindeki mekanlardan oluşturulur.';
      case TransportMode.car:
        return 'Araç rota: Konumuna en yakın 15 km içindeki mekanlardan oluşturulur.';
      case TransportMode.publicTransport:
        return 'Toplu taşıma rota: Konumuna en yakın 5 km içindeki mekanlardan oluşturulur.';
    }
  }

  String _getTransportModeName() {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return 'Yaya';
      case TransportMode.publicTransport:
        return 'Toplu taşıma';
      case TransportMode.car:
        return 'Araç';
    }
  }

  double _calculateTotalRouteDistance() {
    if (_suggestedRoutePlaces.length < 2) return 0;

    double total = 0;

    for (int i = 0; i < _suggestedRoutePlaces.length - 1; i++) {
      total += _calculateDistance(
        _suggestedRoutePlaces[i],
        _suggestedRoutePlaces[i + 1],
      );
    }

    return total;
  }

  int _calculateEstimatedDurationMinutes(double distanceKm) {
    switch (_selectedTransportMode) {
      case TransportMode.walking:
        return (distanceKm / 5 * 60).round();
      case TransportMode.publicTransport:
        return (distanceKm / 20 * 60).round();
      case TransportMode.car:
        return (distanceKm / 35 * 60).round();
    }
  }

  Future<Position?> _getCurrentPositionForRoute() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rota oluşturmak için konum izni gerekli.'),
          ),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Konum izni kalıcı olarak reddedildi. Ayarlardan açmalısınız.',
          ),
        ),
      );
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  List<Place> _sortPlacesByNearestRouteFromUser(
    List<Place> places,
    Position userPosition,
  ) {
    if (places.length <= 1) return places;

    final double startRadius = _getStartRadiusByTransportMode();
    final double stepDistance = _getStepDistanceByTransportMode();

    final List<Place> candidates = places.where((place) {
      return _calculateDistanceFromUser(userPosition, place) <= startRadius;
    }).toList();

    if (candidates.length <= 1) return candidates;

    candidates.sort(
      (a, b) => _calculateDistanceFromUser(
        userPosition,
        a,
      ).compareTo(_calculateDistanceFromUser(userPosition, b)),
    );

    final List<Place> startPool = candidates.take(8).toList();
    final List<Place> remaining = candidates.toList();
    final List<Place> route = [];

    final Place startPlace = startPool[Random().nextInt(startPool.length)];

    remaining.remove(startPlace);
    route.add(startPlace);

    Place current = startPlace;

    while (remaining.isNotEmpty) {
      final nearbyPlaces = remaining.where((place) {
        return _calculateDistance(current, place) <= stepDistance;
      }).toList();

      if (nearbyPlaces.isEmpty) break;

      nearbyPlaces.sort(
        (a, b) => _calculateDistance(
          current,
          a,
        ).compareTo(_calculateDistance(current, b)),
      );

      current = nearbyPlaces.first;
      route.add(current);
      remaining.remove(current);
    }

    return route;
  }

  Future<void> _generateSuggestedRoute() async {
    if (_selectedRouteCategoryId == -1) {
      setState(() {
        _suggestedRoutePlaces = [];
      });

      final filteredRoutes = _getFilteredUserRoutes();

      if (_approvedUserRoutes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Henüz onaylanmış kullanıcı rotası yok.'),
          ),
        );
      } else if (filteredRoutes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu filtreye uygun kullanıcı rotası bulunamadı.'),
          ),
        );
      }

      return;
    }

    setState(() {
      _isGeneratingRoute = true;
      _suggestedRoutePlaces = [];
    });

    try {
      final position = await _getCurrentPositionForRoute();

      if (position == null) {
        setState(() => _isGeneratingRoute = false);
        return;
      }

      List<Place> filteredPlaces;

      if (_selectedRouteCategoryId == 0) {
        filteredPlaces = _allPlaces.toList();
      } else {
        filteredPlaces = _allPlaces
            .where((place) => place.categoryId == _selectedRouteCategoryId)
            .toList();
      }

      if (filteredPlaces.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu kategori için rota oluşturacak yeterli mekan yok.',
            ),
          ),
        );
        setState(() => _isGeneratingRoute = false);
        return;
      }

      final optimizedRoute = _sortPlacesByNearestRouteFromUser(
        filteredPlaces,
        position,
      );

      if (optimizedRoute.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedTransportMode == TransportMode.walking
                  ? 'Yaya rota için konumuna yakın yeterli mekan bulunamadı.'
                  : 'Seçilen ulaşım tipine uygun yakınlıkta yeterli mekan bulunamadı.',
            ),
          ),
        );

        setState(() => _isGeneratingRoute = false);
        return;
      }

      setState(() {
        _suggestedRoutePlaces = optimizedRoute
            .take(_getRouteLimitByTransportMode())
            .toList();
        _isGeneratingRoute = false;
      });
    } catch (e) {
      setState(() => _isGeneratingRoute = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı. Rota oluşturulamadı.')),
      );
    }
  }

  void _openRouteMap() {
    if (_selectedRouteCategoryId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı önerileri metin rota olarak gösteriliyor.'),
        ),
      );
      return;
    }

    if (_suggestedRoutePlaces.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce rota oluşturmalısınız.')),
      );
      return;
    }

    final routePlaces = _suggestedRoutePlaces.map((place) {
      return RoutePlace(
        id: place.id,
        name: place.name,
        latitude: place.latitude,
        longitude: place.longitude,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouteMapPage(places: routePlaces)),
    );
  }

  List<Place> _getMostReviewed() {
    final reviewCounts = <int, int>{};

    for (var review in _allReviews) {
      final pid = review['placeId'] as int;
      reviewCounts[pid] = (reviewCounts[pid] ?? 0) + 1;
    }

    final sorted = _allPlaces.toList()
      ..sort(
        (a, b) => (reviewCounts[b.id] ?? 0).compareTo(reviewCounts[a.id] ?? 0),
      );

    return sorted.take(5).toList();
  }

  List<Place> _getTopRated() {
    final ratingMap = <int, List<double>>{};

    for (var review in _allReviews) {
      final pid = review['placeId'] as int;
      final rating = (review['rating'] as num).toDouble();
      ratingMap.putIfAbsent(pid, () => []).add(rating);
    }

    final avgMap = <int, double>{};

    ratingMap.forEach((pid, ratings) {
      avgMap[pid] = ratings.reduce((a, b) => a + b) / ratings.length;
    });

    final sorted = _allPlaces.where((p) => avgMap.containsKey(p.id)).toList()
      ..sort((a, b) => (avgMap[b.id] ?? 0).compareTo(avgMap[a.id] ?? 0));

    return sorted.take(5).toList();
  }

  double _getAvgRating(int placeId) {
    final ratings = _allReviews
        .where((r) => r['placeId'] == placeId)
        .map((r) => (r['rating'] as num).toDouble())
        .toList();

    if (ratings.isEmpty) return 0;

    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  int _getReviewCount(int placeId) {
    return _allReviews.where((r) => r['placeId'] == placeId).length;
  }

  Place? _findPlaceById(int id) {
    try {
      return _allPlaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Place? _getPlaceByCategory(int categoryId) {
    final places = _allPlaces.where((p) => p.categoryId == categoryId).toList();

    if (places.isEmpty) return null;

    return places[Random().nextInt(places.length)];
  }

  Future<void> _getNearbyPlaces() async {
    setState(() {
      _isLoadingNearby = true;
      _locationStatus = 'Konum alınıyor...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Konum izni reddedildi.';
            _isLoadingNearby = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus =
              'Konum izni kalıcı olarak reddedildi. Ayarlardan açın.';
          _isLoadingNearby = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final nearby = await _apiService.getNearbyPlaces(
        position.latitude,
        position.longitude,
        radiusKm: 5,
      );

      setState(() {
        _nearbyPlaces = nearby;
        _locationStatus = nearby.isEmpty ? 'Yakınınızda mekan bulunamadı.' : '';
        _isLoadingNearby = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Konum alınamadı.';
        _isLoadingNearby = false;
      });
    }
  }

  String _readRouteValue(
    Map<String, dynamic> route,
    String lower,
    String upper,
  ) {
    return '${route[lower] ?? route[upper] ?? ''}';
  }

  String _normalizeUserRouteText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  List<Map<String, dynamic>> _getFilteredUserRoutes() {
    final query = _normalizeUserRouteText(_userRouteFilterText.trim());

    if (query.isEmpty) {
      return _approvedUserRoutes;
    }

    return _approvedUserRoutes.where((route) {
      final title = _readRouteValue(route, 'title', 'Title');
      final description = _readRouteValue(route, 'description', 'Description');
      final places = _readRouteValue(route, 'places', 'Places');
      final duration = _readRouteValue(route, 'duration', 'Duration');
      final distance = _readRouteValue(route, 'distance', 'Distance');

      final fullText = _normalizeUserRouteText(
        '$title $description $places $duration $distance',
      );

      return fullText.contains(query);
    }).toList();
  }

  void _setUserRouteQuickFilter(String text) {
    setState(() {
      final isAll = text == 'Tümü';
      _userRouteFilterText = isAll ? '' : text;
      _userRouteSearchController.text = isAll ? '' : text;
    });
  }

  Widget _buildUserRouteSearchFilters() {
    final filters = [
      'Tümü',
      'Camii',
      'Lezzet',
      'Müze',
      'Köprü',
      'Park',
      'Kısa rota',
      '1 saat',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _userRouteSearchController,
          onChanged: (value) {
            setState(() {
              _userRouteFilterText = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Kullanıcı rotalarında ara...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.red[900],
            ),
            suffixIcon: _userRouteFilterText.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _userRouteFilterText = '';
                        _userRouteSearchController.clear();
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red[900]!),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected =
                  (filter == 'Tümü' && _userRouteFilterText.isEmpty) ||
                      _normalizeUserRouteText(_userRouteFilterText) ==
                          _normalizeUserRouteText(filter);

              return GestureDetector(
                onTap: () => _setUserRouteQuickFilter(filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red[900] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.red[900]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransportOption({
    required TransportMode mode,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedTransportMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTransportMode = mode;
            _suggestedRoutePlaces = [];
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.red[900]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSummaryCard() {
    final totalDistance = _calculateTotalRouteDistance();
    final duration = _calculateEstimatedDurationMinutes(totalDistance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[900]!.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, color: Colors.red[900], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_getTransportModeName()} rota • ${totalDistance.toStringAsFixed(1)} km • Yaklaşık $duration dk',
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayPlace = _todayRecommendation ?? _randomPlace;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red[900]))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.red[900],
                  title: const Text(
                    'Keşfet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('✨ Bugün Sana Özel Öneri'),
                      if (todayPlace != null) _buildTodayRecommendationCard(),
                      _buildSectionTitle('📍 Yakınımdaki Mekanlar'),
                      _buildNearbySection(),
                      _buildSectionTitle('🧭 Sana Özel Rota Önerisi'),
                      _buildRouteSuggestionSection(),
                      _buildSectionTitle('💬 En Çok Yorumlanan'),
                      _buildHorizontalPlaceList(
                        _getMostReviewed(),
                        showReviewCount: true,
                      ),
                      _buildSectionTitle('⭐ En Yüksek Puanlılar'),
                      _buildHorizontalPlaceList(
                        _getTopRated(),
                        showRating: true,
                      ),
                      _buildSectionTitle('❤️ En Çok Favorilenen'),
                      _buildTopFavoritePlaces(),
                      _buildSectionTitle('🗂️ Kategoriye Göre Keşfet'),
                      _buildCategorySection(),
                      _buildSectionTitle('💡 Biliyor muydun?'),
                      _buildFactCards(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRouteSuggestionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[900]!.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: Colors.red[900],
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Konumuna, kategoriye ve ulaşım tercihine göre rota oluştur.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRouteCategoryId,
              decoration: InputDecoration(
                labelText: 'Kategori seç',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: 0,
                  child: Text('Tüm Kategoriler'),
                ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('Kullanıcı Önerileri'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedRouteCategoryId = value;
                  _suggestedRoutePlaces = [];

                  if (value != -1) {
                    _userRouteFilterText = '';
                    _userRouteSearchController.clear();
                  }
                });
              },
            ),
            if (_selectedRouteCategoryId != -1) ...[
              const SizedBox(height: 14),
              const Text(
                'Ulaşım tercihi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTransportOption(
                    mode: TransportMode.walking,
                    icon: Icons.directions_walk_rounded,
                    label: 'Yaya',
                  ),
                  const SizedBox(width: 8),
                  _buildTransportOption(
                    mode: TransportMode.car,
                    icon: Icons.directions_car_rounded,
                    label: 'Araç',
                  ),
                  const SizedBox(width: 8),
                  _buildTransportOption(
                    mode: TransportMode.publicTransport,
                    icon: Icons.directions_bus_rounded,
                    label: 'Toplu',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getTransportInfoText(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingRoute
                        ? null
                        : _generateSuggestedRoute,
                    icon: _isGeneratingRoute
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _isGeneratingRoute ? 'Oluşturuluyor' : 'Rota Oluştur',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      disabledBackgroundColor: Colors.red[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openRouteMap,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Haritada Göster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[850],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedRouteCategoryId == -1) ...[
              const SizedBox(height: 16),
              const Text(
                'Kullanıcı rotalarını filtrele:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildUserRouteSearchFilters(),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final filteredUserRoutes = _getFilteredUserRoutes();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userRouteFilterText.trim().isEmpty
                            ? 'Kullanıcıların onaylanan rotaları:'
                            : 'Filtrelenen kullanıcı rotaları:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_approvedUserRoutes.isEmpty)
                        Text(
                          'Henüz onaylanmış kullanıcı rotası yok.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        )
                      else if (filteredUserRoutes.isEmpty)
                        Text(
                          'Bu aramaya uygun kullanıcı rotası bulunamadı.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        )
                      else
                        Column(
                          children: filteredUserRoutes.map((route) {
                            final title =
                                _readRouteValue(route, 'title', 'Title');
                            final description = _readRouteValue(
                              route,
                              'description',
                              'Description',
                            );
                            final places =
                                _readRouteValue(route, 'places', 'Places');
                            final duration =
                                _readRouteValue(route, 'duration', 'Duration');
                            final distance =
                                _readRouteValue(route, 'distance', 'Distance');

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      Colors.red[900]!.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.place_rounded,
                                        size: 15,
                                        color: Colors.red[900],
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          places,
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_rounded,
                                        size: 15,
                                        color: Colors.red[900],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        duration,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.directions_walk_rounded,
                                        size: 15,
                                        color: Colors.red[900],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        distance,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ],
            if (_suggestedRoutePlaces.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Önerilen rota:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildRouteSummaryCard(),
              const SizedBox(height: 8),
              Column(
                children: _suggestedRoutePlaces.asMap().entries.map((entry) {
                  final index = entry.key;
                  final place = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.red[900],
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _getCategoryName(place.categoryId),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayRecommendationCard() {
    final place = _todayRecommendation ?? _randomPlace!;
    final imageUrl = _getFullImageUrl(place.imageUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
        ),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Colors.grey[300], height: 220),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
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
                    _getCategoryName(place.categoryId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Favorilerine göre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _newRandomPlace,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_nearbyPlaces.isEmpty && !_isLoadingNearby)
            GestureDetector(
              onTap: _getNearbyPlaces,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[900]!, Colors.red[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yakınımdaki Mekanlar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locationStatus.isNotEmpty
                                ? _locationStatus
                                : '5 km çevrendeki mekanları keşfet',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoadingNearby)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.red[900],
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _locationStatus,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = _nearbyPlaces[index];
                  final imageUrl = _getFullImageUrl(place.imageUrl);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailPage(place: place),
                      ),
                    ),
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              width: 150,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.grey[300],
                                width: 150,
                                height: 160,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              place.name,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Yakın',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPlaceList(
    List<Place> places, {
    bool showRating = false,
    bool showReviewCount = false,
  }) {
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Henüz yeterli veri yok.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          final avg = _getAvgRating(place.id);
          final count = _getReviewCount(place.id);
          final imageUrl = _getFullImageUrl(place.imageUrl);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
            ),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Container(height: 120, color: Colors.grey[200]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (showRating && avg > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                avg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' ($count yorum)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        if (showReviewCount)
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.red[900],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$count yorum',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
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
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final place = _getPlaceByCategory(cat.id);
          final color = _categoryColors[cat.id] ?? Colors.red[900]!;
          final icon = _categoryIcons[cat.id] ?? Icons.place_rounded;

          return GestureDetector(
            onTap: place == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailPage(place: place),
                    ),
                  ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (place != null)
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopFavoritePlaces() {
    if (_topFavoritePlaces.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _topFavoritePlaces.length,
        itemBuilder: (context, index) {
          final item = _topFavoritePlaces[index];

          final place = _findPlaceById(item['id'] ?? item['Id']);

          if (place == null) {
            return const SizedBox();
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceDetailPage(place: place),
                ),
              );
            },
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      _getFullImageUrl(place.imageUrl),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red[900],
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item['favoriteCount']} favori',
                              style: const TextStyle(fontSize: 12),
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
        },
      ),
    );
  }

  Widget _buildFactCards() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _factCards.length,
        itemBuilder: (context, index) {
          final card = _factCards[index];
          final color = card['color'] as Color;

          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      card['icon'] as IconData,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    card['fact'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.5,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
