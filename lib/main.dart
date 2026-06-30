import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/splash_screen.dart';
import 'pages/music_player_screen.dart';
import 'services/music_channel.dart';
import 'services/player_state.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Global key to navigate from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    ChangeNotifierProvider.value(
      value: PlayerState.instance,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    MusicChannel.init();
    _setupGlobalCallbacks();
  }

  void _setupGlobalCallbacks() {
    final ps = PlayerState.instance;

    MusicChannel.onNext = () async {
      ps.next();
      final song = ps.currentSong;
      if (song == null) return;
      ps.setPlaying(true);
    };

    MusicChannel.onPrevious = () async {
      ps.previous();
      final song = ps.currentSong;
      if (song == null) return;
      ps.setPlaying(true);
    };

    MusicChannel.onStop = () {
      ps.setPlaying(false);
    };

    MusicChannel.onPause = () {
      ps.setPlaying(false);
    };

    // ← Notification tap → open MusicPlayerScreen
    MusicChannel.onOpenPlayer = () {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      // Avoid pushing duplicate if already on player screen
      navigatorKey.currentState?.pushNamedIfNotAlready('/player');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeWave',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
      routes: {'/player': (_) => const MusicPlayerScreen()},
    );
  }
}

// Extension to avoid pushing duplicate routes
extension NavigatorStateExtension on NavigatorState {
  void pushNamedIfNotAlready(String routeName) {
    // Check if already on that route
    bool alreadyOnRoute = false;
    popUntil((route) {
      if (route.settings.name == routeName) {
        alreadyOnRoute = true;
      }
      return true; // don't actually pop
    });

    if (!alreadyOnRoute) {
      pushNamed(routeName);
    }
  }
}
