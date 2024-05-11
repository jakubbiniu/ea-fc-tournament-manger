import 'package:ea_fc_tournament_manager/login_page.dart';
import 'package:ea_fc_tournament_manager/test_page.dart';
import 'package:ea_fc_tournament_manager/tournament_details_page_guest.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';
import 'database_helper.dart'; // Import naszej klasy pomocniczej dla SQLite

class CreateTournamentPageGuest extends StatefulWidget {
  @override
  _CreateTournamentPageGuestState createState() => _CreateTournamentPageGuestState();
}

class _CreateTournamentPageGuestState extends State<CreateTournamentPageGuest> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance; // Wykorzystujemy naszą instancję klasy pomocniczej do obsługi bazy SQLite
  final db = DatabaseHelper.instance.db;
  List<String> _players = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _errorController = TextEditingController();

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
                      _players.add('${_nameController.text}');
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

  void createMatches(int tournamentId, List<String> players) async {
    List<Map<String, dynamic>> matches = [];
    Random random = Random();

    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        matches.add({
          'player1': players[i],
          'player2': players[j],
          'score1': 0,
          'score2': 0,
          'completed': false,
        });
      }
    }

    matches.shuffle(random);
    for (var match in matches) {
      await dbHelper.insertMatch(tournamentId, match); // Dodajemy mecz do bazy danych SQLite
    }
  }

  Future<bool> isAnyDataInDatabase() async {
    Database db = await DatabaseHelper.instance.db;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM tournaments');
    int count = Sqflite.firstIntValue(result)!;
    return count > 0;
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
            TextField(
              controller: _errorController,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  int tournamentId = await dbHelper.createTournament(_players);
                  _errorController.text = tournamentId.toString();

                  // if (_formKey.currentState!.validate()) {
                  //   dbHelper.createTournament(_players).then((tournamentId) {
                  //     createMatches(tournamentId, _players);
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => TestPage(),
                  //       ),
                  //     );
                  //   });
                  // }
                } catch (e) {
                  // _errorController.text = "Wystąpił błąd: $e";
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wystąpił błąd: $e")));
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
