import 'package:ea_fc_tournament_manager/login_page.dart';
import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ea_fc_tournament_manager/tournaments_tabs_page.dart';
import 'club_selection_guest_page.dart';
import 'tournament_info_page_guest.dart';
import 'tournament_current_match_page_guest.dart';
import 'tournament_table_page_guest.dart';
import 'database_helper.dart';

class TournamentDetailsPageGuest extends StatefulWidget {
  final int tournamentId;

  TournamentDetailsPageGuest({required this.tournamentId});

  @override
  _TournamentDetailsPageGuestState createState() => _TournamentDetailsPageGuestState();
}

class _TournamentDetailsPageGuestState extends State<TournamentDetailsPageGuest> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool isTournamentStarted = false;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkIfTournamentStarted();
  }

  void checkIfTournamentStarted() async {
    var tournamentData = await dbHelper.getTournamentData(widget.tournamentId);
    if (tournamentData != null && tournamentData['started'] == true) {
      setState(() {
        isTournamentStarted = true;
      });
    }
    dbHelper.getTournamentStream(widget.tournamentId).listen((tournamentData) {
      if (tournamentData['started'] == true) {
        setState(() {
          isTournamentStarted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _handleBackButton() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => LoginPage(auth: FirebaseAuth.instance),
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
          TournamentInfoPageGuest(tournamentId: widget.tournamentId),
          isTournamentStarted
              ? TournamentCurrentMatchPageGuest(tournamentId: widget.tournamentId)
              : ClubSelectionPageGuest(tournamentId: widget.tournamentId),
          TournamentTablePageGuest(tournamentId: widget.tournamentId),
        ],
      ),
    );
  }
}
