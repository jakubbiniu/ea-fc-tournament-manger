import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TournamentCurrentMatchPage extends StatefulWidget {
  final String tournamentId;

  TournamentCurrentMatchPage({required this.tournamentId});

  @override
  _TournamentCurrentMatchPageState createState() => _TournamentCurrentMatchPageState();
}

class _TournamentCurrentMatchPageState extends State<TournamentCurrentMatchPage> {
  TextEditingController _score1Controller = TextEditingController();
  TextEditingController _score2Controller = TextEditingController();
  DatabaseReference get _matchesRef => FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/matches');
  String? currentMatchKey;
  bool isTournamentEnded = false;

  @override
  void initState() {
    super.initState();
    checkIfTournamentEnded();
  }

  void checkIfTournamentEnded() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/ended').onValue.listen((event) {
      final ended = event.snapshot.value as bool? ?? false;
      if (ended != isTournamentEnded) {
        setState(() {
          isTournamentEnded = ended;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: _matchesRef.orderByChild('completed').equalTo(false).limitToFirst(1).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null || isTournamentEnded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(isTournamentEnded ? "Turniej został zakończony." : "Nie ma już meczy do rozegrania."),
                  if (!isTournamentEnded) ElevatedButton(
                    onPressed: endTournament,
                    child: Text('Zakończ turniej'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Powrót'),
                  ),
                ],
              ),
            );
          }

          Map<dynamic, dynamic> matches = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          Map<dynamic, dynamic> firstMatch = matches.values.first;
          currentMatchKey = matches.keys.first;

          _score1Controller.text = firstMatch['score1'].toString();
          _score2Controller.text = firstMatch['score2'].toString();

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Mecz: ${firstMatch['player1']} vs ${firstMatch['player2']}'),
              TextField(
                controller: _score1Controller,
                decoration: InputDecoration(labelText: 'Wynik ${firstMatch['player1']}'),
              ),
              TextField(
                controller: _score2Controller,
                decoration: InputDecoration(labelText: 'Wynik ${firstMatch['player2']}'),
              ),
              ElevatedButton(
                onPressed: () => updateMatch(),
                child: Text('Zatwierdź wynik'),
              ),
            ],
          );
        },
      ),
    );
  }

  void updateMatch() {
    if (currentMatchKey != null) {
      _matchesRef.child(currentMatchKey!).update({
        'score1': int.parse(_score1Controller.text),
        'score2': int.parse(_score2Controller.text),
        'completed': true,
      });
    }
  }

  void endTournament() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}').update({
      'ended': true
    }).then((_) {
      Navigator.pop(context);
    });
  }
}
