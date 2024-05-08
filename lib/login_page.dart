import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_account_page.dart';

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
      // Jeśli logowanie powiodło się, przejdź do kolejnego ekranu
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomePage(user: userCredential.user!),
          ),
        );
      }
    } catch (e) {
      // Obsłuż błąd logowania
      print('Sign in error: $e');
      // Tutaj możesz wyświetlić komunikat o błędzie dla użytkownika
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Przejdź do ekranu tworzenia konta
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAccountPage(auth: widget.auth, databaseRef: widget.databaseRef,),
                  ),
                );
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
