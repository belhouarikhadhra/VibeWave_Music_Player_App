import 'package:flutter/material.dart';
import '../models/song_model.dart';

class SongDetailWidget extends StatelessWidget {
  final Song song;
  final bool isLandscape;
  final VoidCallback? onClose;

  const SongDetailWidget({
    super.key,
    required this.song,
    this.isLandscape = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final double imageSize = isLandscape ? 130 : 260;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLandscape && onClose != null)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, top: 10),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onClose,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(8, 8),
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  offset: const Offset(-6, -6),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipOval(
              child: song.imageUrl.isNotEmpty
                  ? Image.network(
                      song.imageUrl,
                      height: imageSize,
                      width: imageSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: imageSize,
                        width: imageSize,
                        color: const Color(0xFF4A7A96),
                        child: const Icon(
                          Icons.music_note,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      height: imageSize,
                      width: imageSize,
                      color: const Color(0xFF4A7A96),
                      child: const Icon(
                        Icons.music_note,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "- ${song.title} -",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            song.artist,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.65),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              song.description ?? "Aucune description disponible.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.55),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class SongDetailScreen extends StatelessWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8BA7BC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "DETAILS",
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(child: SongDetailWidget(song: song)),
    );
  }
}
