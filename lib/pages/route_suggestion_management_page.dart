import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RouteSuggestionManagementPage extends StatefulWidget {
  const RouteSuggestionManagementPage({super.key});

  @override
  State<RouteSuggestionManagementPage> createState() =>
      _RouteSuggestionManagementPageState();
}

class _RouteSuggestionManagementPageState
    extends State<RouteSuggestionManagementPage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _routeSuggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteSuggestions();
  }

  Future<void> _loadRouteSuggestions() async {
    setState(() => _isLoading = true);

    final suggestions = await _apiService.getRouteSuggestions();

    if (!mounted) return;

    setState(() {
      _routeSuggestions = suggestions
          .where((s) => (s['status'] ?? s['Status']) == 'Pending')
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _approveSuggestion(int index) async {
    final route = _routeSuggestions[index];
    final int id = route['id'] ?? route['Id'];
    final routeName = route['title'] ?? route['Title'] ?? 'Rota';

    final success = await _apiService.approveRouteSuggestion(id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _routeSuggestions.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$routeName rotası onaylandı!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota onaylanamadı.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectSuggestion(int index) async {
    final route = _routeSuggestions[index];
    final int id = route['id'] ?? route['Id'];
    final routeName = route['title'] ?? route['Title'] ?? 'Rota';

    final success = await _apiService.rejectRouteSuggestion(id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _routeSuggestions.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$routeName rotası reddedildi!'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota reddedilemedi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editSuggestion(int index) {
    final route = _routeSuggestions[index];

    final int id = route['id'] ?? route['Id'];

    final titleController = TextEditingController(
      text: route['title'] ?? route['Title'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: route['description'] ?? route['Description'] ?? '',
    );
    final placesController = TextEditingController(
      text: route['places'] ?? route['Places'] ?? '',
    );
    final durationController = TextEditingController(
      text: route['duration'] ?? route['Duration'] ?? '',
    );
    final distanceController = TextEditingController(
      text: route['distance'] ?? route['Distance'] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Rotayı Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildEditField(titleController, 'Rota Adı'),
                const SizedBox(height: 10),
                _buildEditField(descriptionController, 'Açıklama', maxLines: 3),
                const SizedBox(height: 10),
                _buildEditField(placesController, 'Duraklar', maxLines: 3),
                const SizedBox(height: 10),
                _buildEditField(durationController, 'Süre'),
                const SizedBox(height: 10),
                _buildEditField(distanceController, 'Mesafe'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await _apiService.editRouteSuggestion(
                  id: id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  places: placesController.text.trim(),
                  duration: durationController.text.trim(),
                  distance: distanceController.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (success) {
                  await _loadRouteSuggestions();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rota önerisi güncellendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rota önerisi güncellenemedi.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _read(Map<String, dynamic> map, String lower, String upper) {
    return '${map[lower] ?? map[upper] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Rota Önerileri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routeSuggestions.isEmpty
              ? const Center(
                  child: Text(
                    'Bekleyen rota önerisi yok.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRouteSuggestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _routeSuggestions.length,
                    itemBuilder: (context, index) {
                      final route = _routeSuggestions[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.red[900],
                                  child: const Icon(
                                    Icons.alt_route_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _read(route, 'title', 'Title'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _read(route, 'description', 'Description'),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildInfoRow(
                              Icons.place_rounded,
                              _read(route, 'places', 'Places'),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.timer_rounded,
                              'Süre: ${_read(route, 'duration', 'Duration')}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.directions_walk_rounded,
                              'Mesafe: ${_read(route, 'distance', 'Distance')}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.person_rounded,
                              'Kullanıcı ID: ${route['userId'] ?? route['UserId'] ?? '-'}',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _editSuggestion(index),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Düzenle',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _approveSuggestion(index),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Onayla',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[900],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _rejectSuggestion(index),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Reddet',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.red[900]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}