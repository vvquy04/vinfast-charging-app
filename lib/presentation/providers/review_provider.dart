import 'package:flutter/material.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _repository;

  ReviewProvider(this._repository);

  List<ReviewModel> _reviews = [];
  List<ReviewModel> get reviews => _reviews;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReviews(int stationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedReviews = await _repository.getReviewsByStation(stationId);
      _reviews = fetchedReviews;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(int stationId, int rating, String? comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newReview = await _repository.submitReview(stationId, rating, comment);
      _reviews.insert(0, newReview); // Thêm vào đầu danh sách
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(int reviewId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteReview(reviewId);
      _reviews.removeWhere((review) => review.reviewId == reviewId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
