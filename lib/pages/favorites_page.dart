import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/api_service.dart';
import 'place_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _apiService = ApiService();

  List<Place> _allFavorites = [];
  List<Place> _filteredFavorites = [];

  bool _isLoading = true;
  String _selectedSort = 'recent';

  final TextEditingController _searchController = TextEditingController();

  final Map<int, String> _categoryNames = {
    1: 'Tarihi Eser',
    2: 'Müze',
    3: 'Yöresel Lezzet',
    4: 'Doğa ve Park',
    5: 'Alışveriş',
    6: 'Hamam',
    7: 'Etkinlik ve Festival',
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final favorites = await _apiService.getFavorites();

    if (!mounted) return;

    setState(() {
      _allFavorites = favorites;
      _isLoading = false;
    });

    _applyFilterAndSort();
  }

  void _runFilter(String query) {
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    final query = _searchController.text.trim().toLowerCase();

    List<Place> result = _allFavorites.where((place) {
      return place.name.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query);
    }).toList();

    if (_selectedSort == 'recent') {
      result = result.reversed.toList();
    } else if (_selectedSort == 'az') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedSort == 'za') {
      result.sort((a, b) => b.name.compareTo(a.name));
    }

    setState(() {
      _filteredFavorites = result;
    });
  }

  void _changeSort(String value) {
    setState(() {
      _selectedSort = value;
    });

    _applyFilterAndSort();
  }

  String _getCategoryName(int categoryId) {
    return _categoryNames[categoryId] ?? 'Diğer';
  }

  String _getFavoriteAnalysis() {
    if (_allFavorites.isEmpty) return '';

    final Map<int, int> categoryCounts = {};

    for (final place in _allFavorites) {
      categoryCounts[place.categoryId] =
          (categoryCounts[place.categoryId] ?? 0) + 1;
    }

    final mostFavoriteCategory = categoryCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    final categoryName = _getCategoryName(mostFavoriteCategory.key);
    final totalCategoryCount = categoryCounts.length;

    return 'En çok favorilediğin kategori: $categoryName • $totalCategoryCount farklı kategori';
  }

  Future<void> _removeFavorite(int placeId) async {
    final success = await _apiService.removeFavorite(placeId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _allFavorites.removeWhere((place) => place.id == placeId);
      });

      _applyFilterAndSort();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarıldı.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarılamadı.')),
      );
    }
  }

  Widget _buildAnalysisCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[900]!,
              Colors.red[700]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getFavoriteAnalysis(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _buildSortChip(
            value: 'recent',
            label: 'En Son Eklenen',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            value: 'az',
            label: 'A-Z',
            icon: Icons.arrow_downward_rounded,
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            value: 'za',
            label: 'Z-A',
            icon: Icons.arrow_upward_rounded,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${_filteredFavorites.length} mekan',
              style: TextStyle(
                color: Colors.red[900],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedSort == value;

    return GestureDetector(
      onTap: () => _changeSort(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[900] : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.red[900]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.favorite_border_rounded,
              size: 76,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'Aramana uygun favori bulunamadı.'
                  : 'Henüz favori mekan eklemediniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Farklı bir kelime ile tekrar arayabilirsin.'
                  : 'Beğendiğin mekanları kalp ikonuna basarak favorilerine ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Place place) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailPage(place: place),
          ),
        );
        await _loadFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: Image.network(
                place.imageUrl ?? '',
                height: 115,
                width: 115,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 115,
                    width: 115,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.grey[400],
                      size: 34,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: Colors.grey[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getCategoryName(place.categoryId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Detayları Gör →',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeFavorite(place.id),
              icon: Icon(
                Icons.favorite_rounded,
                color: Colors.red[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Favorilerim',
          style: TextStyle(
            color: Colors.red[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _runFilter,
                      decoration: InputDecoration(
                        hintText: 'Favorilerde ara...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.red[900],
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                if (_allFavorites.isNotEmpty) _buildAnalysisCard(),

                if (_allFavorites.isNotEmpty) _buildTopInfoRow(),

                Expanded(
                  child: _filteredFavorites.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: Colors.red[900],
                          onRefresh: _loadFavorites,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            itemCount: _filteredFavorites.length,
                            itemBuilder: (context, index) {
                              final place = _filteredFavorites[index];

                              return Dismissible(
                                key: ValueKey(place.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.red[900],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  await _removeFavorite(place.id);
                                  return false;
                                },
                                child: _buildFavoriteCard(place),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}