import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth2/pages/home.dart';
import 'package:firebase_auth2/pages/signUp.dart';
import 'package:firebase_auth2/services/auth.dart';
import 'package:flutter/material.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";
  bool isLoading = false;

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  userLogin() async {
    // Don't proceed if already loading
    if (isLoading) return;

    // Validate all fields are filled
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              "Please fill all fields",
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        ),
      );
      return;
    }

    // Email validation
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              "Please enter a valid email address",
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Clear fields after successful login
      emailController.clear();
      passwordController.clear();

      setState(() {
        email = '';
        password = '';
      });

      // Navigate to home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Home()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed";

      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This account has been disabled";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many attempts. Try again later";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
            content: Center(
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
            content: Center(
              child: Text(
                "An error occurred: $e",
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Image.asset(
              "assets/images/bg.png",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 60.0, left: 30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Start your journey today!",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 4),
                    Container(
                      padding: EdgeInsets.only(left: 20.0),
                      margin: EdgeInsets.only(right: 30.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(115, 0, 0, 0),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your email",
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Container(
                      padding: EdgeInsets.only(left: 20.0),
                      margin: EdgeInsets.only(right: 30.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(115, 0, 0, 0),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your password",
                        ),
                      ),
                    ),
                    SizedBox(height: 90.0),
                    GestureDetector(
                      onTap: isLoading ? null : userLogin,
                      child: Container(
                        height: 60,
                        margin: EdgeInsets.only(right: 30.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: isLoading ? Colors.grey : Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "LogIn",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => SignUp()),
                              (route) => false,
                            );
                          },
                          child: Text(
                            "SignUp",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Divider(color: const Color.fromARGB(106, 0, 0, 0)),
                    ),
                    SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Sign-In Button
                        GestureDetector(
                          onTap:
                              isLoading
                                  ? null
                                  : () async {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    try {
                                      await AuthMethods().signInWithGoogle(
                                        context,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                          child: Image.asset(
                            "assets/images/google.png",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 50.0),
                        // Apple Sign-In Button
                        GestureDetector(
                          onTap:
                              isLoading
                                  ? null
                                  : () async {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    try {
                                      await AuthMethods().signInWithApple(
                                        context,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                          child: Image.asset(
                            "assets/images/apple-logo.png",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
