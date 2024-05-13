import 'package:flutter/material.dart';

class TournamentTablePageGuest extends StatelessWidget {
  final int tournamentId;

  TournamentTablePageGuest({required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tabela wyników dla turnieju $tournamentId"));
  }
}
