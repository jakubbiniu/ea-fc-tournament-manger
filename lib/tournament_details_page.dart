import 'package:ea_fc_tournament_manager/tournaments_tabs_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'tournament_info_page.dart';
import 'tournament_current_match_page.dart';
import 'tournament_table_page.dart';
import 'club_selection_page.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;
  final String userId;

  TournamentDetailsPage({required this.tournamentId, required this.userId});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool isTournamentStarted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkIfTournamentStarted();
  }

  void checkIfTournamentStarted() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/started').onValue.listen((event) {
      final started = event.snapshot.value as bool? ?? false;
      setState(() {
        isTournamentStarted = started;
      });
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => TournamentTabsPage(userId: widget.userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _handleBackButton,
        ),
        title: Center(child: Text('Szczegóły turnieju')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Informacje'),
            Tab(text: isTournamentStarted ? 'Aktualny mecz' : 'Wybór klubów'),
            Tab(text: 'Tabela'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TournamentInfoPage(tournamentId: widget.tournamentId),
          isTournamentStarted
              ? TournamentCurrentMatchPage(tournamentId: widget.tournamentId, userId: widget.userId)
              : ClubSelectionPage(tournamentId: widget.tournamentId, userId: widget.userId),
          TournamentTablePage(tournamentId: widget.tournamentId),
        ],
      ),
    );
  }
}
