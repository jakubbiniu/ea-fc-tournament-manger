import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TournamentCurrentMatchPage extends StatefulWidget {
  final String tournamentId;
  final String userId;

  TournamentCurrentMatchPage({required this.tournamentId, required this.userId});

  @override
  _TournamentCurrentMatchPageState createState() => _TournamentCurrentMatchPageState();
}

class _TournamentCurrentMatchPageState extends State<TournamentCurrentMatchPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _score1Controller = TextEditingController();
  TextEditingController _score2Controller = TextEditingController();
  DatabaseReference get _matchesRef => FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/matches');
  DatabaseReference get _playerClubsRef => FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/player_clubs');
  String? currentMatchKey;
  bool isTournamentEnded = false;
  bool isAdmin = false;
  Map<String, String> playerClubs = {};

  @override
  void initState() {
    super.initState();
    checkIfTournamentEnded();
    checkIfUserIsAdmin();
    fetchPlayerClubs();
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

  void checkIfUserIsAdmin() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/admin').once().then((DatabaseEvent event) {
      final adminId = event.snapshot.value as String?;
      if (adminId == widget.userId) {
        setState(() {
          isAdmin = true;
        });
      }
    });
  }

  void fetchPlayerClubs() {
    _playerClubsRef.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> clubsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          clubsMap.forEach((key, value) {
            playerClubs[key] = value.toString();
          });
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
          if (isAdmin && !isTournamentEnded)
            ElevatedButton(
              onPressed: endTournament,
              child: Text('Zakończ turniej'),
            ),
          if (!isAdmin && !isTournamentEnded)
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tylko admin może zakończyć turniej."))),
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
    String player1 = match['player1'];
    String player2 = match['player2'];
    String club1 = playerClubs[player1] ?? 'Brak klubu';
    String club2 = playerClubs[player2] ?? 'Brak klubu';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Mecz: $player1 ($club1) vs $player2 ($club2)'),
          if (isAdmin) ...[
            TextFormField(
              controller: _score1Controller,
              decoration: InputDecoration(labelText: 'Wynik $player1 ($club1)'),
              validator: (value) {
                if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Wprowadź poprawnie wyniki (nieujemna liczba całkowita)';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _score2Controller,
              decoration: InputDecoration(labelText: 'Wynik $player2 ($club2)'),
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
          ]
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
    if (isAdmin) {
      FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}').update({
        'ended': true
      }).then((_) {
        Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tylko admin może zakończyć turniej.")));
    }
  }
}
