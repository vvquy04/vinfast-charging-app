import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/station_summary_model.dart';
import '../../data/models/station_detail_model.dart';
import '../../data/repositories/station_repository.dart';

class StationProvider with ChangeNotifier {
  final StationRepository _repository;

  List<StationSummaryModel> _stations = [];
  List<StationSummaryModel> get stations => _stations;

  StationDetailModel? _selectedStationDetail;
  StationDetailModel? get selectedStationDetail => _selectedStationDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Search logic variables
  double _radius = 10.0;

  // ─── Routing state ──────────────────────────────
  Set<Polyline> _routePolylines = {};
  Set<Polyline> get routePolylines => _routePolylines;

  bool _isRouting = false;
  bool get isRouting => _isRouting;

  StationProvider(this._repository) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permissions are denied';
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permissions are permanently denied.';
      notifyListeners();
      return;
    } 

    moveToCurrentLocation();
  }

  Future<void> moveToCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _currentPosition = position;
      await fetchNearbyStations(); // Search based on new location
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyStations({String? connectorType}) async {
    if (_currentPosition == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.searchStations(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _radius,
        connectorType: connectorType,
      );
      _stations = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStationDetail(int stationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detail = await _repository.getStationDetail(stationId);
      _selectedStationDetail = detail;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateRadius(double newRadius) {
    _radius = newRadius;
    fetchNearbyStations();
  }

  void clearSelection() {
    _selectedStationDetail = null;
    _routePolylines = {};
    _isRouting = false;
    notifyListeners();
  }

  // ─── Routing: vẽ đường đi đến trạm sạc ────────
  Future<void> drawRoute(LatLng destination) async {
    if (_currentPosition == null) return;

    _isRouting = true;
    notifyListeners();

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: AppConfig.googleMapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          destination: PointLatLng(
            destination.latitude,
            destination.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polyCoords = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route_to_station'),
            color: const Color(0xFF1A1A2E),
            width: 5,
            points: polyCoords,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      } else {
        _errorMessage = result.errorMessage ?? 'Không tìm được đường đi';
      }
    } catch (e) {
      _errorMessage = 'Lỗi khi tìm đường: ${e.toString()}';
    } finally {
      _isRouting = false;
      notifyListeners();
    }
  }

  void clearRoute() {
    _routePolylines = {};
    _isRouting = false;
    notifyListeners();
  }
}
