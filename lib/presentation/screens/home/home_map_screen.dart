import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/station_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'helpers/map_marker_generator.dart';
import 'widgets/station_filter_bottom_sheet.dart';
import 'widgets/route_info_panel.dart';
import 'widgets/station_preview_card.dart';
import 'widgets/station_horizontal_list.dart';
import 'widgets/search_suggestions_overlay.dart';

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

  // Theo dõi các marker (symbols) để có thể cập nhật chúng
  final Map<int, Symbol> _stationSymbols = {};
  Symbol? _userSymbol;
  ui.Image? _logoImage;

  // ─── Trạng thái vẽ tuyến đường ─────────────────────────────
  Line? _routeLine;
  bool _isRouting = false;
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  String? _routeDestinationName;
  double? _routeEndLat;
  double? _routeEndLng;

  // ─── Trạng thái tìm kiếm ──────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = context.read<StationProvider>();
      stationProvider.moveToCurrentLocation();

      // Đọc thông tin xe người dùng và tự động bật lọc trạm tương thích
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user != null && user.vehicleModel != null) {
        stationProvider.setUserVehicle(user.vehicleModel, user.connectorType);
      }
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

  // ─── Các phương thức vẽ đường ─────────────────────────────

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
          'https://maps.track-asia.com/route/v1/car/$startLng,$startLat;$endLng,$endLat?key=public_key&geometries=geojson';

      debugPrint('Calling routing API: $url');
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
          .map<LatLng>(
            (coord) => LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            ),
          )
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
        _routeEndLat = endLat;
        _routeEndLng = endLng;
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
          CameraUpdate.newLatLngBounds(
            bounds,
            left: 80,
            top: 120,
            right: 80,
            bottom: 240,
          ),
        );
      }

      debugPrint('Route drawn successfully: $distanceText, $durationText');
    } catch (e) {
      debugPrint('Routing error: $e');
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
      _routeEndLat = null;
      _routeEndLng = null;
    });
  }

  void _launchExternalMap(double lat, double lng) async {
    final String googleUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final String appleUrl =
        'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
    final String geoUrl = 'geo:$lat,$lng?q=$lat,$lng(Trạm sạc)';

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse(appleUrl))) {
          await launchUrl(Uri.parse(appleUrl), mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Trên Android hoặc fallback cho iOS: Thử geo intent trước, sau đó là Google Maps URL, cuối cùng là gọi trực tiếp không qua check
      if (await canLaunchUrl(Uri.parse(geoUrl))) {
        await launchUrl(Uri.parse(geoUrl), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
      } else {
        // Fallback trực tiếp nếu canLaunchUrl trả về false nhưng thiết bị vẫn có app xử lý
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening map: $e');
    }
  }

  void _startExternalNavigation() {
    if (_routeEndLat != null && _routeEndLng != null) {
      _launchExternalMap(_routeEndLat!, _routeEndLng!);
    }
  }

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    // Đăng ký bộ xử lý sự kiện nhấn vào symbol trên bản đồ
    _mapController!.onSymbolTapped.add(_onSymbolTapped);
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Đăng ký các hình ảnh marker tùy chỉnh
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

  Future<void> _addMarkerImages() async {
    if (_mapController == null) return;

    _logoImage = await MapMarkerGenerator.loadLogoImage('assets/images/logo.jpg');

    final userIcon = await MapMarkerGenerator.createUserMarkerImage();
    await _mapController!.addImage('user-marker', userIcon);

    final availableIcon = await MapMarkerGenerator.createStationMarkerImage(
      isAvailable: true,
      logoImage: _logoImage,
    );
    await _mapController!.addImage('station-available', availableIcon);

    final unavailableIcon = await MapMarkerGenerator.createStationMarkerImage(
      isAvailable: false,
      logoImage: _logoImage,
    );
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
          final station = provider.stations.firstWhere(
            (s) => s.stationId == stationId,
          );
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
      resizeToAvoidBottomInset: false,
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
                  child: SearchSuggestionsOverlay(
                    query: _searchController.text,
                    stations: provider.stations,
                    onStationTap: (station) {
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
                  ),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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

              // ─── Vehicle Filter Banner ────────────────
              if (provider.isFilteringByVehicle && provider.userVehicleModel != null)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: provider.selectedStationDetail != null ? 230 : 160,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded, size: 18, color: Color(0xFF43A047)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đang lọc cho ${provider.userVehicleModel} (${provider.userConnectorType})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => provider.clearVehicleFilter(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.smoke,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.gray),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── Bottom UI Overlay ─────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _isRouting
                    ? RouteInfoPanel(
                        routeDistance: _routeDistance,
                        routeDuration: _routeDuration,
                        routeDestinationName: _routeDestinationName,
                        onCancel: _clearRoute,
                        onStartNavigation: _startExternalNavigation,
                      )
                    : provider.selectedStationDetail != null
                        ? StationPreviewCard(
                            detail: provider.selectedStationDetail!,
                            userConnectorType: provider.userConnectorType,
                            userVehicleModel: provider.userVehicleModel,
                            onDirections: () {
                              final pos = provider.currentPosition;
                              final station = provider.selectedStationDetail!;
                              if (pos != null) {
                                provider.clearSelection();
                                _fetchAndDrawRoute(
                                  startLat: pos.latitude,
                                  startLng: pos.longitude,
                                  endLat: station.latitude,
                                  endLng: station.longitude,
                                  destinationName: station.name,
                                );
                              } else {
                                _launchExternalMap(station.latitude, station.longitude);
                              }
                            },
                          )
                        : StationHorizontalList(
                            stations: provider.stations,
                            userConnectorType: provider.userConnectorType,
                            userVehicleModel: provider.userVehicleModel,
                            onStationTap: (station) {
                              provider.fetchStationDetail(station.stationId);
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(station.latitude, station.longitude),
                                  14.5,
                                ),
                              );
                            },
                          ),
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
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.lightGray,
                  size: 20,
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const StationFilterBottomSheet(),
              );
            },
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
