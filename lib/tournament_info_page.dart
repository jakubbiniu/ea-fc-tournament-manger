import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class TournamentInfoPage extends StatelessWidget {
  final String tournamentId;

  TournamentInfoPage({required this.tournamentId});

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return "${placemarks.first.locality}, ${placemarks.first.street}";
      }
      return "Nieznana lokalizacja";
    } catch (e) {
      return "Problem z lokalizacją: $e";
    }
  }

  Future<void> _launchMapsUrl(double latitude, double longitude) async {
    Uri googleMapsUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    } else {
      throw 'Nie udało się załadować: $googleMapsUri';
    }
  }

  Future<Map<String, Map<String, String>>> _fetchPlayerClubs() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('tournaments/$tournamentId/player_clubs');
    DatabaseEvent event = await ref.once();
    Map<String, Map<String, String>> playerClubs = {};
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> clubsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      clubsMap.forEach((key, value) {
        playerClubs[key] = Map<String, String>.from(value as Map);
      });
    }
    return playerClubs;
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('tournaments').child(tournamentId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Szczegóły Turnieju'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("Brak danych turnieju."));
          }

          Map<dynamic, dynamic> tournament = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          bool isEnded = tournament['ended'] ?? false;
          String location = tournament['location'];

          return FutureBuilder<Map<String, Map<String, String>>>(
            future: _fetchPlayerClubs(),
            builder: (context, playerClubsSnapshot) {
              if (!playerClubsSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              Map<String, Map<String, String>> playerClubs = playerClubsSnapshot.data!;
              List<Widget> playerWidgets = [];

              if (tournament['players'] != null) {
                for (var player in tournament['players']) {
                  String playerName = player['name'].toString();
                  Widget playerWidget;

                  if (playerClubs.containsKey(playerName)) {
                    String clubName = playerClubs[playerName]!['name']!;
                    String clubIcon = playerClubs[playerName]!['icon']!;
                    playerWidget = ListTile(
                      leading: Image.network(clubIcon, width: 40, height: 40),
                      title: Text('$playerName - $clubName'),
                    );
                  } else {
                    playerWidget = ListTile(
                      title: Text(playerName),
                    );
                  }

                  playerWidgets.add(playerWidget);
                }
              }

              if (location.toLowerCase() == 'online') {
                return ListView(
                  padding: EdgeInsets.all(16.0),
                  children: <Widget>[
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Status: ${isEnded ? "Zakończony" : "Trwa"}'),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Nazwa: ${tournament['name']}'),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Data: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(tournament['date']))}'),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Lokalizacja: Online'),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Uczestnicy:'),
                        subtitle: Column(
                          children: playerWidgets,
                        ),
                      ),
                    ),
                  ],
                );
              }

              var parts = location.split(',');
              double lat = double.parse(parts[0]);
              double lng = double.parse(parts[1]);

              return FutureBuilder<String>(
                future: _getAddressFromCoordinates(lat, lng),
                builder: (BuildContext context, AsyncSnapshot<String> addressSnapshot) {
                  String displayAddress = addressSnapshot.data ?? "Ładowanie adresu...";

                  return ListView(
                    padding: EdgeInsets.all(16.0),
                    children: <Widget>[
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Status: ${isEnded ? "Zakończony" : "Trwa"}'),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Nazwa: ${tournament['name']}'),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Data: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(tournament['date']))}'),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Lokalizacja: $displayAddress'),
                          trailing: IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () async {
                              _launchMapsUrl(lat, lng);
                            },
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Uczestnicy:'),
                          subtitle: Column(
                            children: playerWidgets,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
