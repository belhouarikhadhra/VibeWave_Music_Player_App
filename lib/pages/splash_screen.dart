import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:p1/pages/playlist_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _vinylController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  static const Color _bg = Color(0xFF8BA7BC);
  static const Color _card = Color(0xFF9BB5C8);
  static const Color _accent = Color(0xFF4A7A96);

  @override
  void initState() {
    super.initState();

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
        _fadeController.forward();
      }
    });

    // FIX 3: After splash, request storage permission THEN navigate
    Future.delayed(const Duration(milliseconds: 5000), () async {
      if (!mounted) return;
      await _requestStoragePermission();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const PlaylistScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  // FIX 3: Request storage/audio permission with a friendly dialog first
  Future<void> _requestStoragePermission() async {
    // Check if already granted — skip dialog if so
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;
    if (audioStatus.isGranted || storageStatus.isGranted) return;

    // Show explanation dialog before the system prompt
    if (mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF8BA7BC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Accès à la musique",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9BB5C8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(4, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      offset: const Offset(-4, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "VibeWave a besoin d'accéder à vos fichiers audio pour lire votre musique locale.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Plus tard",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7A96),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Autoriser",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        // Try audio permission first (Android 13+), fallback to storage
        if (!await Permission.audio.request().isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated vinyl
            ScaleTransition(scale: _scaleAnim, child: _buildVinyl()),

            const SizedBox(height: 40),

            // App name + tagline
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const Text(
                      "VibeWave",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Feel every beat",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Animated wave indicator
            FadeTransition(opacity: _fadeAnim, child: _buildWaveIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildVinyl() {
    return AnimatedBuilder(
      animation: _vinylController,
      builder: (_, child) => Transform.rotate(
        angle: _vinylController.value * 2 * math.pi,
        child: child,
      ),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(10, 10),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              offset: const Offset(-8, -8),
              blurRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl rings
            ...List.generate(
              5,
              (i) => Container(
                width: 200 - i * 28.0,
                height: 200 - i * 28.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06 + i * 0.02),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Waveform bars at center
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (i) {
                    final phase = (i / 7.0) + _waveController.value;
                    final h = 8.0 + 20.0 * math.sin(phase * math.pi).abs();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 3,
                      height: h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),

            // Center circle
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),

            // White center dot
            Container(
              width: 12,
              height: 12,
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

  Widget _buildWaveIndicator() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final phase = (i / 5.0) + _waveController.value;
            final h = 8.0 + 16.0 * math.sin(phase * math.pi).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
