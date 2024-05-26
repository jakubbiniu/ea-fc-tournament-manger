import 'package:ea_fc_tournament_manager/login_page.dart';
import 'package:ea_fc_tournament_manager/tournaments_tabs_page.dart';
import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'tournament_info_page.dart';
import 'tournament_current_match_page.dart';
import 'tournament_table_page.dart';
import 'club_selection_page.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;
  final String userId;
  final User user;

  TournamentDetailsPage({required this.tournamentId, required this.userId, required this.user});

  @override
  _TournamentDetailsPageState createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isTournamentStarted = false;
  String tournamentName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    checkIfTournamentStarted();
    fetchTournamentName();
  }

  void checkIfTournamentStarted() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/started').onValue.listen((event) {
      final started = event.snapshot.value as bool? ?? false;
      setState(() {
        isTournamentStarted = started;
      });
    });
  }

  void fetchTournamentName() {
    FirebaseDatabase.instance.ref('tournaments/${widget.tournamentId}/name').once().then((DatabaseEvent event) {
      final name = event.snapshot.value as String? ?? 'Turniej';
      setState(() {
        tournamentName = name;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => WelcomePage(user: widget.user),
    ));
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    bool isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: isSelected ? BorderRadius.circular(20) : BorderRadius.zero,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.black54),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBackButton,
        ),
        title: Text('Turniej: $tournamentName', style: TextStyle(color: Colors.white)),
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Stack(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildTabItem(0, 'Informacje', Icons.info),
                  _buildTabItem(1, isTournamentStarted ? 'Aktualny mecz' : 'Wybór klubów', Icons.sports_soccer),
                  _buildTabItem(2, 'Tabela', Icons.table_chart),
                ],
              ),
            ],
          ),
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
