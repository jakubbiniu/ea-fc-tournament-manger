import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ended_tournament_page.dart';
import 'create_tournament_page.dart';
import 'upcoming_tournament_page.dart';

class TournamentTabsPage extends StatefulWidget {
  final String userId;
  final User user;
  TournamentTabsPage({required this.userId,required this.user});

  @override
  _TournamentTabsPageState createState() => _TournamentTabsPageState();
}

class _TournamentTabsPageState extends State<TournamentTabsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabItem(int index, String label) {
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
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
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
        automaticallyImplyLeading: false,
        title: Text(
          'Turnieje',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
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
                  _buildTabItem(0, 'Zakończone'),
                  _buildTabItem(1, 'Stwórz'),
                  _buildTabItem(2, 'Nadchodzące'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EndedTournamentsPage(userId: widget.userId,user: widget.user),
          CreateTournamentPage(userId: widget.userId,user: widget.user),
          UpcomingTournamentsPage(userId: widget.userId,user: widget.user),
        ],
      ),
    );
  }
}
