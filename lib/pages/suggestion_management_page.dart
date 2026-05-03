import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuggestionManagementPage extends StatefulWidget {
  const SuggestionManagementPage({super.key});

  @override
  State<SuggestionManagementPage> createState() => _SuggestionManagementPageState();
}

class _SuggestionManagementPageState extends State<SuggestionManagementPage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final data = await _apiService.getPlaceSuggestions();

    if (!mounted) return;

    setState(() {
      _suggestions = data;
      _isLoading = false;
    });
  }

  Future<void> _approve(int id) async {
    final success = await _apiService.approvePlaceSuggestion(id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öneri onaylandı ve mekanlara eklendi.')),
      );
      await _loadSuggestions();
    }
  }

  Future<void> _reject(int id) async {
    final success = await _apiService.rejectPlaceSuggestion(id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öneri reddedildi.')),
      );
      await _loadSuggestions();
    }
  }

  Color _statusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  String _statusText(String status) {
    if (status == 'Approved') return 'Onaylandı';
    if (status == 'Rejected') return 'Reddedildi';
    return 'Bekliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mekan Önerileri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
              ? Center(
                  child: Text(
                    'Henüz mekan önerisi yok.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.red[900],
                  onRefresh: _loadSuggestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      final id = item['id'];
                      final status = item['status'] ?? 'Pending';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _statusText(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['description'] ?? '',
                              style: TextStyle(color: Colors.grey[700], height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Konum: ${item['latitude']} , ${item['longitude']}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            if (status == 'Pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approve(id),
                                      icon: const Icon(Icons.check_rounded),
                                      label: const Text('Onayla'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _reject(id),
                                      icon: const Icon(Icons.close_rounded),
                                      label: const Text('Reddet'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[900],
                                        foregroundColor: Colors.white,
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
}