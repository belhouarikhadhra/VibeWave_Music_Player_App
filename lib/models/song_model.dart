class Song {
  final String title;
  final String artist;
  final String imageUrl;
  final String audioPath;
  final String? description;

  Song({
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.audioPath,
    this.description,
  });

  @override /// On considère que deux chansons sont identiques si elles ont le même chemin audio
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          audioPath == other.audioPath;

  @override
  int get hashCode => audioPath.hashCode;
}