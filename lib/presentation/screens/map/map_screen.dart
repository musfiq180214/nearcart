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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedStoreUuid;
  bool _showStorePanel = false;

  // 1. Flag to prevent calling move() before map is ready
  bool _isMapReady = false;

  static const _defaultLatLng = LatLng(23.8103, 90.4125); // Dhaka, BD

  final List<String> _categories = [
    'All', 'Grocery', 'Pharmacy', 'Electronics', 'Bakery', 'Market',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Start location request after first frame
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
            content: Text(
                'Location permanently denied. Enable in settings.')));
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

      // 2. Check the flag before using the controller
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

    // 3. Check the flag here as well
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
              onTap: (_, __) => setState(() => _showStorePanel = false),
              // 4. Critical: Set the flag and move if location was already found
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

          // Search + Filters
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

                // Legend
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

                // Category chips
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

          // My Location Button
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

                  // Update provider (optional but good)
                  ref.read(locationProvider.notifier)
                      .setLocation(pos.latitude, pos.longitude);

                  // Move map
                  if (_isMapReady) {
                    _mapController.move(
                      LatLng(pos.latitude, pos.longitude),
                      15.0,
                    );
                  }
                } catch (e) {
                  AppLogger.e("Error getting current location: $e");
                }
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.blueAccent,
              ),
            ).animate().fadeIn().scale(),
          ),

          // Store Panel
          if (_showStorePanel && _selectedStoreUuid != null)
            Positioned(
              bottom: 100, // Adjusted to sit above the Bottom Nav Bar
              left: 16,
              right: 16,
              child: allStoresAsync.maybeWhen(
                data: (stores) {
                  // Find the specific store data
                  final store = stores.firstWhere(
                        (s) => s.uuid == _selectedStoreUuid,
                    orElse: () => stores.first,
                  );

                  return _StoreDetailPanel(
                    storeUuid: store.uuid,
                    stores: stores,
                    currentUid: currentUid,
                    onClose: () => setState(() => _showStorePanel = false),
                  ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

// ── Store Marker ──────────────────────────────────────────────────────────────

/// Green/primary ring = own store | Grey ring = others' store
class _StoreMarker extends StatelessWidget {
  final StoreModel store;
  final bool isOwn;
  final bool isSelected;

  const _StoreMarker(
      {required this.store, required this.isOwn, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final borderColor = isOwn ? AppColors.primary : Colors.grey.shade400;
    final bgColor = isSelected
        ? (isOwn ? AppColors.primary : Colors.grey.shade500)
        : Colors.white;

    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: isOwn ? 2.5 : 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(store.iconEmoji ?? '🏬',
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        // "Mine" star badge
        if (isOwn)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Center(
                child: Text('★',
                    style: TextStyle(color: Colors.white, fontSize: 7)),
              ),
            ),
          ),
      ],
    );
  }
}



// ── Nearby list ───────────────────────────────────────────────────────────────

class _NearbyStoresList extends StatelessWidget {
  final List<StoreModel> stores;
  final String? currentUid;
  final void Function(String) onStoreTap;

  const _NearbyStoresList(
      {required this.stores,
        required this.currentUid,
        required this.onStoreTap});

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
          final isOwn = store.userId == currentUid;

          return Container(
            width: 170,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isOwn
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.black12,
                width: isOwn ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4))
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
                    Row(
                      children: [
                        Text(store.iconEmoji ?? '🏬',
                            style: const TextStyle(fontSize: 26)),
                        if (isOwn) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text('Mine',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(store.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(store.category,
                        style: const TextStyle(
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

// ── Store detail panel ────────────────────────────────────────────────────────

class _StoreDetailPanel extends ConsumerWidget {
  final String storeUuid;
  final List<StoreModel> stores;
  final String? currentUid;
  final VoidCallback onClose;

  const _StoreDetailPanel(
      {required this.storeUuid,
        required this.stores,
        required this.currentUid,
        required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store =
    stores.firstWhere((s) => s.uuid == storeUuid, orElse: () => stores.first);
    final isOwn = store.userId == currentUid;

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
              Text(store.iconEmoji ?? '🏬',
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(store.name,
                              style: const TextStyle(
                                color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (isOwn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: const Text(
                              '⭐ My Store',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(store.address,
                        style: const TextStyle(color: Colors.black54)),
                    Text(store.category,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                style: IconButton.styleFrom(
                    backgroundColor:
                    Colors.black12.withOpacity(0.05)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Only show "View Store Lists" for own stores
          if (isOwn)
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StoreListsScreen(store: store)),
                ),
                child: const Text('View My Lists',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.black12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined,
                      color: Colors.black38, size: 18),
                  SizedBox(width: 8),
                  Text("Community store — view only",
                      style: TextStyle(color: Colors.black54, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}