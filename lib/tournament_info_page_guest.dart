import 'package:flutter/material.dart';
import 'database_helper.dart';

class TournamentInfoPageGuest extends StatelessWidget {
  final int tournamentId;

  TournamentInfoPageGuest({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
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

        return ListView(
          children: <Widget>[
            ListTile(title: Text('Nazwa turnieju: ${tournament['name']}')),
            ListTile(title: Text('Status: ${isEnded ? "Zakończony" : "Trwa"}')),
            ListTile(title: Text('Uczestnicy:')),
            ...List<Widget>.from((tournament['players'] as List).map(
                  (player) {
                String playerName = player.toString();
                if (isStarted && selectedClubs.containsKey(playerName)) {
                  String clubName = selectedClubs[playerName]!['name']!;
                  String clubIcon = selectedClubs[playerName]!['icon']!;
                  return ListTile(
                    title: Row(
                      children: [
                        Text('$playerName - $clubName'),
                        SizedBox(width: 8),
                        Image.network(clubIcon, width: 20, height: 20),
                      ],
                    ),
                  );
                } else {
                  return ListTile(title: Text(playerName));
                }
              },
            )),
          ],
        );
      },
    );
  }
}
