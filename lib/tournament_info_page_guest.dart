import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class TournamentInfoPageGuest extends StatelessWidget {
  final int tournamentId;

  TournamentInfoPageGuest({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: DatabaseHelper.instance.getTournamentData(tournamentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Brak danych turnieju."));
          }

          Map<String, dynamic> tournament = snapshot.data!;
          bool isEnded = tournament['ended'] ?? false;
          bool isStarted = tournament['started'] ?? false;

          Map<String, Map<String, String>> selectedClubs = {};
          if (tournament['selectedClubs'] != null) {
            Map<dynamic, dynamic> rawSelectedClubs = tournament['selectedClubs'] as Map<dynamic, dynamic>;
            rawSelectedClubs.forEach((key, value) {
              selectedClubs[key as String] = Map<String, String>.from(value as Map);
            });
          }

          List<Widget> playerWidgets = [];
          if (tournament['players'] != null) {
            for (var player in tournament['players']) {
              String playerName = player.toString();
              if (isStarted && selectedClubs.containsKey(playerName)) {
                String clubName = selectedClubs[playerName]!['name']!;
                String clubIcon = selectedClubs[playerName]!['icon']!;
                playerWidgets.add(
                  ListTile(
                    leading: Image.network(clubIcon, width: 40, height: 40),
                    title: Text('$playerName - $clubName'),
                  ),
                );
              } else {
                playerWidgets.add(ListTile(title: Text(playerName)));
              }
            }
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: <Widget>[
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('Nazwa turnieju: ${tournament['name']}'),
                ),
              ),
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
                  title: Text('Uczestnicy:'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: playerWidgets,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
