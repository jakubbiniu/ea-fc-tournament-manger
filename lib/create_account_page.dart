import 'dart:async';

import 'package:ea_fc_tournament_manager/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  final FirebaseAuth auth;
  final DatabaseReference databaseRef; // Dodana referencja do bazy danych

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
  final TextEditingController _phoneController = TextEditingController();
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
          }
          else{
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
                'password': _passwordController.text,
                'phone': _phoneController.text,
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
        } else {
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
              decoration: InputDecoration(labelText: 'Nick'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Hasło'),
              obscureText: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Numer telefonu'),
              keyboardType: TextInputType.phone,
            ),
            ElevatedButton(
              onPressed: _createAccountWithEmailAndPassword,
              child: const Text('Utwórz konto'),
            ),
          ],
        ),
      ),
    );
  }
}
