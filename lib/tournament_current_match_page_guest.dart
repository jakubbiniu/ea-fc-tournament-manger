import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login_page.dart';

class TournamentCurrentMatchPageGuest extends StatefulWidget {
  final int tournamentId;

  TournamentCurrentMatchPageGuest({required this.tournamentId});

  @override
  _TournamentCurrentMatchPageGuestState createState() => _TournamentCurrentMatchPageGuestState();
}

class _TournamentCurrentMatchPageGuestState extends State<TournamentCurrentMatchPageGuest> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _score1Controller = TextEditingController();
  TextEditingController _score2Controller = TextEditingController();
  bool isTournamentEnded = false;
  Map<String, dynamic>? currentMatch;

  @override
  void initState() {
    super.initState();
    checkIfTournamentEnded();
    fetchCurrentMatch();
  }

  void checkIfTournamentEnded() async {
    var tournamentData = await DatabaseHelper.instance.getTournamentData(widget.tournamentId);
    setState(() {
      isTournamentEnded = tournamentData?['ended'] ?? false;
    });
  }

  void fetchCurrentMatch() async {
    var matches = await DatabaseHelper.instance.getUncompletedMatches(widget.tournamentId);
    setState(() {
      currentMatch = matches.isNotEmpty ? matches.first : null;
      if (currentMatch != null) {
        _score1Controller.text = currentMatch!['score1'].toString();
        _score2Controller.text = currentMatch!['score2'].toString();
      } else {
        _score1Controller.clear();
        _score2Controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentMatch == null || isTournamentEnded
          ? buildNoMatchesView()
          : buildMatchView(),
    );
  }

  Widget buildNoMatchesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(isTournamentEnded
              ? "Turniej został zakończony."
              : "Nie ma już meczy do rozegrania."),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => LoginPage(auth: FirebaseAuth.instance))),
            child: Text('Powrót'),
          ),
          if (!isTournamentEnded)
            ElevatedButton(
              onPressed: () => endTournament(),
              child: Text('Zakończ turniej'),
            ),
        ],
      ),
    );
  }

  Widget buildMatchView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Mecz: ${currentMatch!['player1']} vs ${currentMatch!['player2']}'),
          TextFormField(
            key: Key('score1'),
            controller: _score1Controller,
            decoration: InputDecoration(labelText: 'Wynik ${currentMatch!['player1']}'),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  int.tryParse(value) == null ||
                  int.parse(value) < 0) {
                return 'Wprowadź poprawnie wyniki (nieujemna liczba całkowita)';
              }
              return null;
            },
          ),
          TextFormField(
            key: Key('score2'),
            controller: _score2Controller,
            decoration: InputDecoration(labelText: 'Wynik ${currentMatch!['player2']}'),
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  int.tryParse(value) == null ||
                  int.parse(value) < 0) {
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

  void updateMatch() async {
    await DatabaseHelper.instance.updateMatchScore(
      currentMatch!['id'],
      currentMatch!['tournament_id'],
      {
        'score1': int.parse(_score1Controller.text),
        'score2': int.parse(_score2Controller.text),
        'completed': true,
      },
    );
    fetchCurrentMatch();
  }

  void endTournament() async {
    try {
      await DatabaseHelper.instance.endTournament(widget.tournamentId);
      if (mounted) {
        setState(() {
          isTournamentEnded = true;
        });
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPage(auth: FirebaseAuth.instance)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie udało się zakończyć turnieju: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
