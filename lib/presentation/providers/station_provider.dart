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

  // ─── Filter state ─────────────────────────────
  double _radius = 10.0;
  double get radius => _radius;

  String? _connectorType;
  String? get connectorType => _connectorType;

  int? _minPowerKw;
  int? get minPowerKw => _minPowerKw;

  double? _minRating;
  double? get minRating => _minRating;

  /// Kiểm tra xem có bộ lọc nào đang được áp dụng không
  bool get hasActiveFilters =>
      _connectorType != null || _minPowerKw != null || _minRating != null;
  
  StationProvider(this._repository) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    // 1. Kiểm tra GPS có bật không — nếu tắt thì dùng vị trí mặc định
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = null; // Không hiện lỗi, chỉ dùng vị trí mặc định
      notifyListeners();
      return;
    }

    // 2. Kiểm tra quyền vị trí
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Hiển thị popup xin quyền truy cập vị trí
      permission = await Geolocator.requestPermission();
    }

    // 3. Nếu người dùng từ chối (denied hoặc deniedForever) → dùng vị trí mặc định
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // 4. Đã được cấp quyền → lấy vị trí thật của người dùng
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

  Future<void> fetchNearbyStations() async {
    if (_currentPosition == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.searchStations(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: _radius,
        connectorType: _connectorType,
        minPowerKw: _minPowerKw,
        minRating: _minRating,
      );
      _stations = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Áp dụng bộ lọc và tải lại danh sách trạm sạc
  Future<void> applyFilters({
    String? connectorType,
    int? minPowerKw,
    double? minRating,
  }) async {
    _connectorType = connectorType;
    _minPowerKw = minPowerKw;
    _minRating = minRating;
    await fetchNearbyStations();
  }

  /// Xóa tất cả bộ lọc và tải lại danh sách
  Future<void> clearFilters() async {
    _connectorType = null;
    _minPowerKw = null;
    _minRating = null;
    await fetchNearbyStations();
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
