import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/location_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  // Center map initially on UAD Kampus 4
  final LatLng _currentCenter = const LatLng(-7.83321, 110.38288);
  List<Marker> _markers = [];
  List<LocationModel> _locations = [];
  String _searchQuery = '';
  bool _isLoading = false;
  double _zoom = 16.0;
  LatLng _mapCenter = const LatLng(-7.83321, 110.38288);

  // Embedded SVG strings (inline to avoid external asset loading issues)
  static const String _restaurantSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="7" r="5" fill="#ff7a00" />
  <rect x="8" y="2" width="1" height="8" fill="#ffffff" />
  <rect x="12" y="2" width="1" height="8" fill="#ffffff" />
  <path d="M6 14c0 3 4 6 6 6s6-3 6-6v-1H6v1z" fill="#ff7a00" opacity="0.95" />
</svg>
''';

  static const String _pinSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#e53935" d="M12 2C8 2 5 5 5 9c0 5 7 13 7 13s7-8 7-13c0-4-3-7-7-7z" />
  <circle cx="12" cy="9" r="2.5" fill="#fff" />
</svg>
''';

  // Picking state
  bool _pickingOnMap = false;
  LatLng? _tempPoint;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await _apiService.getLocations();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase().trim();
    final filtered = q.isEmpty
        ? _locations
        : _locations.where((l) => l.name.toLowerCase().contains(q)).toList();
    setState(() {
      _markers = filtered.map((loc) {
        return Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: 140,
          height: 90,
          child: _buildFancyMarker(loc.name),
        );
      }).toList();
    });
  }

  // Return embedded restaurant SVG as widget
  Widget _restaurantSvgWidget(double width, double height) {
    return SvgPicture.string(_restaurantSvg, width: width, height: height);
  }

  Widget _buildFancyMarker(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular icon with subtle gradient and elevation
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFB36B), Color(0xFFFF7A00)]),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: _restaurantSvgWidget(22, 22),
        ),
        const SizedBox(height: 6),
        // Label bubble with modern style
        Container(
          constraints: const BoxConstraints(maxWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 6, color: Colors.black26, offset: Offset(0, 3))
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _startAddFlow() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: Colors.orange),
              title: const Text('Gunakan GPS'),
              onTap: () async {
                Navigator.pop(context);
                await _addUsingGPS();
              },
            ),
            ListTile(
              leading: const Icon(Icons.place, color: Colors.orange),
              title: const Text('Pilih di Peta'),
              onTap: () {
                Navigator.pop(context);
                _startPickOnMap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Batal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addUsingGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final success =
        await _showNameBottomSheet(LatLng(pos.latitude, pos.longitude));
    if (success == true) {
      await _fetchLocations();
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rekomendasi berhasil disimpan!')));
    }
  }

  void _startPickOnMap() {
    setState(() {
      _pickingOnMap = true;
      _tempPoint = _currentCenter;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ketuk peta untuk memindahkan pin, lalu konfirmasi.'),
      duration: Duration(seconds: 3),
    ));
  }

  void _cancelPick() {
    setState(() {
      _pickingOnMap = false;
      _tempPoint = null;
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    if (!_pickingOnMap) return;
    setState(() {
      _tempPoint = latlng;
    });
  }

  void _confirmPick() {
    if (_tempPoint == null) return;
    // open bottom sheet and await result
    _showNameBottomSheet(_tempPoint!).then((success) async {
      if (success == true) {
        await _fetchLocations();
        _mapController.move(_tempPoint!, 15);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rekomendasi berhasil disimpan!')));
      }
    });
    setState(() {
      _pickingOnMap = false;
    });
  }

  Future<bool?> _showNameBottomSheet(LatLng point) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final nameController = TextEditingController();
        final descController = TextEditingController();
        bool posting = false;

        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Rekomendasi Kuliner',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tempat / Menu',
                      hintText: 'Misal: Nasi Goreng Pak Kumis',
                      prefixIcon: Icon(Icons.fastfood, color: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      hintText: 'Keterangan singkat',
                      prefixIcon: Icon(Icons.note, color: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Koordinat: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          onPressed: posting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;
                                  setSheetState(() => posting = true);
                                  final newLoc = LocationModel(
                                      id: '',
                                      name: name,
                                      description: descController.text.trim(),
                                      latitude: point.latitude,
                                      longitude: point.longitude);
                                  // capture Navigator for this sheet before awaiting
                                  final sheetNavigator = Navigator.of(context);
                                  final success =
                                      await _apiService.addLocation(newLoc);
                                  if (!mounted) return;
                                  setSheetState(() => posting = false);
                                  sheetNavigator.pop(success);
                                },
                          child: posting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Simpan',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> allMarkers = [..._markers];
    if (_tempPoint != null) {
      allMarkers.add(Marker(
        point: _tempPoint!,
        width: 64,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(_pinSvg, width: 36, height: 36),
            const SizedBox(height: 2),
          ],
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KulinerHunt'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _fetchLocations)
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _zoom,
              onTap: _onMapTap,
              onPositionChanged: (pos, hasGesture) {
                setState(() {
                  _mapCenter = pos.center;
                  _zoom = pos.zoom;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kuliner.app',
              ),
              MarkerLayer(markers: allMarkers),
            ],
          ),
          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 80,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Cari nama tempat...'),
                        onChanged: (v) {
                          _searchQuery = v;
                          _applyFilter();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black54),
                      onPressed: () {
                        _searchQuery = '';
                        _applyFilter();
                      },
                    )
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.orange)),
              ),
            ),

          // Map controls (zoom + locate)
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: () async {
                    try {
                      final pos = await Geolocator.getCurrentPosition();
                      _mapController.move(
                          LatLng(pos.latitude, pos.longitude), 15);
                    } catch (_) {}
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _zoom += 1;
                    _mapController.move(_mapCenter, _zoom);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _zoom = (_zoom - 1).clamp(1.0, 20.0);
                    _mapController.move(_mapCenter, _zoom);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.orange),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_pickingOnMap)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'cancelPick',
                        onPressed: _cancelPick,
                        backgroundColor: Colors.grey.shade700,
                        icon: const Icon(Icons.close),
                        label: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.extended(
                        heroTag: 'confirmPick',
                        onPressed: _confirmPick,
                        backgroundColor: Colors.orange,
                        icon: const Icon(Icons.check),
                        label: const Text('Konfirmasi',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'add',
                  onPressed: _startAddFlow,
                  backgroundColor: Colors.orange,
                  label: const Text('Rekomendasiin!',
                      style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.add_location_alt, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
