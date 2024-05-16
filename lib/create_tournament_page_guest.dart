import 'package:ea_fc_tournament_manager/tournament_details_page_guest.dart';
import 'package:flutter/material.dart';
import 'dart:math';
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

  @override
  void initState() {
    super.initState();
  }

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
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stwórz turniej')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _tournamentNameController,
              decoration: const InputDecoration(
                  labelText: 'Nazwa turnieju'
              ),
            ),
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
              child: Text('Dodaj gracza'),
            ),
            ..._players.map((player) => ListTile(
              title: Text(player),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => setState(() => _players.remove(player)),
              ),
            )).toList(),
            ElevatedButton(
              onPressed: () async {
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
              },
              child: Text('Utwórz turniej'),
            ),
          ],
        ),
      ),
    );
  }
}