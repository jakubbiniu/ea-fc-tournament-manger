import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'login_page.dart'; // Zaimportuj odpowiedni pakiet

class CreateAccountPage extends StatefulWidget {
  final FirebaseAuth auth;
  final DatabaseReference databaseRef; // Dodana referencja do bazy danych

  const CreateAccountPage({Key? key, required this.auth, required this.databaseRef}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  Future<void> _createAccountWithEmailAndPassword() async {
    try {
      final UserCredential userCredential = await widget.auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Jeśli konto zostało utworzone, zapisz dane użytkownika do Firebase Realtime Database
      if (userCredential.user != null) {
        // Pobierz nickname z kontrolera
        String nickname = _nicknameController.text;
        String userId = userCredential.user!.uid;

        // Zapisz dane użytkownika do bazy danych
        await widget.databaseRef.child('users').child(userId).set({
          'email': _emailController.text,
          'nickname': nickname,
          'password': _passwordController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Twoje konto zostało pomyślnie utworzone!'),
            duration: Duration(seconds: 3), // Czas wyświetlania komunikatu
          ),
        );
        // Przejdź do kolejnego ekranu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(auth: widget.auth), // Przekazanie użytkownika do ekranu powitalnego
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          duration: Duration(seconds: 3),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
              controller: _nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'), // Nowe pole nickname
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _createAccountWithEmailAndPassword,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
