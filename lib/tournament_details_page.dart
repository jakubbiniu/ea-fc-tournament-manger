import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'tournament_info_page.dart';
import 'tournament_current_match_page.dart';
import 'tournament_table_page.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  TournamentDetailsPage({required this.tournamentId});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Szczegóły turnieju')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Informacje'),
            Tab(text: 'Aktualny mecz'),
            Tab(text: 'Tabela'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TournamentInfoPage(tournamentId: widget.tournamentId),
          TournamentCurrentMatchPage(tournamentId: widget.tournamentId),
          TournamentTablePage(tournamentId: widget.tournamentId)
        ],
      ),
    );
  }
}
