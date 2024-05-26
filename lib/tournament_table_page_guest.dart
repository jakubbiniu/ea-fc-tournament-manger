import 'package:flutter/material.dart';
import 'database_helper.dart';

class TournamentTablePageGuest extends StatefulWidget {
  final int tournamentId;

  TournamentTablePageGuest({required this.tournamentId});

  @override
  _TournamentTablePageGuestState createState() => _TournamentTablePageGuestState();
}

class _TournamentTablePageGuestState extends State<TournamentTablePageGuest> {
  late Future<Map<String, String>> _playerClubsFuture;

  @override
  void initState() {
    super.initState();
    _playerClubsFuture = _fetchPlayerClubs();
  }

  Future<Map<String, String>> _fetchPlayerClubs() async {
    var tournamentData = await DatabaseHelper.instance.getTournamentData(widget.tournamentId);
    Map<String, String> playerClubs = {};
    if (tournamentData != null && tournamentData['selectedClubs'] != null) {
      Map<dynamic, dynamic> clubsMap = Map<dynamic, dynamic>.from(tournamentData['selectedClubs']);
      clubsMap.forEach((key, value) {
        playerClubs[key] = value['icon'] as String;
      });
    }
    return playerClubs;
  }

  Future<DataTable> makeTable(Map<String, String> playerClubs) async {
    var tournamentData = await DatabaseHelper.instance.getMatchesForTournament(widget.tournamentId);
    List<DataRow> rows = [];
    List<dynamic> matches = tournamentData;
    Map<String, int> points = {};
    Map<String, int> goalsScored = {};
    Map<String, int> goalsConceded = {};
    Map<String, Map<String, int>> directMatches = {};
    Map<String, int> matchesPlayed = {};

    for (var match in matches) {
      String player1 = match['player1'];
      String player2 = match['player2'];
      int score1 = match['score1'];
      int score2 = match['score2'];

      if (match['completed'] == false) {
        continue;
      }

      matchesPlayed[player1] = (matchesPlayed[player1] ?? 0) + 1;
      matchesPlayed[player2] = (matchesPlayed[player2] ?? 0) + 1;

      if (score1 > score2) {
        points[player1] = (points[player1] ?? 0) + 3;
        points[player2] = (points[player2] ?? 0) + 0;
        directMatches[player1] ??= {};
        directMatches[player2] ??= {};
        directMatches[player1]![player2] = 2;
        directMatches[player2]![player1] = 0;
      } else if (score1 < score2) {
        points[player2] = (points[player2] ?? 0) + 3;
        points[player1] = (points[player1] ?? 0) + 0;
        directMatches[player1] ??= {};
        directMatches[player2] ??= {};
        directMatches[player1]![player2] = 0;
        directMatches[player2]![player1] = 2;
      } else {
        points[player1] = (points[player1] ?? 0) + 1;
        points[player2] = (points[player2] ?? 0) + 1;
        directMatches[player1] ??= {};
        directMatches[player2] ??= {};
        directMatches[player1]![player2] = 1;
        directMatches[player2]![player1] = 1;
      }

      goalsScored[player1] = (goalsScored[player1] ?? 0) + score1;
      goalsScored[player2] = (goalsScored[player2] ?? 0) + score2;
      goalsConceded[player1] = (goalsConceded[player1] ?? 0) + score2;
      goalsConceded[player2] = (goalsConceded[player2] ?? 0) + score1;
    }

    List<MapEntry<String, int>> sortedPoints = points.entries.toList();
    sortedPoints.sort((a, b) {
      int pointsA = a.value;
      int pointsB = b.value;
      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA);
      }

      int directMatchA = directMatches[a.key]?[b.key] ?? 0;
      int directMatchB = directMatches[b.key]?[a.key] ?? 0;
      if (directMatchA != directMatchB) {
        return directMatchB.compareTo(directMatchA);
      }

      int goalDifferenceA = (goalsScored[a.key] ?? 0) - (goalsConceded[a.key] ?? 0);
      int goalDifferenceB = (goalsScored[b.key] ?? 0) - (goalsConceded[b.key] ?? 0);
      return goalDifferenceB.compareTo(goalDifferenceA);
    });

    int rank = 1;
    sortedPoints.forEach((entry) {
      String player = entry.key;
      int point = entry.value;

      rows.add(DataRow(
        cells: [
          DataCell(Text(rank.toString())),
          DataCell(Image.network(playerClubs[player]!, width: 30, height: 30)),
          DataCell(Text(player)),
          DataCell(Text(matchesPlayed[player].toString())),
          DataCell(Text(point.toString())),
          DataCell(Text(
              ((goalsScored[player] ?? 0) - (goalsConceded[player] ?? 0))
                  .toString())),
        ],
      ));
      rank++;
    });

    return DataTable(
      columnSpacing: 20.0,
      columns: [
        DataColumn(label: Text("#")),
        DataColumn(label: Text("")),
        DataColumn(label: Text("Drużyna")),
        DataColumn(label: Text("M")),
        DataColumn(label: Text("PKT")),
        DataColumn(label: Text("RB")),
      ],
      rows: rows,
    );
  }

  Future<List<Widget>> makeMatchScores(Map<String, String> playerClubs) async {
    var tournamentData = await DatabaseHelper.instance.getMatchesForTournament(widget.tournamentId);
    List<dynamic> matches = tournamentData;
    List<Widget> matchScores = [];
    for (var match in matches) {
      String player1 = match['player1'];
      String player2 = match['player2'];
      int score1 = match['score1'];
      int score2 = match['score2'];
      if (match['completed'] == false) {
        continue;
      }
      matchScores.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(playerClubs[player1]!, width: 30, height: 30),
            SizedBox(width: 8),
            Text("$player1    $score1:$score2    $player2"),
            SizedBox(width: 8),
            Image.network(playerClubs[player2]!, width: 30, height: 30),
          ],
        ),
      );
    }
    return matchScores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Tabela"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _playerClubsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Brak danych turnieju."));
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: FutureBuilder<DataTable>(
                  future: makeTable(snapshot.data!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Center(child: Text("Brak danych turnieju."));
                    }
                    return Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: snapshot.data!,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "M - rozegrane mecze, PKT - punkty, RB - różnica bramek \n"
                                "W przypadku takiej samej liczby punktów, o kolejności decyduje: \n"
                                "wynik bezpośredniego meczu "
                                "i różnica bramek w turnieju",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Wyniki",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Widget>>(
                        future: makeMatchScores(snapshot.data!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Center(child: Text("Brak danych turnieju."));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 15,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: snapshot.data![index],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
