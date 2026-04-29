import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/station_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/map_style.dart';
import '../../../core/utils/map_marker_util.dart';
import '../../../core/widgets/app_button.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(10.84, 106.84), // Default fallback
    zoom: 14.4746,
  );

  BitmapDescriptor? _avatarMarker;
  BitmapDescriptor? _stationAvailable;
  BitmapDescriptor? _stationInUse;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    // Schedule fetching after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().moveToCurrentLocation();
    });
  }

  Future<void> _loadCustomMarkers() async {
    final avatar = await MapMarkerUtil.createAvatarMarker();
    final stationAvail = await MapMarkerUtil.createStationMarker(true);
    final stationUse = await MapMarkerUtil.createStationMarker(false);
    
    if (mounted) {
      setState(() {
        _avatarMarker = avatar;
        _stationAvailable = stationAvail;
        _stationInUse = stationUse;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    controller.setMapStyle(AppMapStyle.silverMapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StationProvider>(
        builder: (context, provider, child) {
          final position = provider.currentPosition;
          
          CameraPosition currentCamera = _initialCamera;
          if (position != null) {
            currentCamera = CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14.5,
            );
          }

          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: currentCamera,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
                markers: _buildMarkers(provider),
                polylines: provider.routePolylines,
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
                        if (provider.currentPosition != null) {
                          final c = await _controller.future;
                          c.animateCamera(CameraUpdate.newLatLng(
                            LatLng(provider.currentPosition!.latitude,
                                provider.currentPosition!.longitude),
                          ));
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _FloatingButton(
                      icon: Icons.directions_rounded,
                      onTap: () {
                        if (provider.selectedStationDetail != null) {
                          final detail = provider.selectedStationDetail!;
                          final dest = LatLng(detail.latitude, detail.longitude);
                          provider.drawRoute(dest);
                          _zoomToFitRoute(provider, dest);
                        }
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

  Set<Marker> _buildMarkers(StationProvider provider) {
    Set<Marker> markers = {};
    
    // Add user avatar location marker
    if (provider.currentPosition != null && _avatarMarker != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            provider.currentPosition!.latitude, 
            provider.currentPosition!.longitude
          ),
          icon: _avatarMarker!,
          zIndex: 99,
        )
      );
    }
    
    // Add stations
    if (_stationAvailable != null && _stationInUse != null) {
      for (var station in provider.stations) {
        // Giả sử có connector rảnh thì isAvailable = true
        bool isAvailable = station.connectorTypes.any((c) => c.totalPorts > 0);
        
        markers.add(
          Marker(
            markerId: MarkerId(station.stationId.toString()),
            position: LatLng(station.latitude, station.longitude),
            icon: isAvailable ? _stationAvailable! : _stationInUse!,
            onTap: () {
              provider.fetchStationDetail(station.stationId);
            },
          )
        );
      }
    }

    return markers;
  }

  /// Zoom camera để vừa chứa cả user và trạm sạc đích
  Future<void> _zoomToFitRoute(StationProvider provider, LatLng destination) async {
    if (provider.currentPosition == null) return;
    final userLatLng = LatLng(
      provider.currentPosition!.latitude,
      provider.currentPosition!.longitude,
    );
    final bounds = LatLngBounds(
      southwest: LatLng(
        userLatLng.latitude < destination.latitude ? userLatLng.latitude : destination.latitude,
        userLatLng.longitude < destination.longitude ? userLatLng.longitude : destination.longitude,
      ),
      northeast: LatLng(
        userLatLng.latitude > destination.latitude ? userLatLng.latitude : destination.latitude,
        userLatLng.longitude > destination.longitude ? userLatLng.longitude : destination.longitude,
      ),
    );
    final c = await _controller.future;
    c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Widget _buildSearchBar() {
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
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.lightGray),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search station',
                hintStyle: TextStyle(color: AppColors.lightGray),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.black, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(StationProvider provider) {
    if (provider.isLoading && provider.stations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.selectedStationDetail != null) {
      final detail = provider.selectedStationDetail!;
      // Bottom Sheet (Ảnh 2)
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
            )
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
                    child: const Icon(Icons.close_rounded, color: AppColors.lightGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('In Use', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.gray),
                const SizedBox(width: 4),
                const Text('1.9 km', style: TextStyle(fontSize: 13, color: AppColors.gray)),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Chi Tiết',
                    style: AppButtonStyle.outlined,
                    onPressed: () {
                      Navigator.pushNamed(context, '/station_detail');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Đặt Lịch',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Horizontal List (Ảnh 1)
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
              final c = _controller.future;
              c.then((map) => map.animateCamera(CameraUpdate.newLatLng(LatLng(station.latitude, station.longitude))));
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
                  )
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
                            child: Image.network(station.imageUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.charging_station_rounded, color: AppColors.gray),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${station.distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available port: ${station.connectorTypes.length}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
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
            )
          ],
        ),
        child: Icon(icon, color: AppColors.black, size: 20),
      ),
    );
  }
}
