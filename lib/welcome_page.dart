import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  final User user;

  const WelcomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
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
      ),
      body: Center(
        child: Text('Welcome, ${user.displayName ?? user.email}!'), // Wyświetl nick użytkownika lub adres e-mail, jeśli nick nie jest dostępny
      ),
    );
  }
}
