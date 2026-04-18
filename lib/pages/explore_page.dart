import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'place_detail_page.dart';

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

  Place? _randomPlace;
  bool _isLoading = true;
  bool _isLoadingNearby = false;
  String _locationStatus = '';

  // Edirne hakkında bilgi kartları
  final List<Map<String, dynamic>> _factCards = [
    {
      'icon': Icons.history_edu_rounded,
      'color': Color(0xFF6C3483),
      'title': 'Tarihin Başkenti',
      'fact': 'Edirne, Osmanlı İmparatorluğu\'nun 1363-1458 yılları arasında başkentliğini yapmıştır.',
    },
    {
      'icon': Icons.architecture_rounded,
      'color': Color(0xFF1A5276),
      'title': 'Mimar Sinan\'ın Şaheseri',
      'fact': 'Selimiye Camii, Mimar Sinan\'ın kendi ifadesiyle "ustalık eserim" dediği yapıdır ve UNESCO Dünya Mirası listesindedir.',
    },
    {
      'icon': Icons.sports_rounded,
      'color': Color(0xFF145A32),
      'title': 'Dünyanın En Eski Sporu',
      'fact': 'Kırkpınar Yağlı Güreşleri, 1346\'dan beri kesintisiz düzenlenen dünyanın en eski spor organizasyonudur.',
    },
    {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF784212),
      'title': 'Tava Ciğerin Vatanı',
      'fact': 'Edirne tava ciğeri, ince dilimlenmiş kuzu ciğerinin yüksek ateşte pişirilmesiyle yapılan eşsiz bir lezzettir.',
    },
    {
      'icon': Icons.water_rounded,
      'color': Color(0xFF1F618D),
      'title': 'Üç Nehrin Şehri',
      'fact': 'Edirne, Meriç, Tunca ve Arda nehirlerinin kavşağında kurulmuş, suyla iç içe bir şehirdir.',
    },
    {
      'icon': Icons.synagogue_rounded,
      'color': Color(0xFF7D6608),
      'title': 'Hoşgörünün Şehri',
      'fact': 'Edirne\'deki Büyük Sinagog, restore edilerek Avrupa\'nın en büyük sinagoglarından biri haline gelmiştir.',
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getPlaces(),
        _apiService.getCategories(),
      ]);
      final places = results[0] as List<Place>;
      final categories = results[1] as List<Category>;

      // Tüm mekanların yorumlarını çek
      List<Map<String, dynamic>> allReviews = [];
      for (var place in places) {
        final reviews = await _apiService.getReviews(place.id);
        for (var review in reviews) {
          allReviews.add({...review, 'placeId': place.id});
        }
      }

      setState(() {
        _allPlaces = places;
        _categories = categories;
        _allReviews = allReviews;
        _randomPlace = places.isNotEmpty ? places[Random().nextInt(places.length)] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _newRandomPlace() {
    if (_allPlaces.isEmpty) return;
    setState(() {
      _randomPlace = _allPlaces[Random().nextInt(_allPlaces.length)];
    });
  }

  // En çok yorum alan mekanlar
  List<Place> _getMostReviewed() {
    final reviewCounts = <int, int>{};
    for (var review in _allReviews) {
      final pid = review['placeId'] as int;
      reviewCounts[pid] = (reviewCounts[pid] ?? 0) + 1;
    }
    final sorted = _allPlaces.toList()
      ..sort((a, b) => (reviewCounts[b.id] ?? 0).compareTo(reviewCounts[a.id] ?? 0));
    return sorted.take(5).toList();
  }

  // En yüksek puanlı mekanlar
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

  // Kategoriye göre bir mekan getir
  Place? _getPlaceByCategory(int categoryId) {
    final places = _allPlaces.where((p) => p.categoryId == categoryId).toList();
    if (places.isEmpty) return null;
    return places[Random().nextInt(places.length)];
  }

  // Yakındaki mekanları getir
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
          _locationStatus = 'Konum izni kalıcı olarak reddedildi. Ayarlardan açın.';
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
        radiusKm: 3,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red[900]))
          : CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.red[900],
                  title: const Text(
                    'Keşfet',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  centerTitle: true,
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. RASTGELE MEKAN
                      _buildSectionTitle('🎲 Bugün Buraya Git!'),
                      if (_randomPlace != null) _buildRandomPlaceCard(),

                      // 2. YAKIN MEKANLAR
                      _buildSectionTitle('📍 Yakınımdaki Mekanlar'),
                      _buildNearbySection(),

                      // 3. EN ÇOK YORUM ALAN
                      _buildSectionTitle('💬 En Çok Yorumlanan'),
                      _buildHorizontalPlaceList(_getMostReviewed(), showReviewCount: true),

                      // 4. EN YÜKSEK PUANLI
                      _buildSectionTitle('⭐ En Yüksek Puanlılar'),
                      _buildHorizontalPlaceList(_getTopRated(), showRating: true),

                      // 5. KATEGORİYE GÖRE ÖNERILER
                      _buildSectionTitle('🗂️ Kategoriye Göre Keşfet'),
                      _buildCategorySection(),

                      // 6. BİLGİ KARTLARI
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

  // Rastgele mekan kartı
  Widget _buildRandomPlaceCard() {
    final place = _randomPlace!;
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  place.imageUrl ?? '',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[300], height: 220),
                ),
              ),
              // Gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  ),
                ),
              ),
              // İçerik
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
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Yenile butonu
                    GestureDetector(
                      onTap: _newRandomPlace,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              // Kategori etiketi
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
                    _categories.firstWhere((c) => c.id == place.categoryId, orElse: () => Category(id: 0, name: 'Diğer')).name,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Yakın mekanlar bölümü
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
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Yakınımdaki Mekanlar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _locationStatus.isNotEmpty ? _locationStatus : '3 km çevrendeki mekanları keşfet',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            )
          else if (_isLoadingNearby)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red[900], strokeWidth: 2),
                  const SizedBox(width: 12),
                  Text(_locationStatus, style: TextStyle(color: Colors.grey[600])),
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
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place))),
                    child: Container(
                      width: 150,
                      margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              place.imageUrl ?? '',
                              width: 150,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.grey[300], width: 150, height: 160),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green[600], borderRadius: BorderRadius.circular(8)),
                              child: const Text('Yakın', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

  // Yatay mekan listesi
  Widget _buildHorizontalPlaceList(List<Place> places, {bool showRating = false, bool showReviewCount = false}) {
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Henüz yeterli veri yok.', style: TextStyle(color: Colors.grey[500])),
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
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place))),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      place.imageUrl ?? '',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 120, color: Colors.grey[200]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        if (showRating && avg > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                              const SizedBox(width: 3),
                              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(' ($count yorum)', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        if (showReviewCount)
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_rounded, color: Colors.red[900], size: 14),
                              const SizedBox(width: 4),
                              Text('$count yorum', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
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

  // Kategoriye göre öneri
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
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place))),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
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
                        Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        if (place != null)
                          Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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

  // Bilgi kartları
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
                colors: [color, color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(card['icon'] as IconData, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(card['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    card['fact'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
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