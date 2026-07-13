import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/dio_client.dart';
import 'auth_provider.dart';

class ChargingProvider extends ChangeNotifier {
  final DioClient _dio = DioClient();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Wallet
  double _balance = 0.0;
  double get balance => _balance;

  // Active Booking & Charging Session
  Map<String, dynamic>? _activeBooking;
  Map<String, dynamic>? get activeBooking => _activeBooking;

  Map<String, dynamic>? _activeSession;
  Map<String, dynamic>? get activeSession => _activeSession;

  List<dynamic> _bookingHistory = [];
  List<dynamic> get bookingHistory => _bookingHistory;

  List<dynamic> _chargingHistory = [];
  List<dynamic> get chargingHistory => _chargingHistory;

  // Timers
  Timer? _bookingTimer;
  int _bookingRemainingSeconds = 0;
  int get bookingRemainingSeconds => _bookingRemainingSeconds;

  Timer? _chargingSimTimer;
  double _simKwh = 0.0;
  double get simKwh => _simKwh;
  double _simCost = 0.0;
  double get simCost => _simCost;
  int _simPercent = 0;
  int get simPercent => _simPercent;
  int _chargingElapsedSeconds = 0;
  int get chargingElapsedSeconds => _chargingElapsedSeconds;

  // ═══════════════════════════════════════════════════
  // WALLET METHODS
  // ═══════════════════════════════════════════════════

