import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  final TextEditingController _placesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _placesController.dispose();
    super.dispose();
  }

  Future<void> _submitRouteSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _apiService.createRouteSuggestion(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      places: _placesController.text.trim(),
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

              _buildTextField(
                controller: _placesController,
                label: 'Rota Durakları',
                icon: Icons.place_rounded,
                hint: 'Örn: Selimiye Camii, Üç Şerefeli Camii, Meriç Köprüsü',
                maxLines: 3,
                validatorMessage: 'Rota durakları boş bırakılamaz',
              ),
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