import 'dart:developer';

import 'package:ea_fc_tournament_manager/create_tournament_page_guest.dart';
import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        // Sprawdzenie, czy konto z podanym adresem email istnieje
        try {
          final List<String> signInMethods = await widget.auth.fetchSignInMethodsForEmail(_emailController.text);
          if (signInMethods.isEmpty) {
            _showErrorSnackbar('Nie istnieje konto z podanym mailem.');
          } else {
            _showErrorSnackbar('Podano złe hasło.');
          }
        } catch (e) {
          _showErrorSnackbar('Nie udało się zweryfikować danych. Spróbuj ponownie.');
        }
      } else if (e.code == 'invalid-email') {
        _showErrorSnackbar('Podany email jest nieprawidłowy.');
      } else if (e.code == 'user-disabled') {
        _showErrorSnackbar('Konto zostało dezaktywowane.');
      } else if (e.code == 'too-many-requests') {
        _showErrorSnackbar('Zbyt wiele nieudanych prób logowania. Spróbuj ponownie później.');
      } else {
        _showErrorSnackbar('Nie udało się zalogować. Spróbuj ponownie.');
      }
    }
  }

  Future<void> _resetPassword() async {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Resetowanie hasła'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (emailController.text.isEmpty) {
                  _showErrorSnackbar('Podaj adres e-mail, aby zresetować hasło.');
                  return;
                }

                try {
                  await widget.auth.sendPasswordResetEmail(email: emailController.text);
                  _showErrorSnackbar('Email z instrukcją resetowania hasła został wysłany.');
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'invalid-email') {
                    _showErrorSnackbar('Podany email jest nieprawidłowy.');
                  } else if (e.code == 'user-not-found') {
                    _showErrorSnackbar('Nie istnieje konto z podanym mailem.');
                  } else {
                    _showErrorSnackbar('Nie udało się wysłać emaila. Spróbuj ponownie.');
                  }
                }
              },
              child: Text('Wyślij'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3), // Czas wyświetlania komunikatu
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Logowanie'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Witaj w naszej aplikacji!',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Hasło',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  onPressed: _resetPassword,
                  child: const Text('Zapomniałeś hasła?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: _signInWithEmailAndPassword,
                child: Text(
                  'Zaloguj się',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseHelper.instance.watchAllTournaments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var tournament = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          tournament['name'] ?? 'Bez nazwy',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailsPageGuest(tournamentId: tournament['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
