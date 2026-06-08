import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import 'location_picker_page.dart';

class SuggestRoutePage extends StatefulWidget {
  const SuggestRoutePage({super.key});

  @override
  State<SuggestRoutePage> createState() => _SuggestRoutePageState();
}

class _SuggestRoutePageState extends State<SuggestRoutePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  final List<Map<String, dynamic>> _stops = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _addStop() async {
    final LatLng? selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (selectedLocation == null || !mounted) return;

    final TextEditingController stopNameController = TextEditingController();

    final String? stopName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Durak Adı'),
          content: TextField(
            controller: stopNameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Örn: Selimiye Camii',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = stopNameController.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    if (stopName == null || stopName.trim().isEmpty) return;

    setState(() {
      _stops.add({
        "name": stopName.trim(),
        "latitude": selectedLocation.latitude,
        "longitude": selectedLocation.longitude,
        "order": _stops.length + 1,
      });
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);

      for (int i = 0; i < _stops.length; i++) {
        _stops[i]["order"] = i + 1;
      }
    });
  }

  Future<void> _submitRouteSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota oluşturmak için en az 2 durak eklemelisin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _apiService.createRouteSuggestion(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      stops: _stops,
      duration: _durationController.text.trim(),
      distance: _distanceController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota önerin admin onayına gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota önerisi gönderilemedi. Lütfen tekrar dene.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStopsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.red[900]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rota Durakları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_stops.length} durak',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Durakları haritadan sırayla seç. Rota bu sıraya göre oluşturulur.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (_stops.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Henüz durak eklenmedi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Column(
              children: List.generate(_stops.length, (index) {
                final stop = _stops[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.red[900],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stop["name"] ?? "-",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeStop(index),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.red[900],
                      ),
                    ],
                  ),
                );
              }),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Haritadan Durak Ekle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[900],
                side: BorderSide(color: Colors.red[900]!),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Rota Öner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.alt_route_rounded, size: 70, color: Colors.red[900]),
              const SizedBox(height: 10),
              Text(
                'Yeni bir gezi rotası öner',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Önerin admin tarafından incelendikten sonra yayına alınabilir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _titleController,
                label: 'Rota Adı',
                icon: Icons.edit_location_alt_rounded,
                hint: 'Örn: Tarihi Edirne Turu',
                validatorMessage: 'Rota adı boş bırakılamaz',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _descriptionController,
                label: 'Rota Açıklaması',
                icon: Icons.description_rounded,
                hint: 'Bu rota hakkında kısa bilgi yaz',
                maxLines: 4,
                validatorMessage: 'Açıklama boş bırakılamaz',
              ),
              const SizedBox(height: 14),
              _buildStopsSection(),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _durationController,
                label: 'Tahmini Süre',
                icon: Icons.timer_rounded,
                hint: 'Örn: 2 saat',
                validatorMessage: 'Süre boş bırakılamaz',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _distanceController,
                label: 'Tahmini Mesafe',
                icon: Icons.directions_walk_rounded,
                hint: 'Örn: 3 km',
                validatorMessage: 'Mesafe boş bırakılamaz',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitRouteSuggestion,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isLoading ? 'Gönderiliyor...' : 'Rota Önerisini Gönder',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String validatorMessage,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.red[900]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}