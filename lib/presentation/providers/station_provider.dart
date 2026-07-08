import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/station_summary_model.dart';
import '../../data/models/station_detail_model.dart';
import '../../data/repositories/station_repository.dart';
import '../../data/services/upload_service.dart';

class StationProvider with ChangeNotifier {
  final StationRepository _repository;
  final UploadService _uploadService;

  StationProvider(this._repository, this._uploadService) {
    _initLocation();
  }

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

  /// Có đang dùng vị trí mặc định hay không (GPS tắt hoặc quyền bị từ chối)
  bool _usingDefaultLocation = false;
  bool get usingDefaultLocation => _usingDefaultLocation;

  // ─── Vị trí mặc định: Trung tâm Hà Nội (Hồ Hoàn Kiếm) ────
  static const double _defaultLatitude = 21.0285;
  static const double _defaultLongitude = 105.8542;

  // ─── Vị trí tìm kiếm hiện tại ────
  double? _searchLatitude;
  double? _searchLongitude;
  double? get searchLatitude => _searchLatitude;
  double? get searchLongitude => _searchLongitude;

  // ─── Vị trí đã fetch dữ liệu gần nhất ────
  double? _lastFetchedLatitude;
  double? _lastFetchedLongitude;

  // ─── Trạng thái bộ lọc ─────────────────────────────
  double _radius = 15.0;
  double get radius => _radius;

  String? _connectorType;
  String? get connectorType => _connectorType;

  int? _minPowerKw;
  int? get minPowerKw => _minPowerKw;

  int? _maxPowerKw;
  int? get maxPowerKw => _maxPowerKw;

  double? _minRating;
  double? get minRating => _minRating;

  // ─── Trạng thái xe người dùng (tự động lọc) ──────────
  String? _userVehicleModel;
  String? get userVehicleModel => _userVehicleModel;

  String? _userConnectorType;
  String? get userConnectorType => _userConnectorType;

  bool _isFilteringByVehicle = false;
  bool get isFilteringByVehicle => _isFilteringByVehicle;

  // ─── Trạng thái TOPSIS (Gợi ý thông minh) ──────────
  bool _useTopsis = false;
  bool get useTopsis => _useTopsis;

  Set<String> _activeTopsisFilters = {};
  Set<String> get activeTopsisFilters => _activeTopsisFilters;

  // Trọng số TOPSIS (tự động điều chỉnh theo bộ lọc đang chọn)
  double get weightDistance => _activeTopsisFilters.contains('distance') ? 5.0 : 1.0;
  double get weightPower => _activeTopsisFilters.contains('power') ? 5.0 : 1.0;
  double get weightOccupancy => _activeTopsisFilters.contains('occupancy') ? 5.0 : 1.0;
  double get weightRating => _activeTopsisFilters.contains('rating') ? 5.0 : 1.0;

  // ─── Trạng thái Check-in ──────────
  bool _isCheckinLoading = false;
  bool get isCheckinLoading => _isCheckinLoading;

  String? _checkinMessage;
  String? get checkinMessage => _checkinMessage;

  /// Kiểm tra xem có bộ lọc nào đang được áp dụng không
  bool get hasActiveFilters =>
      _connectorType != null || _minPowerKw != null || _minRating != null || _isFilteringByVehicle || _useTopsis;
  
  // Constructor initialized above

  // ═══════════════════════════════════════════════════
  // TOPSIS FILTERS
  // ═══════════════════════════════════════════════════

  /// Bật/tắt một bộ lọc TOPSIS (distance, power, occupancy, rating)
  void toggleTopsisFilter(String filter) {
    if (_activeTopsisFilters.contains(filter)) {
      _activeTopsisFilters.remove(filter);
    } else {
      _activeTopsisFilters.add(filter);
    }

    // Tự động bật/tắt TOPSIS dựa trên số lượng filter đang chọn
    _useTopsis = _activeTopsisFilters.isNotEmpty;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    notifyListeners();
    fetchNearbyStations();
  }

  /// Xóa toàn bộ TOPSIS filters
  void clearTopsisFilters() {
    _activeTopsisFilters = {};
    _useTopsis = false;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    notifyListeners();
    fetchNearbyStations();
  }

  // ═══════════════════════════════════════════════════
  // CHECK-IN
  // ═══════════════════════════════════════════════════

  /// Gọi API check-in tại trạm sạc
  Future<bool> checkinStation(int stationId, String status, {File? imageFile}) async {
    _isCheckinLoading = true;
    _checkinMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadService.uploadCheckin(imageFile);
      }

      final message = await _repository.checkinStation(stationId, status, imageUrl: imageUrl);
      _checkinMessage = message;

      // Tải lại chi tiết trạm sạc để cập nhật trạng thái
      await fetchStationDetail(stationId);

      // Buộc tải lại danh sách trạm sạc
      _lastFetchedLatitude = null;
      _lastFetchedLongitude = null;
      await fetchNearbyStations();

