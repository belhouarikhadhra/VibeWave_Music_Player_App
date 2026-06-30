import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song_model.dart';

class FavoritesDB { 
  static final FavoritesDB instance = FavoritesDB._init(); 
  static Database? _database; 

  FavoritesDB._init(); 

  Future<Database> get database async {
    
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath(); // Get the default database path
    final path = join(dbPath, fileName);// Combine the path with the file name
    return await openDatabase(path, version: 1, onCreate: _createDB); // Open the database, creating it if it doesn't exist
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        audioPath   TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        artist      TEXT NOT NULL,
        imageUrl    TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  Future<List<Song>> fetchAll() async {
    final db = await database;
    final rows = await db.query('favorites');
    return rows
        .map((row) => Song(
              title: row['title'] as String,
              artist: row['artist'] as String,
              imageUrl: row['imageUrl'] as String,
              audioPath: row['audioPath'] as String,
              description: row['description'] as String?,
            ))
        .toList();
  }

  Future<void> insert(Song song) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'audioPath': song.audioPath,
        'title': song.title,
        'artist': song.artist,
        'imageUrl': song.imageUrl,
        'description': song.description,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> delete(String audioPath) async {
    final db = await database;
    await db.delete('favorites', where: 'audioPath = ?', whereArgs: [audioPath]);
  }

  Future<bool> isFavorite(String audioPath) async {
    final db = await database;
    final rows = await db.query('favorites', where: 'audioPath = ?', whereArgs: [audioPath]);
    return rows.isNotEmpty;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}