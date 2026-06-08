import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:provider/provider.dart';
import '../../providers/station_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  TrackAsiaMapController? _mapController;
  bool _isMapReady = false;

  // TrackAsia style URL (free demo key)
  static const String _styleUrl =
      'https://maps.track-asia.com/styles/v2/streets.json?key=public_key';

  // Hanoi center (Hoan Kiem Lake)
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(21.0285, 105.8542),
    zoom: 14.5,
  );

  // Track symbols so we can update them
  final Map<int, Symbol> _stationSymbols = {};
  Symbol? _userSymbol;
  ui.Image? _logoImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().moveToCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    // Register symbol tap handler on the controller
    _mapController!.onSymbolTapped.add(_onSymbolTapped);
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Register custom images for markers
    await _addMarkerImages();

    setState(() => _isMapReady = true);

    // Add markers after style is loaded
    final provider = context.read<StationProvider>();
    await _updateMarkers(provider);

    // Listen to provider changes
    provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (!_isMapReady || _mapController == null) return;
    final provider = context.read<StationProvider>();
    _updateMarkers(provider);
  }

  /// Create a colored circle icon for user marker
  Future<Uint8List> _createUserMarkerImage() async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pulse ring
    final pulsePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, pulsePaint);

    // Outer dark border
    final borderPaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 38, borderPaint);

    // Inner white circle
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 32, whitePaint);

    // Letter "U"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'U',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Create station marker icon
  Future<Uint8List> _createStationMarkerImage(bool isAvailable) async {
    const double width = 160;
    const double height = 180;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Create teardrop pin shape (circle + triangle bottom)
    final pinPath = Path();
    pinPath.addOval(
      Rect.fromCircle(center: const Offset(width / 2, 65), radius: 50),
    );

    final trianglePath = Path();
    trianglePath.moveTo(width / 2 - 38, 97);
    trianglePath.lineTo(width / 2, height - 12);
    trianglePath.lineTo(width / 2 + 38, 97);
    trianglePath.close();

    final unifiedPath = Path.combine(PathOperation.union, pinPath, trianglePath);

    // 2. Draw Shadow under the pin
    canvas.drawPath(
      unifiedPath.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3. Draw Background fill (Navy for Available, LightGray for Unavailable)
    final bgPaint = Paint()
      ..color = isAvailable ? AppColors.navy : AppColors.lightGray
      ..style = PaintingStyle.fill;
    canvas.drawPath(unifiedPath, bgPaint);

    // 4. Draw White border outline
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(unifiedPath, borderPaint);

    // 5. Draw the preloaded Logo image inside a circular clip, centered in the pin
    if (_logoImage != null) {
      canvas.save();
      
      final logoClip = Path();
      logoClip.addOval(
        Rect.fromCircle(center: const Offset(width / 2, 65), radius: 38),
      );
      canvas.clipPath(logoClip);

      canvas.drawImageRect(
        _logoImage!,
        Rect.fromLTWH(0, 0, _logoImage!.width.toDouble(), _logoImage!.height.toDouble()),
        Rect.fromCircle(center: const Offset(width / 2, 65), radius: 38),
        Paint(),
      );
      
      canvas.restore();

      // Draw thin white border around the logo circular mask
      canvas.drawCircle(
        const Offset(width / 2, 65),
        38,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _addMarkerImages() async {
    if (_mapController == null) return;

    // Load logo image asset once
    try {
      final byteData = await rootBundle.load('assets/images/logo.jpg');
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _logoImage = frame.image;
    } catch (e) {
      debugPrint('Error loading logo asset: $e');
    }

    final userIcon = await _createUserMarkerImage();
    await _mapController!.addImage('user-marker', userIcon);

    final availableIcon = await _createStationMarkerImage(true);
    await _mapController!.addImage('station-available', availableIcon);

    final unavailableIcon = await _createStationMarkerImage(false);
    await _mapController!.addImage('station-unavailable', unavailableIcon);
  }

  Future<void> _updateMarkers(StationProvider provider) async {
    if (_mapController == null || !_isMapReady) return;

    // --- Update user marker ---
    if (provider.currentPosition != null) {
      final userLatLng = LatLng(
        provider.currentPosition!.latitude,
        provider.currentPosition!.longitude,
      );

      if (_userSymbol != null) {
        await _mapController!.updateSymbol(
          _userSymbol!,
          SymbolOptions(geometry: userLatLng),
        );
      } else {
        _userSymbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: userLatLng,
            iconImage: 'user-marker',
            iconSize: 0.5,
            iconAnchor: 'center',
          ),
        );
      }
    }

    // --- Update station markers ---
    // Remove old station symbols that are no longer in the list
    final currentStationIds = provider.stations.map((s) => s.stationId).toSet();
    final toRemove = _stationSymbols.keys
        .where((id) => !currentStationIds.contains(id))
        .toList();
    for (final id in toRemove) {
      await _mapController!.removeSymbol(_stationSymbols[id]!);
      _stationSymbols.remove(id);
    }

    // Add or update station symbols
    for (final station in provider.stations) {
      final stationLatLng = LatLng(station.latitude, station.longitude);
      final isAvailable = station.connectorTypes.any((c) => c.totalPorts > 0);
      final iconName = isAvailable
          ? 'station-available'
          : 'station-unavailable';

      if (_stationSymbols.containsKey(station.stationId)) {
        await _mapController!.updateSymbol(
          _stationSymbols[station.stationId]!,
          SymbolOptions(
            geometry: stationLatLng,
            iconImage: iconName,
            iconSize: 1.2,
          ),
        );
      } else {
        final symbol = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: stationLatLng,
            iconImage: iconName,
            iconSize: 1.2,
            iconAnchor: 'bottom',
          ),
        );
        _stationSymbols[station.stationId] = symbol;
      }
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    final provider = context.read<StationProvider>();
    // Find station id from symbol
    for (final entry in _stationSymbols.entries) {
      if (entry.value.id == symbol.id) {
        final stationId = entry.key;
        provider.fetchStationDetail(stationId);
        
        // Find the station in the list to animate/zoom camera to its coordinates
        try {
          final station = provider.stations.firstWhere((s) => s.stationId == stationId);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(station.latitude, station.longitude),
              15.5, // Zoom in closer to the selected station
            ),
          );
        } catch (e) {
          debugPrint('Error animating camera to station: $e');
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StationProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              TrackAsiaMap(
                styleString: _styleUrl,
                initialCameraPosition: _initialCamera,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                myLocationEnabled: false,
                trackCameraPosition: true,
                compassEnabled: false,
              ),

              // ─── Top Search Bar Overlay ────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                child: _buildSearchBar(),
              ),

              // ─── Floating Action Buttons right ─────────
              Positioned(
                right: 20,
                bottom: 180,
                child: Column(
                  children: [
                    _FloatingButton(
                      icon: Icons.my_location_rounded,
                      onTap: () async {
                        await provider.moveToCurrentLocation();
                        if (provider.currentPosition != null &&
                            _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(
                                provider.currentPosition!.latitude,
                                provider.currentPosition!.longitude,
                              ),
                              14.5,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _FloatingButton(
                      icon: Icons.directions_rounded,
                      onTap: () {
                        // TODO: Implement routing
                      },
                    ),
                  ],
                ),
              ),

              // ─── Bottom UI Overlay ─────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _buildBottomOverlay(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final provider = context.watch<StationProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.lightGray),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trạm sạc',
                hintStyle: TextStyle(color: AppColors.lightGray),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.black,
                    size: 20,
                  ),
                ),
                // Badge hiển thị khi có bộ lọc đang hoạt động
                if (provider.hasActiveFilters)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final provider = context.read<StationProvider>();

    // Tạo biến tạm để người dùng chỉnh sửa trước khi Áp dụng
    String? selectedConnector = provider.connectorType;
    int? selectedPower = provider.minPowerKw;
    double? selectedRating = provider.minRating;

    final connectorOptions = ['AC', 'DC', 'CCS2', 'CHAdeMO', 'Type2'];
    final powerOptions = [0, 7, 22, 50, 100, 150, 250, 350];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Handle bar ────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Title ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedConnector = null;
                            selectedPower = null;
                            selectedRating = null;
                          });
                        },
                        child: const Text(
                          'Xóa bộ lọc',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Connector Type ────────────────────
                  const Text(
                    'Loại cổng sạc',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: connectorOptions.map((type) {
                      final isSelected = selectedConnector == type;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedConnector = isSelected ? null : type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.smoke,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ─── Min Power ─────────────────────────
                  Text(
                    'Công suất tối thiểu: ${selectedPower ?? 0} kW',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: powerOptions.map((kw) {
                      final isSelected = (selectedPower ?? 0) == kw;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedPower = kw == 0 ? null : kw;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.smoke,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            kw == 0 ? 'Tất cả' : '≥ $kw kW',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ─── Min Rating ────────────────────────
                  Text(
                    'Đánh giá tối thiểu: ${selectedRating?.toStringAsFixed(0) ?? 'Tất cả'} ⭐',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final star = (i + 1).toDouble();
                      final isSelected = (selectedRating ?? 0) >= star;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedRating = selectedRating == star
                                ? null
                                : star;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isSelected
                                ? Colors.amber
                                : AppColors.lightGray,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // ─── Apply Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.applyFilters(
                          connectorType: selectedConnector,
                          minPowerKw: selectedPower,
                          minRating: selectedRating,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomOverlay(StationProvider provider) {
    if (provider.isLoading && provider.stations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.selectedStationDetail != null) {
      final detail = provider.selectedStationDetail!;
      // Bottom Sheet (Chi tiết trạm sạc)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => provider.clearSelection(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.lightGray,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Đang sử dụng',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.gray,
                ),
                const SizedBox(width: 4),
                const Text(
                  '1.9 km',
                  style: TextStyle(fontSize: 13, color: AppColors.gray),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Chi Tiết',
                onPressed: () {
                  Navigator.pushNamed(context, '/station_detail');
                },
              ),
            ),
          ],
        ),
      );
    }

    // Horizontal List (Danh sách trạm sạc)
    if (provider.stations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: provider.stations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final station = provider.stations[index];
          return GestureDetector(
            onTap: () {
              provider.fetchStationDetail(station.stationId);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(station.latitude, station.longitude),
                  14.5,
                ),
              );
            },
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.smoke,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: station.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              station.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.charging_station_rounded,
                                color: AppColors.gray,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.charging_station_rounded,
                            color: AppColors.gray,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Cách ${station.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cổng sạc sẵn có: ${station.connectorTypes.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.black, size: 20),
      ),
    );
  }
}
