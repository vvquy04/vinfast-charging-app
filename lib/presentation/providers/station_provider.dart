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

  /// Có đang dùng vị trí mặc định hay không (GPS tắt hoặc quyền bị từ chối)
  bool _usingDefaultLocation = false;
  bool get usingDefaultLocation => _usingDefaultLocation;

  // ─── Vị trí mặc định: Trung tâm Hà Nội (Hồ Hoàn Kiếm) ────
  static const double _defaultLatitude = 21.0285;
  static const double _defaultLongitude = 105.8542;

  // ─── Vị trí tìm kiếm hiện tại (theo chuyển động bản đồ hoặc vị trí hiện tại) ────
  double? _searchLatitude;
  double? _searchLongitude;
  double? get searchLatitude => _searchLatitude;
  double? get searchLongitude => _searchLongitude;

  // ─── Vị trí đã fetch dữ liệu gần nhất (để tối ưu hóa, tránh gọi API liên tục khi di chuyển nhỏ) ────
  double? _lastFetchedLatitude;
  double? _lastFetchedLongitude;

  // ─── Trạng thái bộ lọc ─────────────────────────────
  double _radius = 200.0; // 200km để bao phủ toàn bộ khu vực miền Bắc (gồm Quảng Ninh, Hải Phòng, Hà Nội)
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

  /// Kiểm tra xem có bộ lọc nào đang được áp dụng không
  bool get hasActiveFilters =>
      _connectorType != null || _minPowerKw != null || _minRating != null || _isFilteringByVehicle;
  
  StationProvider(this._repository) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // 1. Kiểm tra GPS có bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS disabled - using default location (Hanoi)');
        _useDefaultLocationAndFetch();
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
        debugPrint('Location permission denied - using default location (Hanoi)');
        _useDefaultLocationAndFetch();
        return;
      }

      // 4. Đã được cấp quyền → lấy vị trí thật của người dùng
      debugPrint('Location permission granted - fetching current location...');
      await moveToCurrentLocation();
    } catch (e) {
      debugPrint('Error initializing location: $e - using default location');
      _useDefaultLocationAndFetch();
    }
  }

  /// Sử dụng vị trí mặc định (Hà Nội) và tải danh sách trạm sạc
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
      // Kiểm tra quyền trước khi lấy vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Quyền bị từ chối → dùng vị trí mặc định
        if (_currentPosition == null) {
          _useDefaultLocationAndFetch();
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      _usingDefaultLocation = false;
      
      // Reset vị trí tìm kiếm và vị trí fetch gần nhất về vị trí thực của người dùng
      _searchLatitude = position.latitude;
      _searchLongitude = position.longitude;
      _lastFetchedLatitude = null;
      _lastFetchedLongitude = null;

      debugPrint('Current location: ${position.latitude}, ${position.longitude}');
      await fetchNearbyStations();
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Nếu chưa có vị trí nào → dùng vị trí mặc định
      if (_currentPosition == null) {
        _useDefaultLocationAndFetch();
      } else {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Cập nhật vị trí tìm kiếm khi người dùng di chuyển bản đồ
  Future<void> updateSearchPosition(double latitude, double longitude) async {
    _searchLatitude = latitude;
    _searchLongitude = longitude;
    await fetchNearbyStations();
  }

  /// Tính khoảng cách từ vị trí người dùng (hoặc vị trí mặc định) tới trạm sạc (đơn vị: km)
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
    
    // Tối ưu hóa: Nếu vị trí tìm kiếm mới cách vị trí fetch gần nhất dưới 200m thì bỏ qua không fetch lại
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
      debugPrint('Searching charging stations: lat=$searchLat, lng=$searchLng, radius=$_radius km');
      
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

  /// Áp dụng bộ lọc và tải lại danh sách trạm sạc
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

  /// Xóa tất cả bộ lọc và tải lại danh sách
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

  /// Thiết lập thông tin xe người dùng và tự động bật lọc theo xe
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

  /// Tắt bộ lọc theo xe nhưng giữ lại thông tin xe
  Future<void> clearVehicleFilter() async {
    _isFilteringByVehicle = false;
    _lastFetchedLatitude = null;
    _lastFetchedLongitude = null;
    await fetchNearbyStations();
  }

  /// Bật lại bộ lọc theo xe
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

