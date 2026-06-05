import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutePlace {
  final int id;
  final String name;
  final double latitude;
  final double longitude;

  RoutePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class RouteMapPage extends StatefulWidget {
  final List<RoutePlace> places;

  const RouteMapPage({
    super.key,
    required this.places,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  int _currentStepIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  double? _distanceKm;
  double? _durationMinutes;

  @override
  void initState() {
    super.initState();
    _prepareFirstRouteStep();
  }

  Future<void> _prepareFirstRouteStep() async {
    if (widget.places.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Rota oluşturmak için en az 1 mekan gerekli.';
      });
      return;
    }

    try {
      final location = await _getUserLocation();

      setState(() {
        _userLocation = location;
        _currentStepIndex = 0;
      });

      await _loadCurrentStepRoute();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Konum alınamadı. Lütfen konum iznini kontrol edin.';
      });
    }
  }

  Future<LatLng> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Konum servisi kapalı.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni reddedildi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı olarak reddedildi.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  LatLng _placeToLatLng(RoutePlace place) {
    return LatLng(place.latitude, place.longitude);
  }

  LatLng get _stepStartPoint {
    if (_currentStepIndex == 0) {
      return _userLocation!;
    }

    return _placeToLatLng(widget.places[_currentStepIndex - 1]);
  }

  LatLng get _stepEndPoint {
    return _placeToLatLng(widget.places[_currentStepIndex]);
  }

  String get _stepStartName {
    if (_currentStepIndex == 0) {
      return 'Konumunuz';
    }

    return widget.places[_currentStepIndex - 1].name;
  }

  String get _stepEndName {
    return widget.places[_currentStepIndex].name;
  }

  bool get _isLastStep {
    return _currentStepIndex >= widget.places.length - 1;
  }

  Future<void> _loadCurrentStepRoute() async {
    if (_userLocation == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;
    });

    try {
      final start = _stepStartPoint;
      final end = _stepEndPoint;

      final coordinates =
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/$coordinates'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Rota servisine ulaşılamadı.');
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        throw Exception('Rota bulunamadı.');
      }

      final route = data['routes'][0];
      final List coordinatesList = route['geometry']['coordinates'];

      final points = coordinatesList.map<LatLng>((coordinate) {
        final double lng = coordinate[0].toDouble();
        final double lat = coordinate[1].toDouble();
        return LatLng(lat, lng);
      }).toList();

      setState(() {
        _routePoints = points;
        _distanceKm = (route['distance'] as num).toDouble() / 1000;
        _durationMinutes = (route['duration'] as num).toDouble() / 60;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitCurrentStepToMap();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bu adım için rota oluşturulamadı.';
      });
    }
  }

  void _goToNextStep() {
    if (_isLastStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota tamamlandı.'),
        ),
      );
      return;
    }

    setState(() {
      _currentStepIndex++;
    });

    _loadCurrentStepRoute();
  }

  void _fitCurrentStepToMap() {
    final points = <LatLng>[];

    if (_routePoints.isNotEmpty) {
      points.addAll(_routePoints);
    } else {
      if (_userLocation != null) points.add(_userLocation!);
      points.addAll(widget.places.map(_placeToLatLng));
    }

    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  List<Marker> get _markers {
    final markers = <Marker>[];

    if (_userLocation != null) {
      markers.add(
        Marker(
          width: 120,
          height: 80,
          point: _userLocation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Text(
                  'Konumunuz',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      final isCurrentTarget = i == _currentStepIndex;
      final isVisited = i < _currentStepIndex;

      Color markerColor;
      IconData markerIcon;

      if (isCurrentTarget) {
        markerColor = Colors.red.shade900;
        markerIcon = Icons.flag_rounded;
      } else if (isVisited) {
        markerColor = Colors.green.shade700;
        markerIcon = Icons.check_rounded;
      } else {
        markerColor = Colors.grey.shade700;
        markerIcon = Icons.place_rounded;
      }

      markers.add(
        Marker(
          width: 130,
          height: 90,
          point: LatLng(place.latitude, place.longitude),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: markerColor,
                child: isVisited
                    ? Icon(markerIcon, color: Colors.white, size: 18)
                    : Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isCurrentTarget ? FontWeight.bold : FontWeight.w600,
                    color: isCurrentTarget ? Colors.red[900] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  LatLng get _initialCenter {
    if (_userLocation != null) return _userLocation!;
    final firstPlace = widget.places.first;
    return LatLng(firstPlace.latitude, firstPlace.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final hasRouteInfo = _distanceKm != null && _durationMinutes != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        title: const Text(
          'Adım Adım Rota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _fitCurrentStepToMap,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.edirne_gezi_app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.red.shade800,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentStepIndex + 1}. Durak',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_stepStartName → $_stepEndName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    if (hasRouteInfo) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            color: Colors.red[900],
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.directions_walk_rounded,
                            color: Colors.red[900],
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_durationMinutes!.round()} dk',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _goToNextStep,
                icon: Icon(
                  _isLastStep
                      ? Icons.check_circle_rounded
                      : Icons.navigate_next_rounded,
                ),
                label: Text(
                  _isLastStep
                      ? 'Rota Tamamlandı'
                      : 'Sonraki Mekanı Göster',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isLastStep ? Colors.green[700] : Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.75),
              child: Center(
                child: CircularProgressIndicator(color: Colors.red[900]),
              ),
            ),

          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.w600,
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