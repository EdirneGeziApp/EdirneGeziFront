import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../services/api_service.dart';

class PlaceDetailPage extends StatefulWidget {
  final Place place;
  const PlaceDetailPage({super.key, required this.place});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isSending = false;
  double _selectedRating = 5.0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadReviews();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'Gezgin');
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _apiService.getReviews(widget.place.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir yorum yazın.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await _apiService.postReview(
        widget.place.id,
        _userName,
        _commentController.text.trim(),
        _selectedRating.toInt(),
      );

      _commentController.clear();
      setState(() => _selectedRating = 5.0);
      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorumunuz eklendi! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum gönderilemedi, tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _launchMap() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${widget.place.latitude},${widget.place.longitude}";
    final Uri url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  double _calculateAverageRating() {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble());
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = _calculateAverageRating();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Üstteki resim + AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.red[900],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.place.imageUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 80),
                    ),
                  ),
                  // Gradient karartma
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  // Mekan adı resmin üzerinde
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      widget.place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puan + Harita butonu
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // Ortalama puan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _reviews.isEmpty ? 'Henüz yok' : avgRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (_reviews.isNotEmpty)
                              Text(
                                ' (${_reviews.length} yorum)',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Haritada Gör butonu
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _launchMap,
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Haritada Gör', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Mekan Açıklaması
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mekan Hakkında',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.place.description,
                        style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Yorum Yaz Bölümü
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yorum Yap',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yorum yapan: $_userName',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 14),

                      // Yıldız Seçimi
                      Row(
                        children: [
                          const Text('Puanın: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          ...List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _selectedRating = index + 1.0),
                              child: Icon(
                                index < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedRating.toInt()}/5',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Yorum Kutusu
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Bu mekan hakkında düşüncelerinizi paylaşın...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.red[900]!, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gönder Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSending ? null : _submitReview,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSending ? 'Gönderiliyor...' : 'Yorumu Gönder',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Yorumlar Listesi
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Yorumlar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (_reviews.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_reviews.length} yorum',
                                style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _isLoadingReviews
                          ? const Center(child: CircularProgressIndicator())
                          : _reviews.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Henüz yorum yapılmamış.\nİlk yorumu sen yap!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _reviews.length,
                                  separatorBuilder: (_, __) => const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    final review = _reviews[index];
                                    final rating = (review['rating'] as num).toInt();
                                    final userName = review['userName'] ?? 'Anonim';
                                    final comment = review['comment'] ?? '';
                                    final date = review['createdAt'] != null
                                        ? DateTime.tryParse(review['createdAt'])
                                        : null;

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.red[900],
                                          child: Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                  const Spacer(),
                                                  // Yıldızlar
                                                  ...List.generate(5, (i) => Icon(
                                                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  )),
                                                ],
                                              ),
                                              if (date != null)
                                                Text(
                                                  '${date.day}.${date.month}.${date.year}',
                                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                                ),
                                              const SizedBox(height: 6),
                                              Text(
                                                comment,
                                                style: const TextStyle(fontSize: 14, height: 1.4),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}