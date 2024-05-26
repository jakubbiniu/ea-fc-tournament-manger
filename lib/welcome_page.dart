import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'tournaments_tabs_page.dart';

class WelcomePage extends StatelessWidget {
  final User user;

  const WelcomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'EA FC TOURNAMENT MANAGER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Wylogowano!'),
                  duration: Duration(seconds: 3), // Czas wyświetlania komunikatu
                ),
              );
              final auth = FirebaseAuth.instance;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(auth: auth),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: TournamentTabsPage(userId: user.email!, user: user),
    );
  }
}
