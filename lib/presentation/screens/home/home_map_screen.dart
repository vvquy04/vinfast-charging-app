import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
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

  // ─── Routing state ─────────────────────────────
  Line? _routeLine;
  bool _isRouting = false;
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  String? _routeDestinationName;

  // ─── Search state ──────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().moveToCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isSelectingSuggestion) return;
    setState(() {
      _showSuggestions = _searchController.text.trim().isNotEmpty;
    });
  }

  // ─── Routing Methods ─────────────────────────────

  /// Gọi TrackAsia Routing API v1 (OSRM) để lấy tuyến đường
  /// và vẽ polyline trực tiếp lên bản đồ.
  Future<void> _fetchAndDrawRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String destinationName,
  }) async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // 1. Gọi API TrackAsia Routing v1
      final dio = Dio();
      final url =
          'https://maps.track-asia.com/route/v1/driving/$startLng,$startLat;$endLng,$endLat?key=public_key&geometries=geojson';

      debugPrint('🧭 Gọi API chỉ đường: $url');
      final response = await dio.get(url);

      if (response.statusCode != 200 || response.data['code'] != 'Ok') {
        throw Exception('Không tìm thấy tuyến đường');
      }

      final route = response.data['routes'][0];
      final geometry = route['geometry'];
      final coordinates = geometry['coordinates'] as List;
      final distance = (route['distance'] as num).toDouble(); // mét
      final duration = (route['duration'] as num).toDouble(); // giây

      // 2. Chuyển đổi tọa độ [lng, lat] thành List<LatLng>
      final List<LatLng> routePoints = coordinates
          .map<LatLng>((coord) => LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ))
          .toList();

      if (routePoints.isEmpty) {
        throw Exception('Tuyến đường trống');
      }

      // 3. Xóa tuyến đường cũ nếu có
      if (_routeLine != null && _mapController != null) {
        await _mapController!.removeLine(_routeLine!);
        _routeLine = null;
      }

      // 4. Vẽ tuyến đường mới lên bản đồ
      _routeLine = await _mapController?.addLine(
        LineOptions(
          geometry: routePoints,
          lineColor: '#007AFF',
          lineWidth: 5.0,
          lineOpacity: 0.85,
        ),
      );

      // 5. Cập nhật thông tin hiển thị
      String distanceText;
      if (distance >= 1000) {
        distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
      } else {
        distanceText = '${distance.toInt()} m';
      }

      String durationText;
      final totalMinutes = (duration / 60).ceil();
      if (totalMinutes >= 60) {
        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        durationText = '${hours}h ${mins} phút';
      } else {
        durationText = '$totalMinutes phút';
      }

      setState(() {
        _isRouting = true;
        _isLoadingRoute = false;
        _routeDistance = distanceText;
        _routeDuration = durationText;
        _routeDestinationName = destinationName;
      });

      // 6. Zoom bản đồ để hiển thị toàn bộ tuyến đường
      if (_mapController != null && routePoints.length >= 2) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
            routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
            routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
          ),
        );
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds,
              left: 80, top: 120, right: 80, bottom: 240),
        );
      }

      debugPrint('✅ Vẽ tuyến đường thành công: $distanceText, $durationText');
    } catch (e) {
      debugPrint('❌ Lỗi chỉ đường: $e');
      setState(() {
        _isLoadingRoute = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tìm tuyến đường: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Xóa tuyến đường hiện tại và trở về trạng thái bình thường.
  Future<void> _clearRoute() async {
    if (_routeLine != null && _mapController != null) {
      await _mapController!.removeLine(_routeLine!);
    }
    setState(() {
      _routeLine = null;
      _isRouting = false;
      _isLoadingRoute = false;
      _routeDistance = null;
      _routeDuration = null;
      _routeDestinationName = null;
    });
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
                onCameraIdle: () {
                  if (_mapController != null) {
                    final target = _mapController!.cameraPosition?.target;
                    if (target != null) {
                      context.read<StationProvider>().updateSearchPosition(
                            target.latitude,
                            target.longitude,
                          );
                    }
                  }
                },
              ),

              // ─── Top Search Bar Overlay ────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                child: _buildSearchBar(),
              ),

              // ─── Search Suggestions Overlay ────────────
              if (_showSuggestions)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20 + 56 + 8,
                  left: 20,
                  right: 20,
                  child: _buildSearchSuggestions(provider),
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
                      icon: _isRouting
                          ? Icons.close_rounded
                          : Icons.directions_rounded,
                      onTap: () {
                        if (_isRouting) {
                          // Đang chỉ đường → thoát chế độ chỉ đường
                          _clearRoute();
                          return;
                        }

                        final detail = provider.selectedStationDetail;
                        if (detail == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng chọn một trạm sạc trên bản đồ để chỉ đường',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (provider.currentPosition == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đang xác định vị trí của bạn, vui lòng thử lại sau',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        _fetchAndDrawRoute(
                          startLat: provider.currentPosition!.latitude,
                          startLng: provider.currentPosition!.longitude,
                          endLat: detail.latitude,
                          endLng: detail.longitude,
                          destinationName: detail.name,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ─── Loading Route Indicator ────────────────
              if (_isLoadingRoute)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Đang tìm tuyến đường...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ─── Bottom UI Overlay ─────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _isRouting
                    ? _buildRouteInfoPanel()
                    : _buildBottomOverlay(provider),
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
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm trạm sạc',
                hintStyle: TextStyle(color: AppColors.lightGray),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.close_rounded, color: AppColors.lightGray, size: 20),
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

  Widget _buildSearchSuggestions(StationProvider provider) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return const SizedBox.shrink();

    final filtered = provider.stations.where((station) {
      return station.name.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: filtered.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Không tìm thấy trạm sạc nào',
                style: TextStyle(color: AppColors.gray, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.smoke,
              ),
              itemBuilder: (context, index) {
                final station = filtered[index];
                return ListTile(
                  leading: const Icon(
                    Icons.ev_station_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    station.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${station.distance} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray,
                    ),
                  ),
                  onTap: () {
                    _isSelectingSuggestion = true;
                    _searchController.text = station.name;
                    _isSelectingSuggestion = false;
                    setState(() {
                      _showSuggestions = false;
                    });
                    FocusScope.of(context).unfocus();

                    // Select the station in provider
                    provider.fetchStationDetail(station.stationId);

                    // Animate camera to selected station
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(station.latitude, station.longitude),
                        15.5,
                      ),
                    );
                  },
                );
              },
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

  /// Panel hiển thị thông tin tuyến đường khi đang chỉ đường.
  Widget _buildRouteInfoPanel() {
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
        children: [
          // ─── Tiêu đề tuyến đường ────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF007AFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đang chỉ đường đến',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _routeDestinationName ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _clearRoute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.gray,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Thông tin khoảng cách & thời gian ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Khoảng cách
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            _routeDistance ?? '--',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const Text(
                            'Khoảng cách',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.lightGray.withOpacity(0.5),
                ),

                // Thời gian
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            _routeDuration ?? '--',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const Text(
                            'Thời gian dự kiến',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Nút thoát chỉ đường ───────────────
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Kết thúc chỉ đường',
              onPressed: _clearRoute,
            ),
          ),
        ],
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
