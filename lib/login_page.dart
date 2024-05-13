import 'dart:developer';

import 'package:ea_fc_tournament_manager/create_tournament_page_guest.dart';
import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_account_page.dart';
import 'tournament_details_page_guest.dart';
import 'database_helper.dart';

class LoginPage extends StatefulWidget {
  final FirebaseAuth auth;

  LoginPage({Key? key, required this.auth}) : super(key: key);

  // Tworzenie referencji do bazy danych
  final databaseRef = FirebaseDatabase.instance.reference(); // Zaimportuj odpowiedni pakiet

  @override
  _LoginPageState createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final UserCredential userCredential = await widget.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomePage(user: userCredential.user!),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zalogować'),
          duration: Duration(seconds: 3), // Czas wyświetlania komunikatu
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Hasło'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword,
              child: const Text('Zaloguj się'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAccountPage(auth: widget.auth, databaseRef: widget.databaseRef),
                  ),
                );
              },
              child: const Text('Utwórz konto'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTournamentPageGuest(),
                  ),
                );
              },
              child: const Text('Zagraj pojedynczy turniej jako gość'),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseHelper.instance.watchAllTournaments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return SizedBox.shrink();
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var tournament = snapshot.data![index];
                      return ListTile(
                        title: Text(tournament['name'] ?? 'Bez nazwy'),
                        trailing: Icon(Icons.arrow_forward, color: Colors.blue),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailsPageGuest(tournamentId: tournament['id']),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


}
