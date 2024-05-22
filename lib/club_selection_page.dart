import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shake/shake.dart';

import 'tournament_details_page.dart';

class ClubSelectionPage extends StatefulWidget {
  final String tournamentId;
  final String userId;

  ClubSelectionPage({required this.tournamentId, required this.userId});

  @override
  _ClubSelectionPageState createState() => _ClubSelectionPageState();
}

class _ClubSelectionPageState extends State<ClubSelectionPage> {
  final List<String> _countries = [];
  final Map<String, List<String>> _leagues = {};
  final Map<String, List<Map<String, String>>> _clubs = {};
  List<Map<String, dynamic>> _players = [];
  final Map<String, Map<String, String>> _selectedClubs = {};
  Map<String, dynamic>? _selectedPlayer;
  String? _selectedCountry;
  String? _selectedLeague;
  int _selectedClubIndex = 0;
  bool isAdmin = false;
  final random = Random();
  late StreamController<int> _wheelNotifier;
  ShakeDetector? shakeDetector;

  @override
  void initState() {
    super.initState();
    _wheelNotifier = StreamController<int>.broadcast();
    checkIfUserIsAdmin();
    fetchPlayers();
    listenToPlayerSelection();
    listenToSelectedClubs();
    fetchCountriesAndTeams();
    initShakeDetector();
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    shakeDetector?.stopListening();
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

          data.forEach((playerName, clubData) {
            if (clubData is Map<dynamic, dynamic>) {
              _selectedClubs[playerName] = {
                'name': clubData['name'],
                'icon': clubData['icon']
              };
            }
          });

          _players = _players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
        });
      }
    });
  }

  void fetchCountriesAndTeams() {
    FirebaseDatabase.instance.ref('countries').once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return;
      }
      setState(() {
        _countries.clear();
        _leagues.clear();
        _clubs.clear();

        data.forEach((country, countryData) {
          if (country != null && countryData != null) {
            final countryName = country as String;
            if (!_countries.contains(countryName)) {
              _countries.add(countryName);
            }
            final leagues = countryData['leagues'] as Map<dynamic, dynamic>?;
            if (leagues != null) {
              if (!_leagues.containsKey(countryName)) {
                _leagues[countryName] = [];
              }
              _leagues[countryName]!.addAll(leagues.keys.cast<String>().where((league) => !_leagues[countryName]!.contains(league)).toList());
              leagues.forEach((league, leagueData) {
                if (leagueData != null) {
                  final leagueName = league as String;
                  _clubs[leagueName] = List<Map<String, String>>.from((leagueData as List).map((clubData) {
                    if (clubData != null) {
                      final clubMap = clubData as Map<dynamic, dynamic>;
                      final clubName = clubMap['name'] as String?;
                      final clubIcon = clubMap['icon'] as String?;
                      if (clubName != null && clubIcon != null && !_isClubSelected(clubName)) {
                        return {
                          'name': clubName,
                          'icon': clubIcon
                        };
                      }
                    }
                    return {'name': '', 'icon': ''};
                  }).where((clubMap) => clubMap['name']!.isNotEmpty));
                }
              });
            }
          }
        });

        FirebaseDatabase.instance.ref('national_teams').once().then((DatabaseEvent event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) {
            return;
          }
          setState(() {
            if (!_countries.contains('National Teams')) {
              _countries.add('National Teams');
            }
            _leagues['National Teams'] = ['Men', 'Women'];
            _clubs['Men'] = List<Map<String, String>>.from((data['men'] as List).map((teamData) {
              if (teamData != null) {
                final teamMap = teamData as Map<dynamic, dynamic>;
                final teamName = teamMap['name'] as String?;
                final teamIcon = teamMap['icon'] as String?;
                if (teamName != null && teamIcon != null && !_isClubSelected(teamName)) {
                  return {
                    'name': teamName,
                    'icon': teamIcon
                  };
                }
              }
              return {'name': '', 'icon': ''};
            }).where((teamMap) => teamMap['name']!.isNotEmpty));
            _clubs['Women'] = List<Map<String, String>>.from((data['women'] as List).map((teamData) {
              if (teamData != null) {
                final teamMap = teamData as Map<dynamic, dynamic>;
                final teamName = teamMap['name'] as String?;
                final teamIcon = teamMap['icon'] as String?;
                if (teamName != null && teamIcon != null && !_isClubSelected(teamName)) {
                  return {
                    'name': teamName,
                    'icon': teamIcon
                  };
                }
              }
              return {'name': '', 'icon': ''};
            }).where((teamMap) => teamMap['name']!.isNotEmpty));
          });
        });
      });
    });
  }

  bool _isClubSelected(String clubName) {
    return _selectedClubs.values.any((club) => club['name'] == clubName);
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

  void selectClub() {
    if (_selectedPlayer != null || (_players.length == 1 && (_players.first['id'] == widget.userId || _players.first['id'] == null && isAdmin))) {
      final playerName = _selectedPlayer != null ? _selectedPlayer!['name'] : _players.first['name'];
      final selectedClub = _clubs[_selectedLeague!]![_selectedClubIndex];
      final clubName = selectedClub['name'];
      final clubIcon = selectedClub['icon'];
      FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/player_clubs').child(playerName).set({
        'name': clubName,
        'icon': clubIcon,
      }).then((_) {
        FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/current_selection').remove().then((_) {
          setState(() {
            _selectedClubs[playerName] = {
              'name': clubName!,
              'icon': clubIcon!,
            };
            _selectedPlayer = null;
            _selectedClubIndex = 0;
            _selectedCountry = null;
            _selectedLeague = null;
            fetchCountriesAndTeams();
          });
        });
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

  bool get shouldHideWheel {
    if (_selectedPlayer != null &&
        (_selectedPlayer!['id'] == widget.userId ||
            _selectedPlayer!['id'] == null && isAdmin)) {
      return true;
    }
    if (_players.length <= 1) {
      return true;
    }
    return false;
  }

  void initShakeDetector() {
    shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        if (isAdmin && _selectedPlayer == null && _players.length > 1) {
          spinWheel();
        }
      },
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3500,
      shakeThresholdGravity: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  if (!shouldHideWheel)
                    Container(
                      height: 300,
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
                      hint: Text('Wybierz kraj'),
                      value: _selectedCountry,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                          _selectedLeague = null;
                          _selectedClubIndex = 0;
                        });
                      },
                      items: _countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                    ),
                    if (_selectedCountry != null)
                      DropdownButton<String>(
                        hint: Text('Wybierz ligę'),
                        value: _selectedLeague,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLeague = newValue;
                            _selectedClubIndex = 0;
                          });
                        },
                        items: _leagues[_selectedCountry!]!.map((String league) {
                          return DropdownMenuItem<String>(
                            value: league,
                            child: Text(league),
                          );
                        }).toList(),
                      ),
                    if (_selectedLeague != null && _clubs[_selectedLeague!] != null)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _selectedClubIndex = index;
                            });
                          },
                        ),
                        items: _clubs[_selectedLeague!]!
                            .where((club) => !_isClubSelected(club['name']!))
                            .map((club) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(club['icon']!, height: 100, width: 100),
                                  SizedBox(height: 10),
                                  Text(club['name']!, style: TextStyle(fontSize: 18)),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    if (_selectedLeague != null && _clubs[_selectedLeague!] != null && _clubs[_selectedLeague!]!.isNotEmpty)
                      ElevatedButton(
                        onPressed: selectClub,
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
                      hint: Text('Wybierz kraj'),
                      value: _selectedCountry,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                          _selectedLeague = null;
                          _selectedClubIndex = 0;
                        });
                      },
                      items: _countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                    ),
                    if (_selectedCountry != null)
                      DropdownButton<String>(
                        hint: Text('Wybierz ligę'),
                        value: _selectedLeague,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLeague = newValue;
                            _selectedClubIndex = 0;
                          });
                        },
                        items: _leagues[_selectedCountry!]!.map((String league) {
                          return DropdownMenuItem<String>(
                            value: league,
                            child: Text(league),
                          );
                        }).toList(),
                      ),
                    if (_selectedLeague != null && _clubs[_selectedLeague!] != null)
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          enlargeCenterPage: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _selectedClubIndex = index;
                            });
                          },
                        ),
                        items: _clubs[_selectedLeague!]!
                            .where((club) => !_isClubSelected(club['name']!))
                            .map((club) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(club['icon']!, height: 100, width: 100),
                                  SizedBox(height: 10),
                                  Text(club['name']!, style: TextStyle(fontSize: 18)),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    if (_selectedLeague != null && _clubs[_selectedLeague!] != null && _clubs[_selectedLeague!]!.isNotEmpty)
                      ElevatedButton(
                        onPressed: selectClub,
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
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${entry.key}: ${entry.value['name']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          if (entry.value['icon'] != null && entry.value['icon']!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Image.network(
                                entry.value['icon']!,
                                width: 20,
                                height: 20,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
