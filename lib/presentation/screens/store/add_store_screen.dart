import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../data/models/store_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  final LatLng? initialPosition;

  const AddStoreScreen({super.key, this.initialPosition});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final MapController _mapController = MapController();

  String _category = 'grocery';
  String _emoji = '🛒';
  LatLng? _pickedLocation;
  bool _isSaving = false;

  final _categories = [
    ('grocery', '🛒', 'Grocery'),
    ('pharmacy', '💊', 'Pharmacy'),
    ('electronics', '📱', 'Electronics'),
    ('bakery', '🥖', 'Bakery'),
    ('butcher', '🥩', 'Butcher'),
    ('market', '🏪', 'Market'),
    ('clothing', '👕', 'Clothing'),
    ('hardware', '🔧', 'Hardware'),
  ];

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
    final loc = ref.read(locationProvider);
    if (_pickedLocation == null && loc.hasLocation) {
      _pickedLocation = LatLng(loc.lat!, loc.lng!);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a store name');
      return;
    }
    if (_pickedLocation == null) {
      _showSnack('Please pick a location on the map');
      return;
    }

    setState(() => _isSaving = true);

    final store = createStore(
      uuid: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      category: _category,
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      address: _addressCtrl.text.trim().isEmpty
          ? 'No address provided'
          : _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      iconEmoji: _emoji,
    );

    await ref.read(storeRepositoryProvider).addStore(store);
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Add Store', style: AppTextStyles.headingLarge.copyWith(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map picker (Light Theme)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  height: 220,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pickedLocation ?? const LatLng(23.8103, 90.4125),
                      initialZoom: 15,
                      onTap: (_, pos) => setState(() => _pickedLocation = pos),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      if (_pickedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 40),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_pickedLocation == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text('Tap the map to set location', style: AppTextStyles.bodySmall.copyWith(color: Colors.orange.shade800)),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Form Fields
            _label('Store Name'),
            _buildTextField(
              controller: _nameCtrl,
              hint: 'e.g. Fresh Mart, Shajgoj',
              icon: Icons.store_rounded,
            ),

            const SizedBox(height: AppSpacing.md),

            _label('Address (optional)'),
            _buildTextField(
              controller: _addressCtrl,
              hint: 'Street, area, city',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: AppSpacing.md),

            _label('Phone (optional)'),
            _buildTextField(
              controller: _phoneCtrl,
              hint: '+880...',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Category picker
            _label('Category'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _categories.map((cat) {
                final selected = _category == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() {
                    _category = cat.$1;
                    _emoji = cat.$2;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: selected ? AppColors.primary : Colors.black12),
                      boxShadow: [
                        if (selected) BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.$2, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          cat.$3,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Store', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: AppTextStyles.labelMedium.copyWith(color: Colors.black54, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}