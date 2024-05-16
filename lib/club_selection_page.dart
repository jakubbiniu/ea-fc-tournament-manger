import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

import 'tournament_details_page.dart';

class ClubSelectionPage extends StatefulWidget {
  final String tournamentId;
  final String userId;

  ClubSelectionPage({required this.tournamentId, required this.userId});

  @override
  _ClubSelectionPageState createState() => _ClubSelectionPageState();
}

class _ClubSelectionPageState extends State<ClubSelectionPage> {
  final List<String> _clubs = [
    'Barcelona', 'Real Madrid', 'Manchester United', 'Juventus',
    'Paris Saint-Germain', 'Bayern Munich', 'Liverpool', 'Chelsea'
  ];
  List<Map<String, dynamic>> _players = [];
  final List<String> _availableClubs = [];
  final Map<String, String> _selectedClubs = {};
  Map<String, dynamic>? _selectedPlayer;
  String? _selectedClub;
  bool isAdmin = false;
  final random = Random();
  late StreamController<int> _wheelNotifier;

  @override
  void initState() {
    super.initState();
    _wheelNotifier = StreamController<int>.broadcast();
    checkIfUserIsAdmin();
    fetchPlayers();
    listenToPlayerSelection();
    listenToSelectedClubs();
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
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

  void fetchPlayers() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/players').once().then((DatabaseEvent event) {
      final players = List<Map<String, dynamic>>.from((event.snapshot.value as List).map((e) => Map<String, dynamic>.from(e)));
      setState(() {
        _players = players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
        _availableClubs.addAll(_clubs.where((club) => !_selectedClubs.containsValue(club)));
      });
    });
  }

  void listenToPlayerSelection() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/current_selection').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey('selectedPlayer')) {
        setState(() {
          _selectedPlayer = _players.firstWhere(
                (player) => player['name'] == data['selectedPlayer'],
            orElse: () => <String, dynamic>{},
          );
        });
      } else {
        setState(() {
          _selectedPlayer = null;
        });
      }
    });
  }

  void listenToSelectedClubs() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/player_clubs').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          _selectedClubs.clear();
          _availableClubs.clear();
          _availableClubs.addAll(_clubs);

          data.forEach((playerName, club) {
            _selectedClubs[playerName] = club;
            _availableClubs.remove(club);
          });

          _players = _players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
        });
      }
    });
  }

  void spinWheel() {
    if (_players.length <= 1) return;
    final index = random.nextInt(_players.length);
    _wheelNotifier.add(index);
    Future.delayed(Duration(seconds: 3), () {
      FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/current_selection').set({
        'selectedPlayer': _players[index]['name']
      });
    });
  }

  void selectClub(String club) {
    if (_selectedPlayer != null || (_players.length == 1 && (_players.first['id'] == widget.userId || _players.first['id'] == null && isAdmin))) {
      final playerName = _selectedPlayer != null ? _selectedPlayer!['name'] : _players.first['name'];
      FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/player_clubs').child(playerName).set(club).then((_) {
        FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/current_selection').remove();
      });
      setState(() {
        _selectedPlayer = null;
        _selectedClub = null;
      });
    }
  }

  void startTournament() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}').update({'started': true}).then((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => TournamentDetailsPage(tournamentId: widget.tournamentId, userId: widget.userId),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Losowanie klubów'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedPlayer != null)
                  Text(
                    'Wylosowany gracz: ${_selectedPlayer!['name']}',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                if (_selectedPlayer == null && _players.isNotEmpty && _players.length > 1)
                  Text(
                    'Trwa losowanie klubów dla zawodników',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 20),
                if (isAdmin && _selectedPlayer == null && _players.length > 1)
                  ElevatedButton(
                    onPressed: spinWheel,
                    child: Text('Losuj gracza'),
                  ),
                if (isAdmin && _players.length > 1)
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: _wheelNotifier.stream,
                      builder: (context, snapshot) {
                        return FortuneWheel(
                          selected: _wheelNotifier.stream,
                          animateFirst: false,
                          duration: const Duration(seconds: 3),
                          items: [
                            for (var player in _players)
                              FortuneItem(
                                child: Text(player['name']),
                              ),
                          ],
                          onAnimationEnd: () {
                            if (snapshot.hasData) {
                              FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/current_selection').set({
                                'selectedPlayer': _players[snapshot.data!]['name']
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                if (_selectedPlayer != null && (_selectedPlayer!['id'] == widget.userId || _selectedPlayer!['id'] == null && isAdmin)) ...[
                  Text(
                    'Wybierasz klub dla: ${_selectedPlayer!['name']}',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  DropdownButton<String>(
                    hint: Text('Wybierz klub'),
                    value: _selectedClub,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClub = newValue;
                      });
                    },
                    items: _availableClubs.map((String club) {
                      return DropdownMenuItem<String>(
                        value: club,
                        child: Text(club),
                      );
                    }).toList(),
                  ),
                  if (_selectedClub != null)
                    ElevatedButton(
                      onPressed: () {
                        selectClub(_selectedClub!);
                      },
                      child: Text('Zatwierdź klub'),
                    ),
                ] else if (_selectedPlayer != null)
                  Text(
                    'Trwa wybór klubu przez: ${_selectedPlayer!['name']}',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                if (_selectedPlayer == null && _players.length == 1 && (_players.first['id'] == widget.userId || _players.first['id'] == null && isAdmin)) ...[
                  Text(
                    'Wybierasz klub dla: ${_players.first['name']}',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  DropdownButton<String>(
                    hint: Text('Wybierz klub'),
                    value: _selectedClub,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClub = newValue;
                      });
                    },
                    items: _availableClubs.map((String club) {
                      return DropdownMenuItem<String>(
                        value: club,
                        child: Text(club),
                      );
                    }).toList(),
                  ),
                  if (_selectedClub != null)
                    ElevatedButton(
                      onPressed: () {
                        selectClub(_selectedClub!);
                      },
                      child: Text('Zatwierdź klub'),
                    ),
                ] else if (_selectedPlayer == null && _players.length == 1) ...[
                  Text(
                    'Ostatni gracz: ${_players.first['name']} wybiera klub',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (isAdmin && _players.isEmpty)
                  ElevatedButton(
                    onPressed: startTournament,
                    child: Text('Rozpocznij turniej'),
                  ),
                if (_selectedClubs.isNotEmpty) ...[
                  Text(
                    'Wybrane kluby:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  ..._selectedClubs.entries.map((entry) {
                    return Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
