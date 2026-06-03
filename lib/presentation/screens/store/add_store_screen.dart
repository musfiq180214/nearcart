import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/store_model.dart';
import '../../../data/repositories/store_repository.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  const AddStoreScreen({super.key});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  String _selectedCategory = 'Grocery';
  String _selectedEmoji = '🛒';
  double? _lat;
  double? _lng;
  bool _isSaving = false;
  bool _locationLoading = false;

  final _categories = [
    ('Grocery', '🛒'),
    ('Pharmacy', '💊'),
    ('Electronics', '📱'),
    ('Bakery', '🍞'),
    ('Market', '🏪'),
    ('Restaurant', '🍽️'),
    ('Clothing', '👗'),
    ('Other', '🏬'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location captured via GPS!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  Future<void> _pickOnMap() async {
    // Default to Dhaka or current captured location
    final LatLng initialPoint = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(23.8103, 90.4125);

    final LatLng? result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => _MapPickerScreen(initialLocation: initialPoint),
      ),
    );

    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a store name.')));
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please capture the store location.')));
      return;
    }

    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to add a store.')));
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final store = StoreModel()
      ..uuid = const Uuid().v4()
      ..userId = uid
      ..name = _nameCtrl.text.trim()
      ..category = _selectedCategory
      ..iconEmoji = _selectedEmoji
      ..latitude = _lat!
      ..longitude = _lng!
      ..address = _addressCtrl.text.trim().isEmpty
          ? '$_lat, $_lng'
          : _addressCtrl.text.trim()
      ..phoneNumber =
      _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim()
      ..openingHours =
      _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim()
      ..createdAt = now
      ..updatedAt = now;

    try {
      await ref.read(storeRepositoryProvider).addStore(store);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving store: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Store',
            style: AppTextStyles.headingLarge.copyWith(color: Colors.black87)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Category'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = cat.$1 == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat.$1;
                    _selectedEmoji = cat.$2;
                  }),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.$2, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(cat.$1,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.black87,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: AppSpacing.lg),
            _SectionLabel('Store Name *'),
            const SizedBox(height: 6),
            _InputField(
              controller: _nameCtrl,
              hint: 'e.g. Agora Supermarket',
              icon: Icons.storefront_outlined,
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionLabel('Address (optional)'),
            const SizedBox(height: 6),
            _InputField(
              controller: _addressCtrl,
              hint: 'e.g. 12 Gulshan Avenue',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionLabel('Phone (optional)'),
            const SizedBox(height: 6),
            _InputField(
              controller: _phoneCtrl,
              hint: '+880 1700 000000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: AppSpacing.lg),
            _SectionLabel('Location *'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LocationActionCard(
                    onTap: _useCurrentLocation,
                    isLoading: _locationLoading,
                    icon: Icons.my_location_rounded,
                    label: 'Use GPS',
                    isActive: _lat != null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _LocationActionCard(
                    onTap: _pickOnMap,
                    icon: Icons.map_outlined,
                    label: 'Pick on Map',
                    isActive: _lat != null,
                  ),
                ),
              ],
            ),
            if (_lat != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Location set: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Save Store',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Supporting Widgets ──────────────────────────────────────────────────────

class _LocationActionCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final IconData icon;
  final String label;
  final bool isActive;

  const _LocationActionCard({
    required this.onTap,
    this.isLoading = false,
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isActive ? AppColors.primary.withOpacity(0.5) : Colors.black12),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const _MapPickerScreen({required this.initialLocation});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late LatLng _currentCenter;
  final MapController _mapController = MapController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final myLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(myLatLng, 16);
      setState(() => _currentCenter = myLatLng);
    } catch (e) {
      AppLogger.e('Error getting location in picker: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Move map to store', style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _currentCenter),
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,       // <-- wire up the controller
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 16,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  _currentCenter = pos.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nearcart',
              ),
            ],
          ),

          // Crosshair pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, color: AppColors.primary, size: 45),
            ),
          ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton(
              heroTag: "picker_my_location",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 6,
              onPressed: _isLocating ? null : _goToMyLocation,
              child: _isLocating
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
                  : const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Hint bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Text(
                '📍 Align the store icon with the exact location on the map.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InputField({required this.controller, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Icon(icon, color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}