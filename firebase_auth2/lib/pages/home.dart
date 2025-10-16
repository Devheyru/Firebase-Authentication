import 'package:firebase_auth2/pages/logIn.dart';
import 'package:firebase_auth2/pages/signUp.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LogIn()),
                (route) => false,
              );
            },
            child: Center(
              heightFactor: 20,
              child: Text("Go back", style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }
}
