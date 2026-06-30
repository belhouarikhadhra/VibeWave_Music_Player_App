import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/player_state.dart';
import '../services/music_channel.dart';
import 'music_player_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Song> playlist = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  static const Color _bg = Color(0xFF8BA7BC);
  static const Color _cardLight = Color(0xFF9BB5C8);
  static const Color _accent = Color(0xFF4A7A96);

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    bool granted = false;
    if (await Permission.audio.request().isGranted) {
      granted = true;
    } else if (await Permission.storage.request().isGranted) {
      granted = true;
    }
    if (granted) {
      await _scanAudioFiles();
    } else {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
        playlist = _defaultPlaylist();
      });
    }
    // Push playlist into PlayerState so notification callbacks work
    PlayerState.instance.setPlaylist(playlist);
  }

  Future<void> _scanAudioFiles() async {
    try {
      final List<Song> found = [];
      final dir = Directory('/storage/emulated/0/Music');
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') ||
                path.endsWith('.m4a') ||
                path.endsWith('.aac') ||
                path.endsWith('.ogg') ||
                path.endsWith('.flac')) {
              final name = entity.uri.pathSegments.last;
              final title = name.replaceAll(
                RegExp(r'\.(mp3|m4a|aac|ogg|flac)$', caseSensitive: false),
                '',
              );
              found.add(
                Song(
                  title: title,
                  artist: 'Artiste inconnu',
                  imageUrl: '',
                  audioPath: entity.path,
                  description: '',
                ),
              );
            }
          }
        }
      }
      setState(() {
        playlist = found.isEmpty ? _defaultPlaylist() : found;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        playlist = _defaultPlaylist();
        _isLoading = false;
      });
    }
    PlayerState.instance.setPlaylist(playlist);
  }

  List<Song> _defaultPlaylist() => [
    Song(
      title: "Birdie",
      artist: "Kota The Friend",
      imageUrl:
          "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500",
      audioPath: "assets/audio/audio1.mp3",
      description: "Chill music",
    ),
    Song(
      title: "Blinding Lights",
      artist: "The Weeknd",
      imageUrl:
          "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=500",
      audioPath: "assets/audio/test.mp3",
      description: "80s style",
    ),
    Song(
      title: "Track 6",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1511376777868-611b54f68947?q=80&w=500",
      audioPath: "assets/audio/6.mp3",
      description: "Dynamic",
    ),
    Song(
      title: "AD Beat",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=500",
      audioPath: "assets/audio/ad.mp3",
      description: "Modern beat",
    ),
    Song(
      title: "BO Track",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1497032205916-ac775f0649ae?q=80&w=500",
      audioPath: "assets/audio/bo.mp3",
      description: "Calm",
    ),
    Song(
      title: "Cosas",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2?q=80&w=500",
      audioPath: "assets/audio/cosas.mp3",
      description: "Emotional",
    ),
    Song(
      title: "Dre",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=500",
      audioPath: "assets/audio/dre.mp3",
      description: "Hip-hop",
    ),
    Song(
      title: "GM Track",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1510915228340-29c85a43dcfe?q=80&w=500",
      audioPath: "assets/audio/gmp3.mp3",
      description: "Energetic",
    ),
    Song(
      title: "ID Track",
      artist: "Unknown",
      imageUrl:
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=500",
      audioPath: "assets/audio/id.mp3",
      description: "Mysterious",
    ),
  ];

  void _onSongTap(int index) async {
    final song = playlist[index];

    // Update PlayerState with new index BEFORE starting service
    PlayerState.instance.setPlaylist(playlist, startIndex: index);

    // Start service with the full playlist so notification controls work
    await MusicChannel.startService(
      audioPath: song.audioPath,
      title: song.title,
      artist: song.artist,
      playlist: playlist, // <-- pass full playlist
      playlistIndex: index, // <-- pass correct index
    );
    PlayerState.instance.setPlaying(true);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PlayerState>();
    final currentSong = ps.currentSong;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "VibeWave",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        "${playlist.length} songs",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _cardLight,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(4, 4),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          offset: const Offset(-4, -4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Permission banner ────────────────────────────────────
            if (_permissionDenied)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Accès refusé — playlist par défaut",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      GestureDetector(
                        onTap: openAppSettings,
                        child: Text(
                          "Paramètres",
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Now Playing mini bar ─────────────────────────────────
            // FIX 2: Only show mini bar, no auto-redirect on rebuild.
            // User must tap it intentionally to go to player.
            if (currentSong != null && ps.isPlaying)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.equalizer_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentSong.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: playlist.length,
                      itemBuilder: (context, index) {
                        final song = playlist[index];
                        final isAsset = song.audioPath.startsWith('assets/');
                        final isCurrentlyPlaying =
                            ps.isPlaying &&
                            ps.currentSong?.audioPath == song.audioPath;

                        return GestureDetector(
                          onTap: () => _onSongTap(index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentlyPlaying ? _accent : _cardLight,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  offset: const Offset(4, 4),
                                  blurRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  offset: const Offset(-3, -3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: isCurrentlyPlaying
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : _accent,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isAsset && song.imageUrl.isNotEmpty
                                        ? Image.network(
                                            song.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.music_note,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title + artist
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Playing indicator or index
                                if (isCurrentlyPlaying)
                                  const Icon(
                                    Icons.equalizer_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                else
                                  Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
