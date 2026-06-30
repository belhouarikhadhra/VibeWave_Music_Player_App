import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/song_model.dart';
import '../database/favorites_db.dart';
import 'favorites_screen.dart';
import '../main.dart';
import '../services/music_channel.dart';
import '../services/player_state.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver, RouteAware, TickerProviderStateMixin {
  List<Song> favoriteSongs = [];
  int _positionMs = 0;
  int _durationMs = 0;
  Timer? _syncTimer;

  late AnimationController _vinylController;
  late AnimationController _waveController;

  StreamSubscription? _accelSubscription;
  DateTime? _lastShake;
  static const double _shakeThreshold = 15.0;

  static const Color _bg = Color(0xFF8BA7BC);
  static const Color _cardLight = Color(0xFF9BB5C8);
  static const Color _cardDark = Color(0xFF7A95A8);
  static const Color _accent = Color(0xFF4A7A96);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadFavorites();
    _startSyncTimer();
    _startAccelerometer();

    // Sync vinyl with current play state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (PlayerState.instance.isPlaying) {
        _vinylController.repeat();
      }
    });
  }

  void _startAccelerometer() {
    _accelSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((event) {
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          if (magnitude > _shakeThreshold) {
            final now = DateTime.now();
            if (_lastShake == null ||
                now.difference(_lastShake!).inMilliseconds > 1000) {
              _lastShake = now;
              _onShakeDetected();
            }
          }
        });
  }

  void _onShakeDetected() async {
    final ps = PlayerState.instance;
    if (ps.playlist.isEmpty) return;
    await MusicChannel.togglePlayPause();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      final playing = await MusicChannel.isPlayingNow();
      ps.setPlaying(playing);
      if (!playing)
        _vinylController.stop();
      else
        _vinylController.repeat();
    }
  }

  Future<void> _loadFavorites() async {
    final saved = await FavoritesDB.instance.fetchAll();
    if (mounted) setState(() => favoriteSongs = saved);
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      try {
        final playing = await MusicChannel.isPlayingNow();
        final pos = await MusicChannel.getPosition();
        if (mounted) {
          setState(() {
            _positionMs = pos[0];
            _durationMs = pos[1];
          });
          PlayerState.instance.setPlaying(playing);
          if (playing && !_vinylController.isAnimating) {
            _vinylController.repeat();
          } else if (!playing && _vinylController.isAnimating) {
            _vinylController.stop();
          }
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && mounted) {
      final playing = await MusicChannel.isPlayingNow();
      PlayerState.instance.setPlaying(playing);
    }
  }

  @override
  void didPopNext() async {
    final playing = await MusicChannel.isPlayingNow();
    PlayerState.instance.setPlaying(playing);
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _waveController.dispose();
    _syncTimer?.cancel();
    _accelSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _togglePlayPause() async {
    final ps = PlayerState.instance;
    if (ps.playlist.isEmpty) return;

    if (!ps.isPlaying) {
      final song = ps.currentSong!;
      await MusicChannel.startService(
        audioPath: song.audioPath,
        title: song.title,
        artist: song.artist,
      );
      ps.setPlaying(true);
      _vinylController.repeat();
    } else {
      await MusicChannel.togglePlayPause();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        final playing = await MusicChannel.isPlayingNow();
        ps.setPlaying(playing);
        if (!playing)
          _vinylController.stop();
        else
          _vinylController.repeat();
      }
    }
  }

  void _nextSong() async {
    final ps = PlayerState.instance;
    if (ps.playlist.isEmpty) return;
    ps.next();
    setState(() {
      _positionMs = 0;
      _durationMs = 0;
    });
    if (ps.isPlaying) {
      final song = ps.currentSong!;
      await MusicChannel.startService(
        audioPath: song.audioPath,
        title: song.title,
        artist: song.artist,
      );
    }
  }

  void _previousSong() async {
    final ps = PlayerState.instance;
    if (ps.playlist.isEmpty) return;
    ps.previous();
    setState(() {
      _positionMs = 0;
      _durationMs = 0;
    });
    if (ps.isPlaying) {
      final song = ps.currentSong!;
      await MusicChannel.startService(
        audioPath: song.audioPath,
        title: song.title,
        artist: song.artist,
      );
    }
  }

  String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
        "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  Widget _buildNeumorphicButton({
    required Widget child,
    VoidCallback? onTap,
    GestureLongPressCallback? onLongPress,
    double size = 52,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: size,
        height: size,
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
        child: Center(child: child),
      ),
    );
  }

  Widget _buildVinylDisc(Song? currentSong) {
    final isAsset = currentSong?.audioPath.startsWith('assets/') ?? true;

    return AnimatedBuilder(
      animation: _vinylController,
      builder: (_, child) => Transform.rotate(
        angle: _vinylController.value * 2 * pi,
        child: child,
      ),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(8, 8),
              blurRadius: 25,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              offset: const Offset(-6, -6),
              blurRadius: 15,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(
              4,
              (i) => Container(
                width: 220 - i * 25.0,
                height: 220 - i * 25.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06 + i * 0.02),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            ClipOval(
              child: Container(
                width: 90,
                height: 90,
                color: _accent,
                child: isAsset && (currentSong?.imageUrl.isNotEmpty ?? false)
                    ? Image.network(
                        currentSong!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PlayerState>();
    final currentSong = ps.currentSong;
    final isPlaying = ps.isPlaying;
    final isFavorite =
        currentSong != null && favoriteSongs.contains(currentSong);
    final double maxSlider = _durationMs > 0 ? _durationMs.toDouble() : 1.0;
    final double sliderVal = _positionMs.toDouble().clamp(0.0, maxSlider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNeumorphicButton(
                      size: 44,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          "VibeWave",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          "NOW PLAYING",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Main card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _cardLight,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(8, 8),
                        blurRadius: 20,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        offset: const Offset(-6, -6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildVinylDisc(currentSong),
                      const SizedBox(height: 24),
                      Text(
                        "- ${currentSong?.title ?? 'No Song'} -",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentSong?.artist ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 20),

                      // Progress bar
                      Row(
                        children: [
                          Text(
                            _formatMs(_positionMs),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Slider(
                                  min: 0,
                                  max: maxSlider,
                                  value: sliderVal,
                                  onChanged: (v) async {
                                    setState(() => _positionMs = v.toInt());
                                    await MusicChannel.seekTo(v.toInt());
                                  },
                                ),
                              ),
                            ),
                          ),
                          Text(
                            _formatMs(_durationMs),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(width: 10),
                          _buildNeumorphicButton(
                            size: 46,
                            onTap: () async {
                              if (currentSong == null) return;
                              if (isFavorite) {
                                await FavoritesDB.instance.delete(
                                  currentSong.audioPath,
                                );
                                setState(
                                  () => favoriteSongs.remove(currentSong),
                                );
                              } else {
                                await FavoritesDB.instance.insert(currentSong);
                                setState(() => favoriteSongs.add(currentSong));
                              }
                            },
                            onLongPress: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavoritesScreen(
                                  favoriteSongs: favoriteSongs,
                                ),
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? Colors.pinkAccent
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Controls ─────────────────────────────────────────
                if (isPlaying) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNeumorphicButton(
                        size: 52,
                        onTap: _previousSong,
                        child: const Icon(
                          Icons.skip_previous_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                offset: const Offset(5, 5),
                                blurRadius: 15,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                offset: const Offset(-4, -4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pause_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildNeumorphicButton(
                        size: 52,
                        onTap: _nextSong,
                        child: const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Like + Shake hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 40),
                          Icon(
                            Icons.vibration,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Shake to Play/Pause",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 46),
                    ],
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(5, 5),
                            blurRadius: 15,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            offset: const Offset(-4, -4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
