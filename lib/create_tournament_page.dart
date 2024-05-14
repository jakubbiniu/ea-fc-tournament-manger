import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'tournament_details_page.dart';
import 'select_location_screen.dart';

class CreateTournamentPage extends StatefulWidget {
  @override
  _CreateTournamentPageState createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbRef = FirebaseDatabase.instance.ref();
  DateTime? _tournamentDate;
  bool _isOnline = false;
  List<String> _players = [];
  TextEditingController _tournamentNameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _userController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
  }

  void _addPlayerByEmailOrUsername() async {
    DatabaseReference usersRef = _dbRef.child('users');
    String user = _userController.text;

    usersRef.once().then((DatabaseEvent event) {
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      bool _foundUser = false;

      if (data != null) {
        for (var userId in data.keys) {
          var userData = data[userId];
          if (userData['username'] == user || userData['email'] == user) {
            String userEmail = userData['email'];
            setState(() {
              _players.add(userEmail);
              _userController.clear();
            });
            _foundUser = true;
            break;
          }
        }

        if (!_foundUser) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Użytkownik nie znaleziony")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Brak danych użytkowników")));
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wystąpił błąd podczas wyszukiwania użytkownika")));
    });
  }

  void _showAddGuestDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Dodaj gościa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Imię gościa'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Telefon gościa'),
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
                  if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                    setState(() {
                      _players.add('${_nameController.text} (${_phoneController.text})');
                      _nameController.clear();
                      _phoneController.clear();
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

  // void createMatchess(String tournamentId, List<String> players) {
  //   DatabaseReference matchesRef = _dbRef.child('tournaments').child(tournamentId).child('matches');
  //   List<Map<String, dynamic>> matches = [];
  //   Random random = Random();
  //
  //   for (int i = 0; i < players.length; i++) {
  //     for (int j = i + 1; j < players.length; j++) {
  //       matches.add({
  //         'player1': players[i],
  //         'player2': players[j],
  //         'score1': 0,
  //         'score2': 0,
  //         'completed': false,
  //       });
  //     }
  //   }
  //
  //   matches.shuffle(random);
  //   for (var match in matches) {
  //     matchesRef.push().set(match);
  //   }
  // }

  void createMatches(String tournamentId, List<String> players) {
    DatabaseReference matchesRef = _dbRef.child('tournaments').child(
        tournamentId).child('matches');
    List<Map<String, dynamic>> matches = [];

    List<List<List<String>>> rounds = [];
    int numRounds = players.length - 1;

    for (int i = 0; i < numRounds; i++) {
      List<List<String>> roundMatches = [];
      if (i > 0) {
        players.insert(1, players.removeAt(players.length - 1));
      }
      for (int j = 0; j < players.length / 2; j++) {
        roundMatches.add([players[j], players[players.length - 1 - j]]);
      }
      rounds.add(roundMatches);
    }

    for (var round in rounds) {
      for (var match in round) {
        matches.add({
          'player1': match[0],
          'player2': match[1],
          'score1': 0,
          'score2': 0,
          'completed': false,
        });
      }
    }
    for (var match in matches) {
      matchesRef.push().set(match);
    }
  }

  void _openMapAndSelectLocation() async {
    if (_isOnline) return;

    LatLng? initialLocation;

    if (_locationController.text.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(_locationController.text);
        if (locations.isNotEmpty) {
          initialLocation = LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Nie udało się ustalić współrzędnych z adresu"))
        );
        return;
      }
    }

    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationScreen(initialLocation: initialLocation)),
    );

    if (selectedLocation != null) {
      _selectedLocation = selectedLocation;
      List<Placemark> placemarks = await placemarkFromCoordinates(selectedLocation.latitude, selectedLocation.longitude);
      String formattedAddress = "${placemarks.first.locality}, ${placemarks.first.street}";
      setState(() {
        _locationController.text = formattedAddress;
        _selectedLocation = selectedLocation;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stwórz turniej FIFA')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _tournamentNameController,
              decoration: InputDecoration(labelText: 'Nazwa turnieju'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Proszę wprowadzić nazwę turnieju';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Data turnieju',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Proszę wybrać datę i godzinę turnieju';
                }
                return null;
              },
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    DateTime finalDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute
                    );
                    setState(() {
                      _tournamentDate = finalDateTime;
                      _dateController.text = DateFormat('yyyy-MM-dd – kk:mm').format(finalDateTime);
                    });
                  }
                }
              },

            ),
            SwitchListTile(
              title: Text('Turniej online'),
              value: _isOnline,
              onChanged: (bool value) {
                setState(() {
                  _isOnline = value;
                  if (value) _locationController.clear();
                });
              },
            ),
            IgnorePointer(
              ignoring: _isOnline,
              child: ListTile(
                title: Text('Wybierz lokalizacje turnieju'),
                subtitle: Text(_locationController.text.isEmpty ? 'Brak wybranej lokalizacji' : _locationController.text),
                onTap: _openMapAndSelectLocation,
              ),
            ),
            TextFormField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'Email/Username gracza'),
              onFieldSubmitted: (value) => _addPlayerByEmailOrUsername,
            ),
            ElevatedButton(
              onPressed: _addPlayerByEmailOrUsername,
              child: Text('Dodaj gracza'),
            ),
            ElevatedButton(
              onPressed: _showAddGuestDialog,
              child: Text('Dodaj gościa'),
            ),
            ..._players.map((player) => ListTile(
              title: Text(player),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => setState(() => _players.remove(player)),
              ),
            )).toList(),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  DatabaseReference newRef = _dbRef.child('tournaments').push();
                  newRef.set({
                    'name': _tournamentNameController.text,
                    'date': _tournamentDate!.millisecondsSinceEpoch,
                    'location': _isOnline ? 'Online' : "${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}",
                    'players': _players,
                    'ended': false
                  }).then((_) {
                    createMatches(newRef.key!, _players);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TournamentDetailsPage(tournamentId: newRef.key!),
                    ));
                  });
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
