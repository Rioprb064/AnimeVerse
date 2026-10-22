import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime.dart';
import '../data/dummy_data.dart';

class AppStateProvider extends ChangeNotifier{
  //Data yang ingin disimpan di sini
  List<Anime> _favorites = [];

  static const String _storageKey = 'favorite_anime_list';

  AppStateProvider(){
    _loadFavorites();
  }

  // getters
  List<Anime> get favorites => _favorites;

  // STATE BARU: genre yang dipilih (default "All")
  String _selectedGenre = "All";

  // GETTER BARU
  String get selectedGenre => _selectedGenre;

  // METHOD BARU: mengubah genre yang dipilih
  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  //STATE BARU: query pencarian (dipisah per layar)
  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";

  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  //Update query pencarian HomeScreen
  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();
  }

  //Update query pencarian FavoriteScreen
  void setFavoriteSearchQuery(String query) {
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  //helper functions untuk tahu apakah anime sudah ada di favorite atau belum
  bool isFavorite(String id) {
    return _favorites.any((anime) => anime.id == id);
  }

  void toggleFavorite (Anime anime){
    if (isFavorite(anime.id)){
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  void addFavorite(Anime anime){
    if(!isFavorite(anime.id)){
      _favorites.add(anime);
      _saveFavorites(); //tambahkan, untuk menyimpan data ke SharedPreferences
      notifyListeners();
    }
  }

  // fungsi untuk menambahkan dan menghapus anime dari daftar favorit
  void removeFavorite(String animeId){
    _favorites.removeWhere((anime) => anime.id == animeId);
    _saveFavorites(); //untuk menyimpan data ke sharedpreferences
    notifyListeners();
  }

  // ambil daftar anime home yang sudah difilter
  List<Anime> getFilteredAnimeForHome() {
    List<Anime> result = DummyData.animeList; //mulai dari daftar favorit

    // terapkan filter genre
    if (_selectedGenre != "All") {
      result = result.where((anime) {
        //pecah "action, adventure" menjadi ["action", "adventure:]
        final genres = anime.genre.split(',').map((g) => g.trim()).toList();
        //cek apakah anime punya genre yang dipilih
        return genres.contains(_selectedGenre);
      }).toList();
    }

    // terapkan filter search (setelah filter genre)
    if (_homeSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title
            .toLowerCase()
            .contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  // Ambil daftar anime favorit yang sudah difilter
  List<Anime> getFilteredFavorites() {
    List<Anime> result = _favorites;

    // Terapkan filter pencarian favorit
    if (_favoriteSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title
            .toLowerCase()
            .contains(_favoriteSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      //List Anime
      final List<Map<String, dynamic>> favoritesJson = _favorites.map((anime) =>
          anime.toJson()).toList();

      //List Map di encode ke JSON string
      await prefs.setString(_storageKey, jsonEncode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        final List<dynamic> decoded = jsonDecode(favoritesJson);

        _favorites = decoded
            .map((item) => Anime.fromJson(item as Map<String, dynamic>))
            .toList();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }
}