import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'tournament_details_page.dart';

class EndedTournamentsPage extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('tournaments');
  final String userId;

  EndedTournamentsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _dbRef.orderByChild('ended').equalTo(true).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("Brak zakończonych turniejów."));
          }

          Map<dynamic, dynamic> tournaments = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Widget> tournamentWidgets = [];
          tournaments.forEach((key, value) {
            List<dynamic> players = value['players'];
            bool isUserInTournament = players.any((player) => player['id'] == userId);
            if (isUserInTournament) {
              DateTime date = DateTime.fromMillisecondsSinceEpoch(value['date']);
              tournamentWidgets.add(ListTile(
                title: Text(value['name']),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(date)),
                trailing: Icon(Icons.check, color: Colors.green),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentDetailsPage(tournamentId: key, userId: userId),
                    ),
                  );
                },
              ));
            }
          });

          return ListView(
            children: tournamentWidgets.isNotEmpty
                ? tournamentWidgets
                : [Center(child: Text("Nie uczestniczyłeś w żadnych zakończonych turniejach."))],
          );
        },
      ),
    );
  }
}
