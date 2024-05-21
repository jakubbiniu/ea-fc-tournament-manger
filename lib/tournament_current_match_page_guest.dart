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
  Map<String, Map<String, String>> selectedClubs = {};

  @override
  void initState() {
    super.initState();
    checkIfTournamentEnded();
    fetchCurrentMatch();
    fetchSelectedClubs();
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

  void fetchSelectedClubs() async {
    var tournamentData = await DatabaseHelper.instance.getTournamentData(widget.tournamentId);
    if (tournamentData != null && tournamentData['selectedClubs'] != null) {
      Map<dynamic, dynamic> rawSelectedClubs = tournamentData['selectedClubs'] as Map<dynamic, dynamic>;
      Map<String, Map<String, String>> parsedSelectedClubs = {};
      rawSelectedClubs.forEach((key, value) {
        parsedSelectedClubs[key as String] = Map<String, String>.from(value as Map<dynamic, dynamic>);
      });
      setState(() {
        selectedClubs = parsedSelectedClubs;
      });
    }
  }

  String getPlayerWithClub(String playerName) {
    if (selectedClubs.containsKey(playerName)) {
      return '$playerName (${selectedClubs[playerName]!['name']})';
    }
    return playerName;
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
    String player1 = currentMatch!['player1'];
    String player2 = currentMatch!['player2'];
    String clubName1 = selectedClubs[player1]?['name'] ?? 'Brak klubu';
    String clubIcon1 = selectedClubs[player1]?['icon'] ?? '';
    String clubName2 = selectedClubs[player2]?['name'] ?? 'Brak klubu';
    String clubIcon2 = selectedClubs[player2]?['icon'] ?? '';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildPlayerCard(player1, clubName1, clubIcon1, _score1Controller),
              SizedBox(width: 10),
              Text('VS', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              buildPlayerCard(player2, clubName2, clubIcon2, _score2Controller),
            ],
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

  Widget buildPlayerCard(String player, String club, String clubIcon, TextEditingController scoreController) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(player, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(club, style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              if (clubIcon.isNotEmpty) Image.network(clubIcon, width: 50, height: 50),
              TextFormField(
                controller: scoreController,
                decoration: InputDecoration(labelText: 'Wynik $player ($club)'),
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Wprowadź poprawnie wyniki (nieujemna liczba całkowita)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
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
