import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tournament_details_page_guest.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ClubSelectionPageGuest extends StatefulWidget {
  final int tournamentId;

  ClubSelectionPageGuest({required this.tournamentId});

  @override
  _ClubSelectionPageGuestState createState() => _ClubSelectionPageGuestState();
}

class _ClubSelectionPageGuestState extends State<ClubSelectionPageGuest> {
  final List<String> _countries = [];
  final Map<String, List<String>> _leagues = {};
  final Map<String, List<Map<String, String>>> _clubs = {};
  List<Map<String, dynamic>> _players = [];
  final List<String> _availableClubs = [];
  final Map<String, Map<String, String>> _selectedClubs = {};
  Map<String, dynamic>? _selectedPlayer;
  String? _selectedCountry;
  String? _selectedLeague;
  int _selectedClubIndex = 0;
  final random = Random();
  late StreamController<int> _wheelNotifier;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _wheelNotifier = StreamController<int>.broadcast();
    fetchPlayers();
    fetchCountriesAndTeams();
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

        _selectedClubs.clear();
        if (tournamentData['selectedClubs'] != null) {
          Map<String, dynamic> clubsMap = Map<String, dynamic>.from(tournamentData['selectedClubs']);
          clubsMap.forEach((key, value) {
            _selectedClubs[key] = Map<String, String>.from(value);
          });
        }

        _players = _players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
        _availableClubs.clear();
      });
    }
  }

  void listenToSelectedClubs() async {
    var tournamentData = await dbHelper.getTournamentData(widget.tournamentId);
    if (tournamentData != null && tournamentData['selectedClubs'] != null) {
      setState(() {
        _selectedClubs.clear();

        Map<String, dynamic> clubsMap = Map<String, dynamic>.from(tournamentData['selectedClubs']);
        clubsMap.forEach((key, value) {
          _selectedClubs[key] = Map<String, String>.from(value);
        });

        _players = _players.where((player) => !_selectedClubs.containsKey(player['name'])).toList();
      });
    }
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
    if (_players.isEmpty) return;
    final index = random.nextInt(_players.length);
    _wheelNotifier.add(index);
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _selectedPlayer = _players[index];
      });
    });
  }

  void selectClub(String clubName, String clubIcon) async {
    if (_selectedPlayer != null) {
      final playerName = _selectedPlayer!['name'];
      setState(() {
        _selectedClubs[playerName] = {'name': clubName, 'icon': clubIcon};
        _players = _players.where((player) => player['name'] != playerName).toList();
        _selectedPlayer = null;
        _selectedCountry = null;
        _selectedLeague = null;
        _selectedClubIndex = 0;
        fetchCountriesAndTeams();
      });
      await dbHelper.updateTournamentPlayerClub(widget.tournamentId, _selectedClubs);

      if (_players.length == 1) {
        setState(() {
          _selectedPlayer = _players.first;
        });
      } else if (_players.isEmpty) {
        setState(() {
          _selectedPlayer = null;
        });
      }
    } else if (_selectedPlayer == null && _players.length == 1) {
      final playerName = _players.first['name'];
      setState(() {
        _selectedPlayer = _players.first;
        _selectedClubs[playerName] = {'name': clubName, 'icon': clubIcon};
        _players = _players.where((player) => player['name'] != playerName).toList();
        _selectedPlayer = null;
        _selectedCountry = null;
        _selectedLeague = null;
        _selectedClubIndex = 0;
        fetchCountriesAndTeams();
      });
      await dbHelper.updateTournamentPlayerClub(widget.tournamentId, _selectedClubs);
    }

    if (_players.isEmpty) {
      setState(() {
        _selectedPlayer = null;
      });
    }
  }



  void startTournament() async {
    await dbHelper.startTournament(widget.tournamentId);
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => TournamentDetailsPageGuest(tournamentId: widget.tournamentId),
    ));
  }

  bool get shouldHideWheel {
    if (_selectedPlayer != null) {
      return true;
    }
    if (_players.length <= 1) {
      return true;
    }
    return false;
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
                  if (_selectedPlayer == null && _players.length > 1)
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
                                setState(() {
                                  _selectedPlayer = _players[snapshot.data!];
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  if (_selectedPlayer != null) ...[
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
                        items: _clubs[_selectedLeague!]!.map((club) {
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
                        onPressed: () {
                          final selectedClub = _clubs[_selectedLeague!]![_selectedClubIndex];
                          selectClub(selectedClub['name']!, selectedClub['icon']!);
                        },
                        child: Text('Zatwierdź klub'),
                      ),
                  ] else if (_selectedPlayer == null && _players.length == 1) ...[
                    Text(
                      'Ostatni gracz: ${_players.first['name']} wybiera klub',
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
                        items: _clubs[_selectedLeague!]!.map((club) {
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
                        onPressed: () {
                          final selectedClub = _clubs[_selectedLeague!]![_selectedClubIndex];
                          selectClub(selectedClub['name']!, selectedClub['icon']!);
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
      ),
    );
  }
}
