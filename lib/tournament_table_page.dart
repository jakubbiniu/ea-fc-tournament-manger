import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TournamentTablePage extends StatefulWidget {
  final String tournamentId;

  TournamentTablePage({required this.tournamentId});

  @override
  _TournamentTablePageState createState() => _TournamentTablePageState();
}

class _TournamentTablePageState extends State<TournamentTablePage> {
  DatabaseReference get _matchesRef =>
      FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/matches');

  Future<DataTable> makeTable(String tournamentId) async {
    List<DataRow> rows = [];
    List<Map<dynamic, dynamic>> matches = [];

    DataSnapshot snapshot = await _matchesRef.get();
    if (snapshot.exists) {
      matches = (snapshot.value as Map).values.toList().cast<Map<dynamic, dynamic>>();
    }

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

    points.forEach((player, point) {
      rows.add(DataRow(
        cells: [
          DataCell(Text(player)),
          DataCell(Text(matchesPlayed[player].toString())),
          DataCell(Text(point.toString())),
          DataCell(Text(
              ((goalsScored[player] ?? 0) - (goalsConceded[player] ?? 0))
                  .toString())),
        ],
      ));
    });

    rows.sort((a, b) {
      int pointsA = int.parse((a.cells[2].child as Text).data!);
      int pointsB = int.parse((b.cells[2].child as Text).data!);
      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA);
      }

      int directMatchA = directMatches[(a.cells[0].child as Text).data!]?[(b.cells[0].child as Text).data!] ?? 0;
      int directMatchB = directMatches[(b.cells[0].child as Text).data!]?[(a.cells[0].child as Text).data!] ?? 0;
      if (directMatchA != directMatchB) {
        return directMatchB.compareTo(directMatchA);
      }

      int goalDifferenceA = int.parse((a.cells[3].child as Text).data!);
      int goalDifferenceB = int.parse((b.cells[3].child as Text).data!);
      if (goalDifferenceA != goalDifferenceB) {
        return goalDifferenceB.compareTo(goalDifferenceA);
      }

      return int.parse((b.cells[3].child as Text).data!).compareTo(int.parse((a.cells[3].child as Text).data!));
    });

    List<DataRow> rankedRows = [];
    for (int i = 0; i < rows.length; i++) {
      DataRow row = rows[i];
      rankedRows.add(DataRow(
        cells: [
          DataCell(Text((i + 1).toString())), // Rank column
          ...row.cells
        ],
      ));
    }

    return DataTable(
      columnSpacing: 20.0,
      columns: [
        DataColumn(label: Text("#")), // Rank column
        DataColumn(label: Text("Drużyna")),
        DataColumn(label: Text("M")),
        DataColumn(label: Text("PKT")),
        DataColumn(label: Text("RB")),
      ],
      rows: rankedRows,
    );
  }


  Future<List> makeMatchScores() async {
    List<Map<dynamic, dynamic>> matches = [];
    List<String> matchScores = [];

    DataSnapshot snapshot = await _matchesRef.get();
    if (snapshot.exists) {
      matches = (snapshot.value as Map).values.toList().cast<Map<dynamic, dynamic>>();
    }

    for (var match in matches) {
      String player1 = match['player1'];
      String player2 = match['player2'];
      int score1 = match['score1'];
      int score2 = match['score2'];
      if (match['completed'] == false) {
        continue;
      }
      matchScores.add("$player1    $score1:$score2    $player2");
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
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<DataTable>(
              future: makeTable(widget.tournamentId),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List>(
                    future: makeMatchScores(),
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
                          return ListTile(
                            title: Text(snapshot.data![index]),
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
      ),
    );
  }
}
