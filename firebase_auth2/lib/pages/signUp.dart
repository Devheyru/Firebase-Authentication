import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth2/pages/home.dart';
import 'package:firebase_auth2/services/db.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = '', password = '', name = '';
  bool isLoading = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  registration() async {
    // Don't proceed if already loading
    if (isLoading) return;

    // Validate all fields are filled
    if (passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              "Please fill all fields",
              style: TextStyle(fontSize: 18.0),
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
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ),
      );
      return;
    }

    // Password length validation
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
          content: Center(
            child: Text(
              "Password should be at least 6 characters",
              style: TextStyle(fontSize: 18.0),
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
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      Map<String, dynamic> userInfoMap = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "uid": userCredential.user!.uid,
      };

      await DatabaseMethods().addUserDetails(userInfoMap);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
          content: Center(
            child: Text(
              "Registered Successfully",
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        ),
      );
      // Clear all form fields after successful registration
      nameController.clear();
      emailController.clear();
      passwordController.clear();

      // Reset the state variables (optional)
      setState(() {
        name = '';
        email = '';
        password = '';
      });

      // Only navigate if still mounted
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed";

      if (e.code == 'weak-password') {
        errorMessage = "Password Provided is too Weak";
      } else if (e.code == "email-already-in-use") {
        errorMessage = "Account Already exists";
      } else if (e.code == "invalid-email") {
        errorMessage = "Invalid email address";
      } else if (e.code == "operation-not-allowed") {
        errorMessage = "Email/password accounts are not enabled";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
            content: Center(
              child: Text(errorMessage, style: TextStyle(fontSize: 18.0)),
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
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        );
      }
    } finally {
      // Always check if widget is still mounted before calling setState
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
      backgroundColor: Colors.blue,
      body: Container(
        child: Stack(
          children: [
            Image.asset(
              'assets/images/bg.png',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.fill,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 60, left: 20),

              child: AbsorbPointer(
                absorbing: isLoading,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create account",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Start your journey today",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 6),
                      Container(
                        padding: EdgeInsets.only(left: 20.0),
                        margin: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(115, 0, 0, 0),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Your name",
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.only(left: 20.0),
                        margin: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(115, 0, 0, 0),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Your email",
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 20.0),
                        margin: EdgeInsets.only(right: 20, top: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(115, 0, 0, 0),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Your password",
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap:
                            isLoading
                                ? null
                                : () {
                                  // Disable when loading
                                  registration();
                                },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.only(right: 20, top: 90.0),
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                isLoading
                                    ? Colors.blueGrey
                                    : Colors.blue, // Visual feedback
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child:
                                isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      "SignUp",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Divider(color: Colors.blueAccent),
                      ),
                      SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/google.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 50.0),
                          Image.asset(
                            "assets/images/apple-logo.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
