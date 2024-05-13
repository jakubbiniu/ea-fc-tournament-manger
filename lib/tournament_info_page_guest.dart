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

        return ListView(
          children: <Widget>[
            ListTile(title: Text('Nazwa turnieju: ${tournament['name']}')),
            ListTile(title: Text('Status: ${isEnded ? "Zakończony" : "Trwa"}')),
            ListTile(title: Text('Uczestnicy:')),
            ...List<Widget>.from((tournament['players'] as List).map(
                    (player) => ListTile(title: Text(player.toString()))
            )),
          ],
        );
      },
    );
  }
}
