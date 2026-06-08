import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  LatLng? _userLocation;

  bool _isLoadingLocation = true;

  static const LatLng _edirneCenter = LatLng(41.6771, 26.5557);

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _userLocation = currentLocation;
        _selectedLocation = currentLocation;
        _isLoadingLocation = false;
      });
    } catch (e) {
      _useFallbackLocation();
    }
  }

  void _useFallbackLocation() {
    if (!mounted) return;

    setState(() {
      _userLocation = null;
      _selectedLocation = _edirneCenter;
      _isLoadingLocation = false;
    });
  }

  void _goToUserLocation() {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mevcut konum alınamadı.'),
        ),
      );
      return;
    }

    _mapController.move(_userLocation!, 17);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation || _selectedLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Konum Seç'),
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 17,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.edirne_gezi',
              ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Marker(
                    point: _selectedLocation!,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red[900],
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Haritada mekanın olduğu yere dokunarak konum seç.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 92,
            child: FloatingActionButton(
              heroTag: 'currentLocationButton',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              onPressed: _goToUserLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, _selectedLocation);
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Bu Konumu Seç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}