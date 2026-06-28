import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/station_history_model.dart';
import '../../data/repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository;

  HistoryProvider(this._repository) {
    _loadFavorites();
    loadReviewedStations();
  }

  List<StationHistoryModel> _historyList = [];
  List<StationHistoryModel> get historyList => _historyList;

  final Set<int> _favoriteStationIds = {};
  Set<int> get favoriteStationIds => _favoriteStationIds;

  final Set<int> _reviewedStationIds = {};
  Set<int> get reviewedStationIds => _reviewedStationIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const String _favPrefKey = 'favorite_station_ids';
  static const String _reviewedPrefKey = 'reviewed_station_ids';

  /// Tải danh sách đã bình luận từ SharedPreferences
  Future<void> loadReviewedStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? reviewedList = prefs.getStringList(_reviewedPrefKey);
      if (reviewedList != null) {
        _reviewedStationIds.clear();
        _reviewedStationIds.addAll(reviewedList.map((id) => int.parse(id)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách đã bình luận: $e');
    }
  }

  /// Đánh dấu trạm sạc đã được bình luận
  Future<void> markAsReviewed(int stationId) async {
    if (!_reviewedStationIds.contains(stationId)) {
      _reviewedStationIds.add(stationId);
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _reviewedPrefKey,
          _reviewedStationIds.map((id) => id.toString()).toList(),
        );
      } catch (e) {
        debugPrint('Lỗi lưu danh sách đã bình luận: $e');
      }
    }
  }

  /// Tải danh sách yêu thích từ SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? favList = prefs.getStringList(_favPrefKey);
      if (favList != null) {
        _favoriteStationIds.clear();
        _favoriteStationIds.addAll(favList.map((id) => int.parse(id)));
        _sortHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách yêu thích: $e');
    }
  }

  /// Bật/Tắt trạng thái yêu thích của trạm sạc
  Future<void> toggleFavorite(int stationId) async {
    try {
      if (_favoriteStationIds.contains(stationId)) {
        _favoriteStationIds.remove(stationId);
      } else {
        _favoriteStationIds.add(stationId);
      }
      _sortHistory();
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favPrefKey,
        _favoriteStationIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Lỗi lưu danh sách yêu thích: $e');
    }
  }

  /// Kiểm tra xem trạm sạc có phải là yêu thích không
  bool isFavorite(int stationId) {
    return _favoriteStationIds.contains(stationId);
  }

  /// Sắp xếp lịch sử: Yêu thích lên đầu, sau đó sắp xếp theo thời gian xem gần nhất
  void _sortHistory() {
    _historyList.sort((a, b) {
      final aFav = _favoriteStationIds.contains(a.stationId);
      final bFav = _favoriteStationIds.contains(b.stationId);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return b.lastVisited.compareTo(a.lastVisited);
    });
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historyList = await _repository.getHistory();
      _sortHistory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordVisit(int stationId) async {
    try {
      await _repository.recordVisit(stationId);
    } catch (e) {
      debugPrint('Lỗi ghi nhận lịch sử: $e');
    }
  }

  Future<bool> deleteHistory(int historyId) async {
    try {
      await _repository.deleteHistory(historyId);
      _historyList.removeWhere((item) => item.historyId == historyId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
