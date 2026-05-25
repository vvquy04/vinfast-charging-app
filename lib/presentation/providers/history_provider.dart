import 'package:flutter/material.dart';
import '../../data/models/station_history_model.dart';
import '../../data/repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository;

  HistoryProvider(this._repository);

  List<StationHistoryModel> _historyList = [];
  List<StationHistoryModel> get historyList => _historyList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historyList = await _repository.getHistory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordVisit(int stationId) async {
    // Không cần set isLoading vì đây là tác vụ chạy ngầm
    try {
      await _repository.recordVisit(stationId);
      // Optional: Tải lại danh sách lịch sử nếu đang ở màn hình lịch sử
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
