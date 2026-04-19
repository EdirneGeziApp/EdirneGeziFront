import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/place.dart';
import 'login_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: const Text('Admin Paneli', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.setBool('isAdmin', false);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Hoş geldin, Admin! 👋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[900]),
            ),
            const SizedBox(height: 6),
            Text('Ne yapmak istersin?', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Kullanıcı\nYönetimi',
                    subtitle: 'Kullanıcıları listele ve yönet',
                    color: const Color(0xFF1A5276),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage())),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.chat_bubble_rounded,
                    title: 'Yorum\nYönetimi',
                    subtitle: 'Yorumları incele ve sil',
                    color: const Color(0xFF784212),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewsPage())),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'Mekan\nYönetimi',
                    subtitle: 'Mekanları düzenle ve sil',
                    color: const Color(0xFF145A32),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPlacesPage())),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: 'İstatistikler',
                    subtitle: 'Uygulama verilerini gör',
                    color: const Color(0xFF6C3483),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStatsPage())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ KULLANICI YÖNETİMİ ============
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _apiService.getUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _deleteUser(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('$userName adlı kullanıcıyı silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red[900])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteUser(userId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı silindi!')),
        );
        _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Kullanıcı Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Kayıtlı kullanıcı yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.red[900],
                            radius: 22,
                            child: Text(
                              (user['userName'] as String? ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_rounded, color: Colors.red[900]),
                            onPressed: () => _deleteUser(user['id'] as int, user['userName'] as String),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ============ YORUM YÖNETİMİ ============
class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final reviews = await _apiService.getAllReviews();
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  Future<void> _deleteReview(int placeId, int reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red[900])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteReview(placeId, reviewId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum silindi!')),
        );
        _loadReviews();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Yorum Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('Henüz yorum yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final rating = (review['rating'] as num?)?.toInt() ?? 0;
                    final date = review['createdAt'] != null ? DateTime.tryParse(review['createdAt']) : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF784212),
                                radius: 18,
                                child: Text(
                                  (review['userName'] as String? ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(review['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (date != null)
                                      Text('${date.day}.${date.month}.${date.year}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber, size: 14,
                                )),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_rounded, color: Colors.red[900], size: 20),
                                onPressed: () => _deleteReview(review['placeId'] as int, review['id'] as int),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['comment'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ============ MEKAN YÖNETİMİ ============
class AdminPlacesPage extends StatefulWidget {
  const AdminPlacesPage({super.key});

  @override
  State<AdminPlacesPage> createState() => _AdminPlacesPageState();
}

class _AdminPlacesPageState extends State<AdminPlacesPage> {
  final ApiService _apiService = ApiService();
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final places = await _apiService.getPlaces();
    if (!mounted) return;
    setState(() {
      _places = places;
      _isLoading = false;
    });
  }

  Future<void> _deletePlace(int placeId, String placeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mekanı Sil'),
        content: Text('"$placeName" mekanını silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red[900])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deletePlace(placeId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mekan silindi!')),
        );
        _loadPlaces();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Mekan Yönetimi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        place.imageUrl ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported_rounded),
                        ),
                      ),
                    ),
                    title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(place.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_rounded, color: Colors.red[900]),
                      onPressed: () => _deletePlace(place.id, place.name),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============ İSTATİSTİKLER ============
class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _apiService.getStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('İstatistikler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('📍 Toplam Mekan', '${_stats['totalPlaces']}', const Color(0xFF145A32))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('👤 Toplam Kullanıcı', '${_stats['totalUsers']}', const Color(0xFF1A5276))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('💬 Toplam Yorum', '${_stats['totalReviews']}', const Color(0xFF784212))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('🏆 En Popüler', '${_stats['mostReviewedPlace']}', const Color(0xFF6C3483))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('En Çok Yorumlanan Mekan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_stats['mostReviewedPlace']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text('${_stats['mostReviewedCount']} yorum', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                ],
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}