import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'tournament_details_page.dart';
import 'select_location_screen.dart';

class CreateTournamentPage extends StatefulWidget {
  final String userId;
  final User user;

  CreateTournamentPage({required this.userId, required this.user});

  @override
  _CreateTournamentPageState createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbRef = FirebaseDatabase.instance.ref();
  DateTime? _tournamentDate;
  bool _isOnline = false;
  bool _isTwoPersonTeams = false;
  List<Map<String, dynamic>> _players = [];
  TextEditingController _tournamentNameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _userController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  LatLng? _selectedLocation;

  double _dragProgress = 0.0;

  void _addPlayerByEmailOrUsername() async {
    DatabaseReference usersRef = _dbRef.child('users');
    String user = _userController.text;

    usersRef.once().then((DatabaseEvent event) {
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      bool _foundUser = false;

      if (data != null) {
        for (var userId in data.keys) {
          var userData = data[userId];
          if (userData['nickname'] == user || userData['email'] == user) {
            String userNickname = userData['nickname'];
            setState(() {
              _players.add({'name': userNickname, 'id': userData['email']});
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

  void _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dodaj gracza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userController,
                decoration: InputDecoration(labelText: 'Email/Username gracza'),
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
                if (_userController.text.isNotEmpty) {
                  _addPlayerByEmailOrUsername();
                  Navigator.pop(context);
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
                    _players.add({'name': '${_nameController.text} (Gość)', 'id': null});
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

  void createMatches(String tournamentId, List<Map<String, dynamic>> players) {
    DatabaseReference matchesRef = FirebaseDatabase.instance
        .ref()
        .child('tournaments')
        .child(tournamentId)
        .child('matches');

    if (players.length % 2 != 0) {
      players.add({'name': "BYE", 'id': null}); // Add a dummy player if the number of players is odd
    }

    List<Map<String, dynamic>> matches = [];
    int numRounds = players.length - 1;
    int halfSize = players.length ~/ 2;

    List<Map<String, dynamic>> teams = List.from(players);
    for (int round = 0; round < numRounds; round++) {
      for (int i = 0; i < halfSize; i++) {
        var player1 = teams[i];
        var player2 = teams[teams.length - 1 - i];
        if (player1['name'] != "BYE" && player2['name'] != "BYE") {
          matches.add({
            'player1': player1['name'],
            'player2': player2['name'],
            'score1': 0,
            'score2': 0,
            'completed': false,
          });
        }
      }
      teams.insert(1, teams.removeLast()); // Rotate teams
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
          SnackBar(content: Text("Nie udało się ustalić współrzędnych z adresu")),
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

  List<Map<String, dynamic>> _createTeams(List<Map<String, dynamic>> players) {
    List<Map<String, dynamic>> teams = [];
    List<Map<String, dynamic>> shuffledPlayers = List.from(players)..shuffle();

    for (int i = 0; i < shuffledPlayers.length; i += 2) {
      if (i + 1 < shuffledPlayers.length) {
        var player1 = shuffledPlayers[i];
        var player2 = shuffledPlayers[i + 1];
        String? teamId = player1['id'] ?? player2['id'];
        String? secondId = player1['id'] != null && player2['id'] != null ? player2['id'] : null;

        teams.add({
          'name': '${player1['name']} & ${player2['name']}',
          'id': teamId,
          'second_id': secondId,
        });
      } else {
        teams.add({
          'name': '${shuffledPlayers[i]['name']}',
          'id': shuffledPlayers[i]['id'],
          'second_id': null,
        });
      }
    }

    return teams;
  }

  void _createTournament() {
    if (_formKey.currentState!.validate()) {
      if (!_isOnline && _selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Proszę wybrać lokalizację turnieju")),
        );
        return;
      }

      List<Map<String, dynamic>> finalPlayers = _isTwoPersonTeams ? _createTeams(_players) : _players;
      DatabaseReference newRef = _dbRef.child('tournaments').push();
      newRef.set({
        'name': _tournamentNameController.text,
        'date': _tournamentDate!.millisecondsSinceEpoch,
        'location': _isOnline ? 'Online' : "${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}",
        'players': finalPlayers,
        'ended': false,
        'admin': widget.userId
      }).then((_) {
        createMatches(newRef.key!, finalPlayers);
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => TournamentDetailsPage(tournamentId: newRef.key!, userId: widget.userId, user: widget.user),
        ));
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Stwórz turniej FIFA'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _tournamentNameController,
              decoration: InputDecoration(
                labelText: 'Nazwa turnieju',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Proszę wprowadzić nazwę turnieju';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Data turnieju',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      pickedTime.minute,
                    );
                    setState(() {
                      _tournamentDate = finalDateTime;
                      _dateController.text = DateFormat('yyyy-MM-dd – kk:mm').format(finalDateTime);
                    });
                  }
                }
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Turniej online'),
              value: _isOnline,
              onChanged: (bool value) {
                setState(() {
                  _isOnline = value;
                  if (value) {
                    _locationController.clear();
                    _selectedLocation = null;
                  }
                });
              },
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
            IgnorePointer(
              ignoring: _isOnline,
              child: GestureDetector(
                onTap: _openMapAndSelectLocation,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationController.text.isEmpty
                              ? 'Wybierz lokalizację turnieju'
                              : _locationController.text,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showAddPlayerDialog,
                    child: Text('Dodaj gracza', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showAddGuestDialog,
                    child: Text('Dodaj gościa', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
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
                      child: Text(player['name'][0].toUpperCase()),
                    ),
                    title: Text(player['name']),
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
                            Text(
                              'Przeciągnij, aby utworzyć turniej',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, color: Colors.green),
                          ],
                        ),
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