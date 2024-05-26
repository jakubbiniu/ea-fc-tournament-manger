import 'dart:async';
import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  final FirebaseAuth auth;
  final DatabaseReference databaseRef;

  const CreateAccountPage({Key? key, required this.auth, required this.databaseRef}) : super(key: key);

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

String _getTranslatedErrorMessage(dynamic e) {
  Map<String, String> errorMessages = {
    "email-already-in-use": "Adres e-mail jest już używany",
    "weak-password": "Hasło powinno zawierać co najmniej 6 znaków",
    "nickname-already-in-use": "Nick jest już używany",
  };
  return errorMessages[e.code] ?? "Wystąpił błąd: ${e.toString()}";
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _errorController = TextEditingController();

  Future<void> _createAccountWithEmailAndPassword() async {
    try {
      final _dbRef = FirebaseDatabase.instance.ref();
      DatabaseReference usersRef = _dbRef.child('users');
      usersRef.once().then((DatabaseEvent event) async {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
        bool _foundUser = false;
        if (data != null) {
          for (var userId in data.keys) {
            var userData = data[userId];
            if (userData['nickname'] == _nicknameController.text) {
              _foundUser = true;
              break;
            }
          }
          if (_foundUser) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Podany nick jest już zajęty")));
            return;
          } else {
            final UserCredential userCredential = await widget.auth.createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

            if (userCredential.user != null) {
              String nickname = _nicknameController.text;
              String userId = userCredential.user!.uid;

              await widget.databaseRef.child('users').child(userId).set({
                'email': _emailController.text,
                'nickname': nickname,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Twoje konto zostało pomyślnie utworzone!'),
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(auth: widget.auth), // Przekazanie użytkownika do ekranu logowania
                ),
              );
            }
          }
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wystąpił błąd podczas tworzenia konta")));
      });
    } catch (e) {
      String errorMessage = _getTranslatedErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tworzenie konta'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Utwórz swoje konto',
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
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Nick',
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createAccountWithEmailAndPassword,
              child: const Text('Utwórz konto'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}