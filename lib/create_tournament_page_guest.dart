import 'package:ea_fc_tournament_manager/tournament_details_page_guest.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class CreateTournamentPageGuest extends StatefulWidget {
  @override
  _CreateTournamentPageGuestState createState() => _CreateTournamentPageGuestState();
}

class _CreateTournamentPageGuestState extends State<CreateTournamentPageGuest> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  List<String> _players = [];
  final TextEditingController _tournamentNameController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  bool _isTwoPersonTeams = false;
  double _dragProgress = 0.0;

  void _showAddGuestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dodaj gracza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Imię gracza'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Anuluj'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Dodaj'),
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  setState(() {
                    _players.add(_nameController.text);
                    _nameController.clear();
                    Navigator.pop(context);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Proszę wypełnić wszystkie pola")));
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<String> _createTeams(List<String> players) {
    List<String> teams = [];
    List<String> shuffledPlayers = List.from(players)..shuffle();

    for (int i = 0; i < shuffledPlayers.length; i += 2) {
      if (i + 1 < shuffledPlayers.length) {
        teams.add('${shuffledPlayers[i]} & ${shuffledPlayers[i + 1]}');
      } else {
        teams.add(shuffledPlayers[i]);
      }
    }

    return teams;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _dragProgress += details.primaryDelta! / constraints.maxWidth;
      _dragProgress = _dragProgress.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragProgress > 0.8) {
      if (_formKey.currentState!.validate()) {
        _createTournament();
      }
    }
    setState(() {
      _dragProgress = 0.0;
    });
  }

  void _createTournament() async {
    if (_formKey.currentState!.validate()) {
      List<String> finalPlayers = _isTwoPersonTeams ? _createTeams(_players) : _players;
      try {
        int tournamentId = await dbHelper.createTournament(_tournamentNameController.text, finalPlayers);
        await dbHelper.createMatches(tournamentId, finalPlayers);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailsPageGuest(tournamentId: tournamentId),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wystąpił błąd: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stwórz turniej'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _tournamentNameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa turnieju',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Drużyny dwuosobowe'),
              value: _isTwoPersonTeams,
              onChanged: (bool value) {
                setState(() {
                  _isTwoPersonTeams = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _showAddGuestDialog,
              child: Text('Dodaj gracza', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ), backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Lista graczy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _players.isEmpty
                ? Center(
              child: Text('Brak dodanych graczy'),
            )
                : Column(
              children: _players.map((player) {
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(player[0].toUpperCase()),
                    ),
                    title: Text(player),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _players.remove(player)),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, constraints),
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: Stack(
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Przeciągnij, aby utworzyć turniej',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, color: Colors.green),
                          ],
                        )
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          height: 80,
                          width: constraints.maxWidth * _dragProgress,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