  Future<void> fetchWalletBalance() async {
    try {
      final response = await _dio.dio.get('/api/users/profile');
      if (response.data != null && response.data['data'] != null) {
        _balance = (response.data['data']['balance'] ?? 0.0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching wallet balance: $e');
    }
  }

  Future<String?> createVnPayUrl(int amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.dio.post(
        '/api/payment/vnpay/create-url',
        data: {'amount': amount},
      );
      _isLoading = false;
      notifyListeners();
      if (response.data != null && response.data['success'] == true) {
        return response.data['paymentUrl'];
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating VNPay URL: $e');
    }
    return null;
  }

  Future<bool> mockDeposit(int amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.dio.post(
        '/api/payment/deposit',
        data: {'amount': amount},
      );
      _isLoading = false;
      if (response.data != null && response.data['success'] == true) {
        _balance = (response.data['data'] ?? 0.0).toDouble();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error doing mock deposit: $e');
    }
    return false;
  }

  // ═══════════════════════════════════════════════════
  // BOOKING METHODS
  // ═══════════════════════════════════════════════════

  Future<bool> createBooking(int stationId, String connectorType) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.dio.post(
        '/api/bookings/create',
        data: {
          'stationId': stationId,
          'connectorType': connectorType,
        },
      );
      _isLoading = false;
      if (response.data != null && response.data['success'] == true) {
        _activeBooking = response.data['data'];
        _startBookingCountdown();
        await fetchWalletBalance();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating booking: $e');
    }
    return false;
  }

  Future<bool> cancelActiveBooking() async {
    if (_activeBooking == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final bookingId = _activeBooking!['bookingId'];
      final response = await _dio.dio.post('/api/bookings/cancel/$bookingId');
      _isLoading = false;
      if (response.data != null && response.data['success'] == true) {
        _activeBooking = null;
        _stopBookingCountdown();
        await fetchWalletBalance();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error cancelling booking: $e');
    }
    return false;
  }

  Future<void> fetchActiveBooking() async {
    try {
      final response = await _dio.dio.get('/api/bookings/active');
      if (response.data != null && response.data['data'] != null && response.data['data'].isNotEmpty) {
        _activeBooking = response.data['data'];
        _startBookingCountdown();
      } else {
        _activeBooking = null;
        _stopBookingCountdown();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching active booking: $e');
    }
  }

  Future<void> fetchBookingHistory() async {
    try {
      final response = await _dio.dio.get('/api/bookings/history');
      if (response.data != null && response.data['data'] != null) {
        _bookingHistory = response.data['data'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching booking history: $e');
    }
  }

  void _startBookingCountdown() {
    _stopBookingCountdown();
    if (_activeBooking == null) return;

    final expiryTimeStr = _activeBooking!['expiryTime'];
    if (expiryTimeStr == null) return;

    final expiryTime = DateTime.parse(expiryTimeStr);
    final now = DateTime.now();
    _bookingRemainingSeconds = expiryTime.difference(now).inSeconds;

    if (_bookingRemainingSeconds <= 0) {
      _activeBooking = null;
      notifyListeners();
      return;
    }

    _bookingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_bookingRemainingSeconds > 0) {
        _bookingRemainingSeconds--;
        notifyListeners();
      } else {
        _activeBooking = null;
        _stopBookingCountdown();
        notifyListeners();
      }
    });
  }

  void _stopBookingCountdown() {
    _bookingTimer?.cancel();
    _bookingTimer = null;
    _bookingRemainingSeconds = 0;
  }

  // ═══════════════════════════════════════════════════
  // CHARGING SESSION METHODS
  // ═══════════════════════════════════════════════════

  Future<bool> startCharging(int stationId, String connectorType, double powerKw) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.dio.post(
        '/api/charging/start',
        data: {
          'stationId': stationId,
          'connectorType': connectorType,
          'powerKw': powerKw,
        },
      );
      _isLoading = false;
      if (response.data != null && response.data['success'] == true) {
        _activeSession = response.data['data'];
        _activeBooking = null; // Bắt đầu sạc thành công -> booking biến mất
        _stopBookingCountdown();
        _startChargingSimulation(powerKw);
        await fetchWalletBalance();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error starting charging: $e');
    }
    return false;
  }

  Future<bool> stopCharging() async {
    if (_activeSession == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final sessionId = _activeSession!['sessionId'];
      final response = await _dio.dio.post(
        '/api/charging/stop',
        data: {
          'sessionId': sessionId,
          'energyCharged': _simKwh,
        },
      );
      _isLoading = false;
      if (response.data != null && response.data['success'] == true) {
        _activeSession = null;
        _stopChargingSimulation();
        await fetchWalletBalance();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error stopping charging: $e');
    }
    return false;
  }

  Future<void> fetchActiveSession() async {
    try {
      final response = await _dio.dio.get('/api/charging/active');
      if (response.data != null && response.data['data'] != null && response.data['data'].isNotEmpty) {
        _activeSession = response.data['data'];
        final double powerKw = (_activeSession!['powerKw'] ?? 30.0).toDouble();
        
        // Tính toán lại mô phỏng dựa trên thời gian bắt đầu thực tế của phiên sạc
        final startTime = DateTime.parse(_activeSession!['startTime']);
        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        
        _simPercent = (20 + (elapsedSeconds * 0.1)).clamp(20, 100).toInt();
        _simKwh = (elapsedSeconds * (powerKw / 3600.0));
        _simCost = _simKwh * 3858.0;
        _chargingElapsedSeconds = elapsedSeconds;

        _startChargingSimulation(powerKw);
      } else {
        _activeSession = null;
        _stopChargingSimulation();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching active session: $e');
    }
  }

  Future<void> fetchChargingHistory() async {
    try {
      final response = await _dio.dio.get('/api/charging/history');
      if (response.data != null && response.data['data'] != null) {
        _chargingHistory = response.data['data'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching charging history: $e');
    }
  }

  void _startChargingSimulation(double powerKw) {
    _chargingSimTimer?.cancel();
    
    // Mỗi giây sạc xe được mô phỏng chạy tăng
    _chargingSimTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _chargingElapsedSeconds++;
      
      // Giả lập lượng điện năng tiêu thụ: powerKw (kW) / 3600 giây
      _simKwh += (powerKw / 3600.0);
      _simCost = _simKwh * 3858.0;
      
      // Giả lập phần trăm pin tăng dần từ 20%
      if (_simPercent < 100) {
        _simPercent = (20 + (_chargingElapsedSeconds * 0.1)).clamp(20, 100).toInt();
      }
      
      notifyListeners();
    });
  }

  void _stopChargingSimulation() {
    _chargingSimTimer?.cancel();
    _chargingSimTimer = null;
    _simKwh = 0.0;
    _simCost = 0.0;
    _simPercent = 0;
    _chargingElapsedSeconds = 0;
  }

  @override
  void dispose() {
    _bookingTimer?.cancel();
    _chargingSimTimer?.cancel();
    super.dispose();
  }
}
