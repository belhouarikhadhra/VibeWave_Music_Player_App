import 'package:flutter/material.dart';
import '../models/song_model.dart';

class PlayerState extends ChangeNotifier {
  static final PlayerState instance = PlayerState._();
  PlayerState._();

  List<Song> _playlist    = [];
  int        _currentIndex = 0;
  bool       _isPlaying   = false;

  List<Song> get playlist     => _playlist;
  int        get currentIndex => _currentIndex;
  bool       get isPlaying    => _isPlaying;

  Song? get currentSong =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  // Mettre à jour la playlist sans forcer de navigation
  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist      = songs;
    _currentIndex  = startIndex.clamp(0, songs.isEmpty ? 0 : songs.length - 1);
    notifyListeners();
  }

  // Changer uniquement l'index (appelé depuis notification)
  void setIndex(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void next() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    notifyListeners();
  }

  void previous() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    notifyListeners();
  }

  void setPlaying(bool value) {
    if (_isPlaying == value) return;
    _isPlaying = value;
    notifyListeners();
  }
}