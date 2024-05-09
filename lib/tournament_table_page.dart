import 'package:flutter/material.dart';

class TournamentTablePage extends StatelessWidget {
  final String tournamentId;

  TournamentTablePage({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tabela wyników dla turnieju $tournamentId"));
  }
}
