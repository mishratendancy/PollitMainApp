import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../services/firestore_service.dart';

class FeedProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Poll> _polls = [];
  bool _isLoading = true;
  String? _error;

  List<Poll> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FeedProvider() {
    _initGlobalFeed();
  }

  void _initGlobalFeed() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getGlobalFeedStream().listen(
      (pollList) {
        _polls = pollList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }
}
