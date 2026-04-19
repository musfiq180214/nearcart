import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/store_model.dart';
import '../../widgets/glassmorphic/glass_card.dart';
import '../store/add_store_screen.dart';
import '../cart/store_lists_screen.dart';
import 'package:http/http.dart' as http;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedStoreUuid;
  bool _showStorePanel = false;
  bool _isMapReady = false;

  static const _defaultLatLng = LatLng(23.8103, 90.4125);

  final List<String> _categories = [
    'All', 'Grocery', 'Pharmacy', 'Electronics', 'Bakery', 'Market',
  ];
  String _selectedCategory = 'All';

  // --- New Routing State ---
  List<LatLng> _routePoints = [];
  bool _isRouting = false;

  Future<void> _fetchRoadRoute(LatLng start, LatLng destination) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
          _isRouting = true;
          _showStorePanel = false;
        });

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_routePoints),
            padding: const EdgeInsets.all(70),
          ),
        );
      }
    } catch (e) {
      AppLogger.e("Routing Error: $e");
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _isRouting = false;
      _showStorePanel = false;
      _selectedStoreUuid = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationAndInit();
    });
  }

  Future<void> _requestLocationAndInit() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled.'),
            action: SnackBarAction(
                label: 'Enable',
                onPressed: () => Geolocator.openLocationSettings()),
          ),
        );
      }
      ref.read(locationProvider.notifier).setError('Location services disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ref.read(locationProvider.notifier).setError('Permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permanently denied. Enable in settings.')));
      }
      return;
    }

    ref.read(locationProvider.notifier).setLoading();

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      ref
          .read(locationProvider.notifier)
          .setLocation(pos.latitude, pos.longitude);

      if (_isMapReady) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    } catch (e) {
      AppLogger.e('Error getting location: $e');
      ref.read(locationProvider.notifier).setError(e.toString());
    }
  }

  void _selectStore(String uuid) {
    setState(() {
      _selectedStoreUuid = uuid;
      _showStorePanel = true;
    });

    final store = ref.read(allStoresProvider).value?.firstWhere((s) => s.uuid == uuid);

    if (store != null && _isMapReady) {
      _mapController.move(LatLng(store.latitude, store.longitude), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allStoresAsync = ref.watch(allStoresProvider);
    final location = ref.watch(locationProvider);
    final currentUid = ref.watch(currentUidProvider);

    final markers = allStoresAsync.maybeWhen(
      data: (stores) => stores
          .where((s) =>
      _selectedCategory == 'All' ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase())
          .map((store) {
        final isOwn = store.userId == currentUid;
        final isSelected = _selectedStoreUuid == store.uuid;

        return Marker(
          point: LatLng(store.latitude, store.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _selectStore(store.uuid),
            child: Icon(
              Icons.location_on,
              size: isSelected ? 45 : 35,
              color: isOwn ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
        );
      }).toList(),
      orElse: () => <Marker>[],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: location.hasLocation
                  ? LatLng(location.lat!, location.lng!)
                  : _defaultLatLng,
              initialZoom: 14,
              onTap: (_, __) {
                if (!_isRouting) {
                  setState(() => _showStorePanel = false);
                }
              },
              onMapReady: () {
                setState(() => _isMapReady = true);
                if (location.hasLocation) {
                  _mapController.move(LatLng(location.lat!, location.lng!), 15.0);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              // --- Route Layer ---
              if (_isRouting && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 5,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
              if (location.hasLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(location.lat!, location.lng!),
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Search + Filters (Hide when routing)
          if (!_isRouting)
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Text('Search stores near you...',
                                style: TextStyle(color: Colors.black54, fontSize: 16)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddStoreScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.add_location_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        _LegendDot(color: AppColors.primary, label: 'My stores'),
                        const SizedBox(width: AppSpacing.md),
                        _LegendDot(color: Colors.grey.shade400, label: "Others' stores"),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final selected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              boxShadow: [
                                if (!selected) const BoxShadow(color: Colors.black12, blurRadius: 4)
                              ],
                              border: Border.all(
                                  color: selected ? AppColors.primary : Colors.black12),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // --- Clear Route Button (Close) ---
          if (_isRouting)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _clearRoute,
                child: const Icon(Icons.close, color: Colors.red),
              ).animate().scale().fadeIn(),
            ),

          // My Location Button
          if (!_isRouting)
            Positioned(
              bottom: 130,
              right: 16,
              child: FloatingActionButton(
                heroTag: "my_location_btn",
                backgroundColor: Colors.white,
                elevation: 6,
                onPressed: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                    _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
                  } catch (e) {
                    AppLogger.e(e.toString());
                  }
                },
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),

          // Store Detail Panel
          if (_showStorePanel && _selectedStoreUuid != null && !_isRouting)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: allStoresAsync.maybeWhen(
                data: (stores) {
                  final store = stores.firstWhere((s) => s.uuid == _selectedStoreUuid);
                  return _StoreDetailPanel(
                    store: store,
                    currentUid: currentUid,
                    onClose: () => setState(() => _showStorePanel = false),
                    onGoTo: () {
                      if (location.hasLocation) {
                        _fetchRoadRoute(
                          LatLng(location.lat!, location.lng!),
                          LatLng(store.latitude, store.longitude),
                        );
                      }
                    },
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ).animate().slideY(begin: 1.0, end: 0),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _StoreDetailPanel extends StatelessWidget {
  final StoreModel store;
  final String? currentUid;
  final VoidCallback onClose;
  final VoidCallback onGoTo;

  const _StoreDetailPanel({
    required this.store,
    this.currentUid,
    required this.onClose,
    required this.onGoTo,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  store.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          Text(store.category, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreListsScreen(store: store),
                ),
              );
            },
            child: const Text("View My Lists"),
          ),
          const SizedBox(height: AppSpacing.sm),
          // --- New "Go To" Button ---
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
            onPressed: onGoTo,
            icon: const Icon(Icons.directions),
            label: const Text("Go To"),
          ),
        ],
      ),
    );
  }
}