import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._(); // Prywatny konstruktor

  factory DatabaseHelper() => _instance;

  static late Database _db;

  static DatabaseHelper get instance => _instance;

  DatabaseHelper._(); // Prywatny konstruktor

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }


  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'tournaments.db');

    // Open/create the database at a given path
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    // Create tables
    await db.execute('''
      CREATE TABLE tournaments (
        id INTEGER PRIMARY KEY ,
        ended INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE matches (
        id INTEGER PRIMARY KEY,
        tournament_id INTEGER,
        player1 TEXT,
        player2 TEXT,
        score1 INTEGER,
        score2 INTEGER,
        completed INTEGER,
        FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
      )
    ''');
  }

  // Insert new tournament into the database
  Future<int> createTournament(List<String> players) async {
    var dbClient = await DatabaseHelper.instance.db;
    List<Map<String, dynamic>> maxIdResult = await dbClient.rawQuery('SELECT MAX(id) AS maxId FROM tournaments');
    int maxId = (maxIdResult.first['maxId'] ?? 0) as int;
    await dbClient.insert('tournaments', {'id': maxId + 1, 'ended': 0});
    return maxId + 1;
  }


  // Insert new match into the database
  Future<void> insertMatch(int tournamentId, Map<String, dynamic> match) async {
    Database dbClient = await db;
    await dbClient.insert('matches', {
      'tournament_id': tournamentId,
      'player1': match['player1'],
      'player2': match['player2'],
      'score1': match['score1'],
      'score2': match['score2'],
      'completed': match['completed'] ? 1 : 0,
    });
  }

  Future<bool> isAnyDataInDatabase() async {
    Database dbClient = await db;
    List<Map<String, dynamic>> result = await dbClient.rawQuery('SELECT COUNT(*) as count FROM tournaments');
    int count = Sqflite.firstIntValue(result)!;
    return count > 0;
  }

}
