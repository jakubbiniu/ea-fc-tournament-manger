import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class TournamentTablePage extends StatefulWidget {
  final String tournamentId;

  TournamentTablePage({required this.tournamentId});

  @override
  _TournamentTablePageState createState() => _TournamentTablePageState();
}

class _TournamentTablePageState extends State<TournamentTablePage> {
  DatabaseReference get _matchesRef => FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/matches');


  @override
  void initState() {
    super.initState();
    makeTable();
  }

  
  Future<DataTable> makeTable(String tournamentId) async {
    List<DataRow> rows = [];
    List<Map<dynamic, dynamic>> matches = [];
    DatabaseReference matchesRef = FirebaseDatabase.instance.ref('tournaments/$tournamentId/matches');
    matchesRef.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      if (values != null) {
        values.forEach((key, value) {
          matches.add(value);
        });
      }
    }).catchError((error) {
      print("Error fetching matches: $error");
    });

    Map<String, int> points = {};
    Map<String, int> goalsScored = {};
    Map<String, int> goalsConceded = {};
    Map<String, Map<String, int>> directMatches = {};

    for (var match in matches) {
      String player1 = match['player1'];
      String player2 = match['player2'];
      int score1 = match['score1'];
      int score2 = match['score2'];

      if(match['completed'] == false) {
        continue;
      }

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
          DataCell(Text(point.toString())),
          DataCell(Text(((goalsScored[player] ?? 0) - (goalsConceded[player] ?? 0)).toString())),
        ],
      ));
    });

    rows.sort((a, b) {
      int pointsA = int.parse((a.cells[1].child as Text).data!);
      int pointsB = int.parse((b.cells[1].child as Text).data!);
      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA);
      }

      int directMatchA = directMatches[(a.cells[0].child as Text).data!]?[(b.cells[0].child as Text).data!] ?? 0;
      int directMatchB = directMatches[(b.cells[0].child as Text).data!]?[(a.cells[0].child as Text).data!] ?? 0;
      if(directMatchA != directMatchB) {
        return directMatchB.compareTo(directMatchA);
      }

      int goalDifferenceA = int.parse((a.cells[2].child as Text).data!);
      int goalDifferenceB = int.parse((b.cells[2].child as Text).data!);
      if (goalDifferenceA != goalDifferenceB) {
        return goalDifferenceB.compareTo(goalDifferenceA);
      }

      return int.parse((b.cells[2].child as Text).data!).compareTo(int.parse((a.cells[2].child as Text).data!));
    });

    var finalTable =  DataTable(
      columns: [
        DataColumn(label: Text("Drużyna")),
        DataColumn(label: Text("Punkty")),
        DataColumn(label: Text("Bilans bramek")),
      ],
      rows: rows,
    );

    return finalTable;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tabela"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: FutureBuilder<DataTable>(
          future: makeTable(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text("Brak danych turnieju."));
            }
            return snapshot.data!;
          },
        ),
      ),
    );
  }



}
