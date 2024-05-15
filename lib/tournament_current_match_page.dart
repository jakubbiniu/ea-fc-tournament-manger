import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TournamentCurrentMatchPage extends StatefulWidget {
  final String tournamentId;

  TournamentCurrentMatchPage({required this.tournamentId});

  @override
  _TournamentCurrentMatchPageState createState() => _TournamentCurrentMatchPageState();
}

class _TournamentCurrentMatchPageState extends State<TournamentCurrentMatchPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
            return buildNoMatchesView();
          }

          Map<dynamic, dynamic> matches = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          Map<dynamic, dynamic> firstMatch = matches.values.first;
          currentMatchKey = matches.keys.first;

          _score1Controller.text = firstMatch['score1'].toString();
          _score2Controller.text = firstMatch['score2'].toString();

          return buildMatchView(firstMatch);
        },
      ),
    );
  }

  Widget buildNoMatchesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(isTournamentEnded ? "Turniej został zakończony." : "Nie ma już meczy do rozegrania."),
          if (!isTournamentEnded)
            ElevatedButton(
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

  Widget buildMatchView(Map<dynamic, dynamic> match) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Mecz: ${match['player1']} vs ${match['player2']}'),
          TextFormField(
            controller: _score1Controller,
            decoration: InputDecoration(labelText: 'Wynik ${match['player1']}'),
            validator: (value) {
              if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                return 'Wprowadź poprawnie wyniki (nieujemna liczba całkowita)';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _score2Controller,
            decoration: InputDecoration(labelText: 'Wynik ${match['player2']}'),
            validator: (value) {
              if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                return 'Wprowadź poprawnie wyniki (nieujemna liczba całkowita)';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                bool confirm = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Potwierdzenie"),
                      content: Text("Czy na pewno chcesz zatwierdzić wynik?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text("Nie"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text("Tak"),
                        ),
                      ],
                    );
                  },
                );
                if (confirm) {
                  updateMatch();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wprowadź poprawnie wyniki'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Zatwierdź wynik'),
          ),
        ],
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
