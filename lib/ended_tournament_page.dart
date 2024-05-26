import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'tournament_details_page.dart';

class EndedTournamentsPage extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('tournaments');
  final String userId;
  final User user;

  EndedTournamentsPage({required this.userId,required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Zakończone Turnieje', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
            bool isUserInTournament = players.any((player) => player['id'] == userId || player['second_id'] == userId);
            if (isUserInTournament) {
              DateTime date = DateTime.fromMillisecondsSinceEpoch(value['date']);
              tournamentWidgets.add(Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  title: Text(
                    value['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(date)),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentDetailsPage(tournamentId: key, userId: userId,user: user),
                      ),
                    );
                  },
                ),
              ));
            }
          });

          return tournamentWidgets.isNotEmpty
              ? ListView(
            padding: const EdgeInsets.all(8.0),
            children: tournamentWidgets,
          )
              : Center(child: Text("Nie uczestniczyłeś w żadnych zakończonych turniejach."));
        },
      ),
    );
  }
}
