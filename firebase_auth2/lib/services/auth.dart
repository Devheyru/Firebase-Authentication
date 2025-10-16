import 'package:firebase_auth2/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For google_sign_in ^7.2.0 - use the standard constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In method
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      print("Starting Google Sign-In...");

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("Google user: $googleUser");

      // Check if user cancelled sign-in
      if (googleUser == null) {
        print("User cancelled Google sign-in");
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("Google auth obtained");

      // Debug print tokens
      print("ID Token: ${googleAuth.idToken != null ? 'present' : 'null'}");
      print(
        "Access Token: ${googleAuth.accessToken != null ? 'present' : 'null'}",
      );

      // Check if we have the required tokens
      if (googleAuth.accessToken == null) {
        _showErrorSnackBar(context, "Failed to get access token from Google");
        return;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Firebase credential created");

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      print("Firebase user: $user");

      if (user != null) {
        print("User signed in successfully: ${user.uid}");
        // Save user data to Firestore if it's a new user
        await _saveUserToFirestore(user);

        // Navigate to home page
        _navigateToHome(context);
      } else {
        _showErrorSnackBar(context, "Failed to sign in to Firebase");
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      _showErrorSnackBar(context, "Google sign-in failed: ${e.message}");
    } on PlatformException catch (e) {
      print("Platform Exception: ${e.code} - ${e.message}");
      _showErrorSnackBar(context, "Sign-in failed: ${e.message}");
    } catch (e) {
      print("Google Sign-In Error: $e");
      _showErrorSnackBar(context, "Failed to sign in with Google");
    }
  }

  // Alternative method if the above doesn't work
  Future<void> signInWithGoogleAlternative(BuildContext context) async {
    try {
      // Alternative approach with explicit configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(user);
        _navigateToHome(context);
      }
    } catch (e) {
      print("Alternative Google Sign-In Error: $e");
      _showErrorSnackBar(context, "Failed to sign in with Google");
    }
  }

  // Apple Sign-In
  Future<void> signInWithApple(BuildContext context) async {
    try {
      // Check if Apple Sign-In is available on the device
      if (!await TheAppleSignIn.isAvailable()) {
        _showErrorSnackBar(
          context,
          "Apple Sign-In is not available on this device",
        );
        return;
      }

      // Perform Apple Sign-In request
      final result = await TheAppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName]),
      ]);

      // Handle the authorization result
      switch (result.status) {
        case AuthorizationStatus.authorized:
          final appleIdCredential = result.credential!;

          // Check if we have the required tokens
          if (appleIdCredential.identityToken == null) {
            _showErrorSnackBar(
              context,
              "Apple Sign-In failed: Missing identity token",
            );
            return;
          }

          // Create OAuth credential for Firebase
          final oAuthCredential = OAuthProvider("apple.com").credential(
            idToken: String.fromCharCodes(appleIdCredential.identityToken!),
            accessToken:
                appleIdCredential.authorizationCode != null
                    ? String.fromCharCodes(appleIdCredential.authorizationCode!)
                    : null,
          );

          // Sign in to Firebase with Apple credentials
          final userCredential = await _auth.signInWithCredential(
            oAuthCredential,
          );
          final user = userCredential.user;

          if (user != null) {
            // Update user profile with Apple provided data
            await _updateUserProfileWithAppleData(user, appleIdCredential);

            // Save user data to Firestore
            await _saveUserToFirestore(user);

            // Navigate to home page
            _navigateToHome(context);
          }
          break;

        case AuthorizationStatus.error:
          _showErrorSnackBar(
            context,
            "Apple Sign-In failed: ${result.error?.toString() ?? 'Unknown error'}",
          );
          break;

        case AuthorizationStatus.cancelled:
          // User cancelled, no need to show error
          print("Apple Sign-In cancelled by user");
          break;
      }
    } on PlatformException catch (e) {
      print("Platform Exception during Apple Sign-In: $e");
      _showErrorSnackBar(context, "Apple Sign-In failed: ${e.message}");
    } catch (e) {
      print("Apple Sign-In Error: $e");
      _showErrorSnackBar(context, "Failed to sign in with Apple");
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection("users").doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          "Name": user.displayName ?? "User",
          "Email": user.email ?? "",
          "Id": user.uid,
          "Image": user.photoURL ?? "",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
        print("New user saved to Firestore: ${user.uid}");
      } else {
        // Update existing user data if needed
        await userDoc.update({"updatedAt": FieldValue.serverTimestamp()});
        print("Existing user updated in Firestore: ${user.uid}");
      }
    } catch (e) {
      print("Error saving user to Firestore: $e");
    }
  }

  // Update user profile with Apple data
  Future<void> _updateUserProfileWithAppleData(
    User user,
    AppleIdCredential appleIdCredential,
  ) async {
    try {
      final fullName = appleIdCredential.fullName;

      // Update display name if available from Apple
      if (fullName != null &&
          fullName.givenName != null &&
          fullName.familyName != null) {
        final displayName =
            '${fullName.givenName} ${fullName.familyName}'.trim();

        // Update Firebase user profile
        await user.updateDisplayName(displayName);

        // Also update in Firestore
        await _firestore.collection("users").doc(user.uid).update({
          "Name": displayName,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        print("Updated user profile with Apple data: $displayName");
      }
    } catch (e) {
      print("Error updating user profile with Apple data: $e");
    }
  }

  // Navigate to home page
  void _navigateToHome(BuildContext context) {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),
        (route) => false,
      );
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      );
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
