import 'package:sembast/sembast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static DatabaseHelper get instance => _instance;

  Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db == null) {
      await _initDb();
    }
    return _db!;
  }

  Future<void> _initDb() async {
    DatabaseFactory dbFactory;
    String dbName = 'tournaments.db';

    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      final dbPath = path.join(dir.path, dbName);
      dbFactory = databaseFactoryIo;
      _db = await dbFactory.openDatabase(dbPath);
    } else {
      dbFactory = databaseFactoryWeb;
      _db = await dbFactory.openDatabase(dbName);
    }

    await _createStores();
  }


  Future _createStores() async {
    var db = await database;

    var tournamentStore = intMapStoreFactory.store('tournaments');
    var keyExists = await tournamentStore.record(1).exists(db);
    if (!keyExists) {
      /*await tournamentStore.add(db, {
        'ended': 0,
        'players': [],
      });*/
    }

    var matchStore = intMapStoreFactory.store('matches');
    keyExists = await matchStore.record(1).exists(db);
    if (!keyExists) {
      /*await matchStore.add(db, {
        'tournament_id': 0,
        'player1': 'Player 1',
        'player2': 'Player 2',
        'score1': 0,
        'score2': 0,
        'completed': 0,
      });*/
    }

  }

  Future<int> createTournament(String name, List<String> players) async {
    var db = await database;
    var store = intMapStoreFactory.store('tournaments');
    var data = {
      'name': name,
      'players': players,
      'ended': false
    };
    int key = await store.add(db, data);
    return key;
  }


  Future<void> insertMatch(int tournamentId, Map<String, dynamic> match) async {
    var db = await database;
    var store = intMapStoreFactory.store('matches');
    var matchData = {
      ...match,
      'tournament_id': tournamentId
    };
    await store.add(db, matchData);
  }

  Future<void> createMatches(int tournamentId, List<String> players) async {
    var db = await database;
    List<Map<String, dynamic>> matches = [];
    int matchId = 1;

    // Add a dummy player "BYE" if the number of players is odd
    if (players.length % 2 != 0) {
      players.add("BYE");
    }

    int numRounds = players.length - 1;
    int halfSize = players.length ~/ 2;

    List<String> teams = List.from(players);

    for (int round = 0; round < numRounds; round++) {
      for (int i = 0; i < halfSize; i++) {
        String player1 = teams[i];
        String player2 = teams[teams.length - 1 - i];

        if (player1 != "BYE" && player2 != "BYE") {
          matches.add({
            'id': matchId++,
            'player1': player1,
            'player2': player2,
            'score1': 0,
            'score2': 0,
            'completed': false,
          });
        }
      }
      // Rotate teams
      teams.insert(1, teams.removeLast());
    }

    // Insert matches into the database
    for (var match in matches) {
      await insertMatch(tournamentId, match);
    }
  }



  Future<List<Map<String, dynamic>>> getMatchesForTournament(int tournamentId) async {
    var store = intMapStoreFactory.store('matches');
    final finder = Finder(filter: Filter.equals('tournament_id', tournamentId));
    var records = await store.find(_db!, finder: finder);
    return records.map((snapshot) => snapshot.value as Map<String, dynamic>).toList();
  }

  Stream<List<Map<String, dynamic>>> watchAllTournaments() async* {
    var db = await database;
    var store = intMapStoreFactory.store('tournaments');
    var finder = Finder(sortOrders: [SortOrder(Field.key, false)]);

    yield* store.query(finder: finder).onSnapshots(db).map((snapshots) {
      return snapshots.map((snapshot) {
        var map = Map<String, dynamic>.from(snapshot.value);
        map['id'] = snapshot.key;
        return map;
      }).toList();
    });
  }



  Future<List<Map<String, dynamic>>> getAllTournaments() async {
    var db = await database;
    var store = intMapStoreFactory.store('tournaments');
    final finder = Finder(sortOrders: [SortOrder(Field.key, false)]);
    var records = await store.find(db, finder: finder);

    return records.map((snapshot) {
      var map = Map<String, dynamic>.from(snapshot.value);
      map['id'] = snapshot.key;
      return map;
    }).toList();

  }


  Future<Map<String, dynamic>?> getTournamentData(int tournamentId) async {
    var db = await database;
    var store = intMapStoreFactory.store('tournaments');

    final finder = Finder(filter: Filter.byKey(tournamentId));
    var recordSnapshot = await store.findFirst(db, finder: finder);

    if (recordSnapshot != null) {
      return recordSnapshot.value;
    }
    return null;
  }

  Future<void> updateMatchScore(int matchId, int tournamentId, Map<String, dynamic> updates) async {
    var db = await database;
    var store = intMapStoreFactory.store('matches');
    final finder = Finder(
        filter: Filter.and([
          Filter.equals('id', matchId),
          Filter.equals('tournament_id', tournamentId)
        ])
    );
    var record = await store.findFirst(db, finder: finder);
    if (record != null) {
      await store.record(record.key).update(db, {
        'score1': updates['score1'],
        'score2': updates['score2'],
        'completed': updates['completed']
      });
    }
  }


  Future<void> endTournament(int tournamentId) async {
    var db = await database;
    await db.transaction((txn) async {
      var tournamentStore = intMapStoreFactory.store('tournaments');
      var matchStore = intMapStoreFactory.store('matches');

      final matchesFinder = Finder(filter: Filter.equals('tournament_id', tournamentId));
      await matchStore.delete(txn, finder: matchesFinder);

      await tournamentStore.record(tournamentId).delete(txn);
    });
  }


  Future<List<Map<String, dynamic>>> getUncompletedMatches(int tournamentId) async {
    var db = await database;
    var store = intMapStoreFactory.store('matches');
    final finder = Finder(
        filter: Filter.and([
          Filter.equals('tournament_id', tournamentId),
          Filter.equals('completed', false)
        ]),
        sortOrders: [
          SortOrder('id')
        ]
    );
    var records = await store.find(db, finder: finder);
    return records.map((snapshot) => snapshot.value as Map<String, dynamic>).toList();
  }


  Future<bool> isAnyDataInDatabase() async {
    var store = intMapStoreFactory.store('tournaments');
    var count = await store.count(_db!);
    return count > 0;
  }

  Future<List<dynamic>> getTournamentMatches(int tournamentId) async {
    var db = await database;
    var store = intMapStoreFactory.store('matches');
    final finder = Finder(filter: Filter.equals('tournament_id', tournamentId));
    var records = await store.find(db, finder: finder);
    return records.map((snapshot) => snapshot.value as Map<String, dynamic>).toList();
  }

}
