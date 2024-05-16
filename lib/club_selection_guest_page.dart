import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tournament_details_page_guest.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class ClubSelectionPageGuest extends StatefulWidget {
  final int tournamentId;

  ClubSelectionPageGuest({required this.tournamentId});

  @override
  _ClubSelectionPageGuestState createState() => _ClubSelectionPageGuestState();
}

class _ClubSelectionPageGuestState extends State<ClubSelectionPageGuest> {
  final List<String> _clubs = [
    'Barcelona', 'Real Madrid', 'Manchester United', 'Juventus',
    'Paris Saint-Germain', 'Bayern Munich', 'Liverpool', 'Chelsea'
  ];
  List<Map<String, dynamic>> _players = [];
  final List<String> _availableClubs = [];
  final Map<String, String> _selectedClubs = {};
  Map<String, dynamic>? _selectedPlayer;
  String? _selectedClub;
  final random = Random();
  late StreamController<int> _wheelNotifier;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _wheelNotifier = StreamController<int>.broadcast();
    fetchPlayers();
    listenToSelectedClubs();
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    super.dispose();
  }

  void fetchPlayers() async {
    var tournamentData = await dbHelper.getTournamentData(widget.tournamentId);
    if (tournamentData != null) {
      setState(() {
        _players = List<Map<String, dynamic>>.from(tournamentData['players'].map((player) => {
          'name': player,
          'id': null,
        }));
        _availableClubs.addAll(_clubs.where((club) => !(tournamentData['selectedClubs'] ?? {}).containsValue(club)));
        _selectedClubs.addAll(Map<String, String>.from(tournamentData['selectedClubs'] ?? {}));
      });
    }
  }

  void listenToSelectedClubs() async {
    var tournamentData = await dbHelper.getTournamentData(widget.tournamentId);
    if (tournamentData != null && tournamentData['selectedClubs'] != null) {
      setState(() {
        _selectedClubs.clear();
        _availableClubs.clear();
        _availableClubs.addAll(_clubs);

        Map<String, String> selectedClubs = Map<String, String>.from(tournamentData['selectedClubs']);
        selectedClubs.forEach((playerName, club) {
          _selectedClubs[playerName] = club;
          _availableClubs.remove(club);
        });

        _players = _players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
      });
    }
  }

  void spinWheel() {
    if (_players.isEmpty) return;
    final index = random.nextInt(_players.length);
    _wheelNotifier.add(index);
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _selectedPlayer = _players[index];
      });
    });
  }

  void selectClub(String club) async {
    if (_selectedPlayer != null) {
      setState(() {
        _selectedClubs[_selectedPlayer!['name']] = club;
        _availableClubs.remove(club);
        _players.remove(_selectedPlayer);
        _selectedPlayer = null;
        _selectedClub = null;
      });
      await dbHelper.updateTournamentPlayerClub(widget.tournamentId, _selectedClubs);

      if (_players.length == 1) {
        setState(() {
          _selectedPlayer = _players.first;
        });
      }
    } else if (_selectedPlayer == null && _players.length == 1) {
      setState(() {
        _selectedPlayer = _players.first;
        _selectedClubs[_selectedPlayer!['name']] = club;
        _availableClubs.remove(club);
        _players.remove(_selectedPlayer);
        _selectedPlayer = null;
        _selectedClub = null;
      });
      await dbHelper.updateTournamentPlayerClub(widget.tournamentId, _selectedClubs);
    }
  }

  void startTournament() async {
    await dbHelper.startTournament(widget.tournamentId);
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
                if (_selectedPlayer == null && _players.length > 1)
                  Text(
                    'Trwa losowanie klubów dla zawodników',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 20),
                if (_selectedPlayer == null && _players.length > 1)
                  ElevatedButton(
                    onPressed: spinWheel,
                    child: Text('Losuj gracza'),
                  ),
                if (_selectedPlayer == null && _players.length > 1)
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
                              setState(() {
                                _selectedPlayer = _players[snapshot.data!];
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                if (_selectedPlayer != null || (_players.length == 1 && _selectedPlayer == null)) ...[
                  Text(
                    'Wybierasz klub dla: ${_selectedPlayer != null ? _selectedPlayer!['name'] : _players.first['name']}',
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
                ],
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
                if (_players.isEmpty && _selectedClubs.isNotEmpty)
                  ElevatedButton(
                    onPressed: startTournament,
                    child: Text('Rozpocznij turniej'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
