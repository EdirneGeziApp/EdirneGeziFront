import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import 'location_picker_page.dart';

class SuggestPlacePage extends StatefulWidget {
  const SuggestPlacePage({super.key});

  @override
  State<SuggestPlacePage> createState() => _SuggestPlacePageState();
}

class _SuggestPlacePageState extends State<SuggestPlacePage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  LatLng? _selectedLocation;
  File? _selectedImage;

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

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitSuggestion() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty ||
        desc.isEmpty ||
        _selectedCategoryId == null ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen mekan adı, açıklama, kategori ve konum seçimini tamamlayın.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _apiService.createPlaceSuggestion(
      name: name,
      description: desc,
      categoryId: _selectedCategoryId!,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mekan öneriniz admin onayına gönderildi.'),
        ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _locationSelector() {
    final hasLocation = _selectedLocation != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Icon(
                hasLocation ? Icons.check_circle_rounded : Icons.map_rounded,
                color: hasLocation ? Colors.green : Colors.red[900],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? 'Konum seçildi'
                      : 'Mekan konumunu haritadan seç',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.location_on_rounded),
              label: Text(
                hasLocation ? 'Konumu Değiştir' : 'Haritadan Konum Seç',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[900],
                side: BorderSide(color: Colors.red[900]!),
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

  Widget _imageSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Icon(Icons.image_rounded, color: Colors.red[900]),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Mekan fotoğrafı',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removeSelectedImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Fotoğraf eklemek isteğe bağlıdır.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(
                _selectedImage == null
                    ? 'Galeriden Fotoğraf Seç'
                    : 'Fotoğrafı Değiştir',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[900],
                side: BorderSide(color: Colors.red[900]!),
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
            _locationSelector(),
            _imageSelector(),
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