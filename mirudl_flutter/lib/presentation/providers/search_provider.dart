import 'package:flutter/foundation.dart';

import '../../data/models/anime_item.dart';
import '../../domain/usecases/search_anime.dart';

/// ViewModel for the Home/Search screen
class SearchProvider extends ChangeNotifier {
  final SearchAnime _searchAnime;

  List<AnimeItem> _results = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  SearchProvider(this._searchAnime);

  List<AnimeItem> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;

  /// Search anime by query
  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      _results = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await _searchAnime.call(query);
    } catch (e) {
      _error = e.toString();
      _results = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear search results
  void clear() {
    _results = [];
    _error = null;
    _query = '';
    notifyListeners();
  }
}
