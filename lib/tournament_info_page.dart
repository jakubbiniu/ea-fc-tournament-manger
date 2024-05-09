import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TournamentInfoPage extends StatelessWidget {
  final String tournamentId;

  TournamentInfoPage({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('tournaments').child(tournamentId);

    return StreamBuilder<DatabaseEvent>(
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

        return ListView(
          children: <Widget>[
            ListTile(title: Text('Status: ${isEnded ? "Zakończony" : "Trwa"}')),
            ListTile(title: Text('Nazwa: ${tournament['name']}')),
            ListTile(title: Text('Data: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(tournament['date']))}')),
            ListTile(title: Text('Miejsce: ${tournament['location']}')),
            ListTile(title: Text('Uczestnicy:')),
            ...List<Widget>.from((tournament['players'] as List).map((player) => ListTile(title: Text(player.toString())))),
          ],
        );
      },
    );
  }
}
