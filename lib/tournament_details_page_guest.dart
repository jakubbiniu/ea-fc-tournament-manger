import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'tournament_info_page_guest.dart';
import 'tournament_current_match_page_guest.dart';
import 'tournament_table_page_guest.dart';

class TournamentDetailsPageGuest extends StatefulWidget {
  final int tournamentId;

  TournamentDetailsPageGuest({required this.tournamentId});

  @override
  _TournamentDetailsPageGuestState createState() => _TournamentDetailsPageGuestState();
}

class _TournamentDetailsPageGuestState extends State<TournamentDetailsPageGuest> with SingleTickerProviderStateMixin {
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
          TournamentInfoPageGuest(tournamentId: widget.tournamentId),
          TournamentCurrentMatchPageGuest(tournamentId: widget.tournamentId),
          TournamentTablePageGuest(tournamentId: widget.tournamentId)
        ],
      ),
    );
  }
}
