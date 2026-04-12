import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/place.dart';
import '../models/category.dart';
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
  int _selectedCategoryId = 0;
  bool _isLoading = true;

  // Arama için gerekli değişkenler
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
      debugPrint("Veri yükleme hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  // Arama ve Kategori Filtrelemesini Birleştiren Fonksiyon
  void _runFilter(String query) {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final nameMatch = place.name.toLowerCase().contains(
              query.toLowerCase(),
            );
        final categoryMatch =
            (_selectedCategoryId == 0 ||
                place.categoryId == _selectedCategoryId);
        return nameMatch && categoryMatch;
      }).toList();
    });
  }

  void _filterByCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _runFilter(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Mekan ara...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => _runFilter(value),
              )
            : const Text(
                'Edirne Gezi Rehberi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _runFilter("");
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kategori Listesi
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    // "Tümü" + Kategoriler
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildCategoryChip("Tümü", 0);
                      
                      final cat = _categories[index - 1];
                      // DÜZELTME: cat.name'in dolu olduğundan emin oluyoruz
                      return _buildCategoryChip(cat.name.toString(), cat.id);
                    },
                  ),
                ),
                // Mekan Listesi
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: _filteredPlaces.isEmpty
                        ? const Center(child: Text("Sonuç bulunamadı."))
                        : ListView.builder(
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (context, index) {
                              return _buildPlaceCard(_filteredPlaces[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChip(String label, int id) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => _filterByCategory(id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[900] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailPage(place: place),
            ),
          );
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                // IP ADRESİ KONTROLÜ: api_constants içindeki 10.0.2.2 ayarı burada otomatik çalışır
                place.imageUrl ?? 'https://via.placeholder.com/400x200',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      Text("Resim yüklenemedi", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(
                place.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                place.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}