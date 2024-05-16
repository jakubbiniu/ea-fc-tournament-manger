import 'package:flutter/material.dart';
import 'ended_tournament_page.dart';
import 'create_tournament_page.dart';
import 'upcoming_tournament_page.dart';

class TournamentTabsPage extends StatefulWidget {
  final String userId;

  TournamentTabsPage({required this.userId});

  @override
  _TournamentTabsPageState createState() => _TournamentTabsPageState();
}

class _TournamentTabsPageState extends State<TournamentTabsPage> with SingleTickerProviderStateMixin {
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
        title: Center(child: Text('Turnieje')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Zakończone turnieje'),
            Tab(text: 'Stwórz turniej'),
            Tab(text: 'Nadchodzące turnieje'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EndedTournamentsPage(userId: widget.userId),
          CreateTournamentPage(userId: widget.userId),
          UpcomingTournamentsPage(userId: widget.userId),
        ],
      ),
    );
  }
}