      return true;
    } catch (e) {
      _checkinMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isCheckinLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // LOCATION & SEARCH (giữ nguyên logic cũ)
  // ═══════════════════════════════════════════════════

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS disabled - using default location (Hanoi)');
        _useDefaultLocationAndFetch();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied - using default location (Hanoi)');
        _useDefaultLocationAndFetch();
        return;
      }

      debugPrint('Location permission granted - fetching current location...');
      await moveToCurrentLocation();
    } catch (e) {
      debugPrint('Error initializing location: $e - using default location');
      _useDefaultLocationAndFetch();
    }
  }

  void _useDefaultLocationAndFetch() {
    _usingDefaultLocation = true;
    _currentPosition = Position(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _errorMessage = null;
    notifyListeners();
    fetchNearbyStations();
  }

  Future<void> moveToCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (_currentPosition == null) {
          _useDefaultLocationAndFetch();
        }
        return;
      }

      // 1. Lấy vị trí đã biết gần nhất trước để hiển thị ngay lập tức (tránh chờ lâu)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _currentPosition = lastPosition;
        _searchLatitude = lastPosition.latitude;
        _searchLongitude = lastPosition.longitude;
        _usingDefaultLocation = false;
        notifyListeners();
        fetchNearbyStations(); // Tải trạm sạc ngay lập tức với vị trí cũ trước
      }

      // 2. Chạy ngầm lấy vị trí GPS cập nhật với giới hạn tối đa 3 giây
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium sẽ trả về nhanh hơn rất nhiều so với High
        timeLimit: const Duration(seconds: 3),    // Quá 3 giây sẽ nhảy vào catchError
      ).catchError((e) {
        debugPrint('Timeout lấy GPS chính xác - sử dụng vị trí gần nhất: $e');
        if (lastPosition != null) return lastPosition;
        // Nếu hoàn toàn chưa có vị trí nào, trả về vị trí mặc định Hà Nội để tránh lỗi
        return Position(
          latitude: _defaultLatitude,
          longitude: _defaultLongitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });

      _currentPosition = position;
      _usingDefaultLocation = (position.latitude == _defaultLatitude && position.longitude == _defaultLongitude);
      
      _searchLatitude = position.latitude;
      _searchLongitude = position.longitude;
      _lastFetchedLatitude = null;
      _lastFetchedLongitude = null;

      debugPrint('Current location: ${position.latitude}, ${position.longitude}');
      await fetchNearbyStations();
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (_currentPosition == null) {
        _useDefaultLocationAndFetch();
      } else {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateSearchPosition(double latitude, double longitude) async {
    _searchLatitude = latitude;
    _searchLongitude = longitude;
    await fetchNearbyStations();
  }

  double getDistanceToUser(double stationLat, double stationLng) {
    final double userLat = _currentPosition?.latitude ?? _defaultLatitude;
    final double userLng = _currentPosition?.longitude ?? _defaultLongitude;
    
    final double distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      stationLat,
      stationLng,
    );
    return distanceInMeters / 1000.0;
  }

  String? _mapToDbConnector(String? uiConnector) {
    if (uiConnector == null) return null;
    final clean = uiConnector.toLowerCase();
    if (clean.contains('ccs2')) return 'CCS2';
    if (clean.contains('type 2') || clean.contains('type2') || clean.contains('ac')) return 'AC';
    if (clean.contains('chademo')) return 'CHAdeMO';
    if (clean.contains('dc')) return 'DC';
    return uiConnector;
  }

  Future<void> fetchNearbyStations() async {
    final double searchLat = _searchLatitude ?? _currentPosition?.latitude ?? _defaultLatitude;
    final double searchLng = _searchLongitude ?? _currentPosition?.longitude ?? _defaultLongitude;
    
    if (_lastFetchedLatitude != null && _lastFetchedLongitude != null) {
      final double distanceMoved = Geolocator.distanceBetween(
        _lastFetchedLatitude!,
        _lastFetchedLongitude!,
        searchLat,
        searchLng,
      );
      if (distanceMoved < 200) {
        debugPrint('Movement too small ($distanceMoved m) - skipping API fetch');
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Searching charging stations: lat=$searchLat, lng=$searchLng, radius=$_radius km, topsis=$_useTopsis');
      
      final rawConnector = _isFilteringByVehicle ? (_connectorType ?? _userConnectorType) : _connectorType;
      final dbConnectorType = _mapToDbConnector(rawConnector);

      final data = await _repository.searchStations(
        latitude: searchLat,
        longitude: searchLng,
        radius: _radius,
        connectorType: dbConnectorType,
        minPowerKw: _minPowerKw,
        maxPowerKw: _maxPowerKw,
        minRating: _minRating,
        useTopsis: _useTopsis,
        weightDistance: weightDistance,
        weightPower: weightPower,
        weightOccupancy: weightOccupancy,
        weightRating: weightRating,
      );
      _stations = data;
      _lastFetchedLatitude = searchLat;
      _lastFetchedLongitude = searchLng;
      debugPrint('Found ${data.length} charging stations');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error finding charging stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    String? connectorType,
    int? minPowerKw,
    int? maxPowerKw,
    double? minRating,
  }) async {
    _connectorType = connectorType;
    _minPowerKw = minPowerKw;
    _maxPowerKw = maxPowerKw;
    _minRating = minRating;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    await fetchNearbyStations();
  }

  Future<void> clearFilters() async {
    _connectorType = null;
    _minPowerKw = null;
    _maxPowerKw = null;
    _minRating = null;
    _isFilteringByVehicle = false;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    await fetchNearbyStations();
  }

  void setUserVehicle(String? vehicleModel, String? connectorType) {
    _userVehicleModel = vehicleModel;
    _userConnectorType = connectorType;
    if (connectorType != null && connectorType.isNotEmpty) {
      _isFilteringByVehicle = true;
      _lastFetchedLatitude = null;
      _lastFetchedLongitude = null;
      fetchNearbyStations();
    }
    notifyListeners();
  }

  Future<void> clearVehicleFilter() async {
    _isFilteringByVehicle = false;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    await fetchNearbyStations();
  }

  Future<void> enableVehicleFilter() async {
    if (_userConnectorType != null) {
      _isFilteringByVehicle = true;
      _lastFetchedLatitude = null;
      _lastFetchedLongitude = null;
      await fetchNearbyStations();
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
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    fetchNearbyStations();
  }

  void clearSelection() {
    _selectedStationDetail = null;
    notifyListeners();
  }
}
