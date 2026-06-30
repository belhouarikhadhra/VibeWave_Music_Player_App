import 'package:flutter/services.dart';
import '../models/song_model.dart';

class MusicChannel {
  static const _channel = MethodChannel('com.example.p1/music_service');

  static Function()? onNext;
  static Function()? onPrevious;
  static Function()? onStop;
  static Function()? onPause;
  static Function()? onOpenPlayer;

  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNext':
          onNext?.call();
          break;
        case 'onPrevious':
          onPrevious?.call();
          break;
        case 'onStop':
          onStop?.call();
          break;
        case 'onPause':
          onPause?.call();
          break;
        case 'openPlayer':
          onOpenPlayer?.call();
          break;
      }
    });
  }

  static Future<void> startService({
    required String audioPath,
    required String title,
    String artist = '',
    List<Song>? playlist,
    int playlistIndex = 0,
  }) async {
    final params = <String, dynamic>{
      'audioPath': audioPath,
      'title': title,
      'artist': artist,
    };
    if (playlist != null && playlist.isNotEmpty) {
      params['playlistPaths'] = playlist.map((s) => s.audioPath).toList();
      params['playlistTitles'] = playlist.map((s) => s.title).toList();
      params['playlistArtists'] = playlist.map((s) => s.artist).toList();
      params['playlistIndex'] = playlistIndex;
    }
    await _channel.invokeMethod('startService', params);
  }

  static Future<bool> togglePlayPause() async =>
      await _channel.invokeMethod<bool>('togglePlayPause') ?? false;

  static Future<void> stopService() async =>
      await _channel.invokeMethod('stopService');

  static Future<bool> isPlayingNow() async =>
      await _channel.invokeMethod<bool>('isPlaying') ?? false;

  static Future<List<int>> getPosition() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getPosition');
    if (result == null) return [0, 0];
    return [result[0] as int, result[1] as int];
  }

  static Future<void> seekTo(int positionMs) async =>
      await _channel.invokeMethod('seekTo', {'position': positionMs});

  static Future<void> setLooping(bool looping) async =>
      await _channel.invokeMethod('setLooping', {'looping': looping});
}
