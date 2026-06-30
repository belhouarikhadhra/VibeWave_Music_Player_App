import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../database/favorites_db.dart';
import 'song_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Song> favoriteSongs;
  const FavoritesScreen({super.key, required this.favoriteSongs});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Song? _selectedSong;

  static const Color _bg = Color(0xFF8BA7BC);
  static const Color _cardLight = Color(0xFF9BB5C8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "FAVORITES",
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 2,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.favoriteSongs.isEmpty
          ? _buildEmptyState()
          : OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait ||
                    _selectedSong == null) {
                  return _buildList(orientation);
                } else {
                  return Row(
                    children: [
                      Expanded(flex: 2, child: _buildList(orientation)),
                      Container(width: 1, color: Colors.white.withOpacity(0.2)),
                      Expanded(
                        flex: 3,
                        child: SongDetailWidget(
                          song: _selectedSong!,
                          isLandscape: true,
                          onClose: () => setState(() => _selectedSong = null),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cardLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(4, 4),
                  blurRadius: 15,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  offset: const Offset(-4, -4),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Favorites Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Orientation orientation) {
    return ListView.builder(
      itemCount: widget.favoriteSongs.length,
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final song = widget.favoriteSongs[index];
        final isSelected =
            orientation == Orientation.landscape && _selectedSong == song;

        return GestureDetector(
          onTap: () {
            if (orientation == Orientation.portrait) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
              );
            } else {
              setState(() => _selectedSong = song);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _cardLight,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song.imageUrl.isNotEmpty
                    ? Image.network(
                        song.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFF4A7A96),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFF4A7A96),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
              title: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.pinkAccent,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF8BA7BC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: const Text(
                        "Remove from favorites?",
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Remove",
                            style: TextStyle(color: Colors.pinkAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FavoritesDB.instance.delete(song.audioPath);
                    setState(() {
                      widget.favoriteSongs.remove(song);
                      if (_selectedSong == song) _selectedSong = null;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${song.title} removed"),
                          backgroundColor: const Color(0xFF4A7A96),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
