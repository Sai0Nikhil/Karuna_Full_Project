import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../utils/app_colors.dart';

class MapRoutingScreen extends StatefulWidget {
  final int caseId;
  final double caseLat;
  final double caseLon;
  final String animalTitle;

  const MapRoutingScreen({
    super.key,
    required this.caseId,
    required this.caseLat,
    required this.caseLon,
    required this.animalTitle,
  });

  @override
  State<MapRoutingScreen> createState() => _MapRoutingScreenState();
}

class _MapRoutingScreenState extends State<MapRoutingScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _caseLocation;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _navigationSteps = [];
  bool _loading = true;
  String? _errorMessage;

  // Simulation state
  bool _isSimulating = false;
  int _simulationIndex = 0;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _caseLocation = LatLng(widget.caseLat, widget.caseLon);
    _initializeNavigation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get Starting Coordinates (prefer real GPS, fallback to mock start nearby)
      LatLng startPoint;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
        Position position = await Geolocator.getCurrentPosition();
        startPoint = LatLng(position.latitude, position.longitude);
      } else {
        // Mock starting point 0.01 degrees (~1km) away from the case
        startPoint = LatLng(widget.caseLat + 0.008, widget.caseLon - 0.012);
      }

      setState(() {
        _currentLocation = startPoint;
      });

      // 2. Fetch OSRM Driving Route
      await _fetchRoute(startPoint, _caseLocation!);

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load navigation: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=true';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          
          // Parse polyline geometry
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          final List<LatLng> points = coordinates
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();

          // Parse navigation steps
          final List<Map<String, dynamic>> steps = [];
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final legSteps = route['legs'][0]['steps'] as List;
            for (var s in legSteps) {
              final instruction = s['maneuver']['instruction']?.toString() ?? 'Proceed';
              final distance = (s['distance'] as num).toDouble();
              final location = s['maneuver']['location'] as List;
              steps.add({
                'instruction': instruction,
                'distance': distance,
                'coord': LatLng(location[1].toDouble(), location[0].toDouble()),
              });
            }
          }

          setState(() {
            _routePoints = points;
            _navigationSteps = steps;
            _loading = false;
          });

          // Fit route within map bounds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapBounds();
          });
          return;
        }
      }
      throw Exception('Route not found from routing server');
    } catch (e) {
      // Fallback: draw straight line and generate simple mock instructions
      setState(() {
        _routePoints = [start, end];
        _navigationSteps = [
          {'instruction': 'Head east toward the animal case', 'distance': 500.0, 'coord': start},
          {'instruction': 'Continue straight on the street', 'distance': 400.0, 'coord': LatLng((start.latitude + end.latitude)/2, (start.longitude + end.longitude)/2)},
          {'instruction': 'Arrived at the reported rescue location', 'distance': 0.0, 'coord': end},
        ];
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
    }
  }

  void _fitMapBounds() {
    if (_routePoints.isEmpty) return;
    
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLon = _routePoints.first.longitude;
    double maxLon = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() {
        _isSimulating = false;
      });
    } else {
      if (_routePoints.isEmpty) return;
      setState(() {
        _isSimulating = true;
        _simulationIndex = 0;
        _currentLocation = _routePoints.first;
      });
      _mapController.move(_currentLocation!, 16.5);

      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_simulationIndex >= _routePoints.length - 1) {
          timer.cancel();
          setState(() {
            _isSimulating = false;
            _currentLocation = _routePoints.last;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🚑 Arrived at case location!'), backgroundColor: AppColors.teal),
          );
        } else {
          _simulationIndex += (_routePoints.length / 15).ceil().clamp(1, 15); // complete path in ~15 steps
          if (_simulationIndex >= _routePoints.length) {
            _simulationIndex = _routePoints.length - 1;
          }
          setState(() {
            _currentLocation = _routePoints[_simulationIndex];
          });
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigation to ${widget.animalTitle}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          if (!_loading && _errorMessage == null)
            IconButton(
              icon: Icon(Icons.gps_fixed, color: AppColors.teal),
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16.0);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('❌', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _initializeNavigation,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // The Map Widget
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation ?? _caseLocation ?? const LatLng(16.5062, 80.6480),
                        initialZoom: 15.0,
                        maxZoom: 18.0,
                        minZoom: 10.0,
                      ),
                      children: [
                        // Map Tiles (OpenStreetMap styled beautifully)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.karuna.app',
                        ),
                        // Route Overlay
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5.5,
                                color: Colors.blueAccent,
                                borderColor: Colors.blue[900],
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                        // Markers Overlay (Start + End)
                        MarkerLayer(
                          markers: [
                            // Responder Location Marker
                            if (_currentLocation != null)
                              Marker(
                                point: _currentLocation!,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                                      ),
                                      child: const Icon(Icons.navigation, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ),
                            // Animal Case Destination Marker
                            if (_caseLocation != null)
                              Marker(
                                point: _caseLocation!,
                                width: 60,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.critical,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'SOS',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Icon(Icons.location_on, color: AppColors.critical, size: 36),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Navigation Overlay Sheet
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 240,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag handle and top row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Turn-by-Turn Guide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                                      Text('${_navigationSteps.length} steps to destination', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _toggleSimulation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isSimulating ? Colors.red[400] : AppColors.teal,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow, size: 16, color: Colors.white),
                                    label: Text(
                                      _isSimulating ? 'Stop' : 'Simulate',
                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _navigationSteps.length,
                                itemBuilder: (ctx, i) {
                                  final step = _navigationSteps[i];
                                  final distance = step['distance'] as double;
                                  final active = _isSimulating &&
                                      _simulationIndex >= 0 &&
                                      i == _getClosestStepIndex();

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: active ? AppColors.tealLight.withOpacity(0.5) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: active ? AppColors.teal : AppColors.lightGray,
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            color: active ? Colors.white : AppColors.dark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        step['instruction'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                      subtitle: distance > 0
                                          ? Text(
                                              'For ${distance >= 1000 ? "${(distance / 1000).toStringAsFixed(1)} km" : "${distance.round()} meters"}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.gray),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  int _getClosestStepIndex() {
    if (_routePoints.isEmpty || _navigationSteps.isEmpty) return 0;
    
    // Find step that is closest to our current simulated coordinates
    int closestIndex = 0;
    double minDistance = double.maxFinite;

    for (int i = 0; i < _navigationSteps.length; i++) {
      LatLng stepCoord = _navigationSteps[i]['coord'];
      double dist = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        stepCoord.latitude,
        stepCoord.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    return closestIndex;
  }
}
