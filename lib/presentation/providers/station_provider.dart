import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
    notifyListeners();
  }
}
