import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class SuggestPlacePage extends StatefulWidget {
  const SuggestPlacePage({super.key});

  @override
  State<SuggestPlacePage> createState() => _SuggestPlacePageState();
}

class _SuggestPlacePageState extends State<SuggestPlacePage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _apiService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _selectedCategoryId = categories.first.id;
      }
    });
  }

  Future<void> _submitSuggestion() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final lat = double.tryParse(_latController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lngController.text.trim().replaceAll(',', '.'));

    if (name.isEmpty || desc.isEmpty || lat == null || lng == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doğru doldurun.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _apiService.createPlaceSuggestion(
      name: name,
      description: desc,
      categoryId: _selectedCategoryId!,
      latitude: lat,
      longitude: lng,
      imageUrl: _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mekan öneriniz admin onayına gönderildi.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mekan önerisi gönderilemedi.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.red[900]),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mekan Öner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(
              controller: _nameController,
              hint: 'Mekan adı',
              icon: Icons.place_rounded,
            ),
            _input(
              controller: _descController,
              hint: 'Mekan açıklaması',
              icon: Icons.description_rounded,
              maxLines: 3,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  items: _categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
              ),
            ),
            _input(
              controller: _latController,
              hint: 'Enlem (Latitude) örn: 41.6780',
              icon: Icons.my_location_rounded,
              keyboardType: TextInputType.number,
            ),
            _input(
              controller: _lngController,
              hint: 'Boylam (Longitude) örn: 26.5594',
              icon: Icons.location_on_rounded,
              keyboardType: TextInputType.number,
            ),
            _input(
              controller: _imageController,
              hint: 'Görsel URL (isteğe bağlı)',
              icon: Icons.image_rounded,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitSuggestion,
                icon: const Icon(Icons.send_rounded),
                label: Text(_isLoading ? 'Gönderiliyor...' : 'Öneriyi Gönder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}