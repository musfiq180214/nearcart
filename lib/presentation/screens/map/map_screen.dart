import 'dart:async';
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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedStoreUuid;
  bool _showStorePanel = false;

  static const _defaultLatLng = LatLng(23.8103, 90.4125); // Dhaka, BD

  final List<String> _categories = [
    'All', 'Grocery', 'Pharmacy', 'Electronics', 'Bakery', 'Market',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationAndInit();
    });
  }

  Future<void> _requestLocationAndInit() async {
    // 1. Check if services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.e("Location services are disabled.");

      // OPTION A: Show a snackbar with a button to open settings
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled.'),
            action: SnackBarAction(
              label: 'Enable',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }

      ref.read(locationProvider.notifier).setError('Location services are disabled.');
      return;
    }

    // 2. Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // This triggers the actual system "Allow NearCart to access location?" popup
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ref.read(locationProvider.notifier).setError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User has clicked "Don't ask again"
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in settings.'))
        );
      }
      return;
    }

    // 3. Notify provider we are loading
    ref.read(locationProvider.notifier).setLoading();

    try {
      // 4. Get Current Position
      // Using a timeLimit is good, but 5 seconds might be too short for a cold GPS start
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 5. Update the Riverpod State
      ref.read(locationProvider.notifier).setLocation(pos.latitude, pos.longitude);

      // 6. Move the Map
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        15.0,
      );

    } catch (e) {
      AppLogger.e("Error getting location: $e");
      ref.read(locationProvider.notifier).setError(e.toString());
    }
  }


  void _selectStore(String uuid) {
    setState(() {
      _selectedStoreUuid = uuid;
      _showStorePanel = true;
    });

    final store = ref
        .read(allStoresProvider)
        .value
        ?.firstWhere((s) => s.uuid == uuid);
    if (store != null) {
      _mapController.move(LatLng(store.latitude, store.longitude), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(allStoresProvider);
    final location = ref.watch(locationProvider);

    final markers = storesAsync.maybeWhen(
      data: (stores) =>
          stores
              .where((s) =>
          _selectedCategory == 'All' ||
              s.category.toLowerCase() == _selectedCategory.toLowerCase())
              .map((store) =>
              Marker(
                point: LatLng(store.latitude, store.longitude),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () => _selectStore(store.uuid),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedStoreUuid == store.uuid ? AppColors
                          .primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: Text(store.iconEmoji ?? '🏬',
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              ))
              .toList(),
      orElse: () => <Marker>[],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: location.hasLocation
                  ? LatLng(location.lat!, location.lng!)
                  : _defaultLatLng,
              initialZoom: 14,
              onTap: (_, __) => setState(() => _showStorePanel = false),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
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

          // 2. Search + Filters
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

          // 3. Bottom Panels (Store Details OR Nearby List)
          if (_showStorePanel && _selectedStoreUuid != null)
            Positioned(
              bottom: 90, left: 0, right: 0,
              child: _StoreDetailPanel(
                storeUuid: _selectedStoreUuid!,
                stores: storesAsync.value ?? [],
                onClose: () => setState(() => _showStorePanel = false),
              ).animate().slideY(begin: 1, end: 0),
            )
          else
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Colors.white.withOpacity(0)],
                  ),
                ),
                padding: const EdgeInsets.only(top: 40),
                child: _NearbyStoresList(
                  stores: storesAsync.value ?? [],
                  onStoreTap: _selectStore,
                ),
              ),
            ),

          // 4. Location FAB - MUST BE LAST TO BE ON TOP
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // Slides up when panel is open (330), stays down when horizontal list is visible (180)
            bottom: _showStorePanel ? 330 : 180,
            right: 16,
            child: FloatingActionButton(
              onPressed: _requestLocationAndInit, // Make sure this moves the map
              backgroundColor: Colors.white,
              elevation: 6,
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ).animate().fadeIn().scale(),
          ),
        ],
      ),
    );
  }
}

class _NearbyStoresList extends StatelessWidget {
  final List<StoreModel> stores;
  final void Function(String) onStoreTap;

  const _NearbyStoresList({required this.stores, required this.onStoreTap});

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: stores.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final store = stores[i];
          return Container(
            width: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => onStoreTap(store.uuid),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.iconEmoji ?? '🏬',
                        style: const TextStyle(fontSize: 28)),
                    const Spacer(),
                    Text(store.name, style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1),
                    Text(store.category, style: const TextStyle(
                        color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoreDetailPanel extends ConsumerWidget {
  final String storeUuid;
  final List<StoreModel> stores;
  final VoidCallback onClose;

  const _StoreDetailPanel(
      {required this.storeUuid, required this.stores, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = stores.firstWhere((s) => s.uuid == storeUuid,
        orElse: () => stores.first);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                  store.iconEmoji ?? '🏬', style: const TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(store.address,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.black12.withOpacity(0.05)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StoreListsScreen(store: store)),
                  ),
              child: const Text('View Store Lists',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}