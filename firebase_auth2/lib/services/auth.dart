import 'package:firebase_auth2/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;
  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '472514765293-vn9baacrggsh1924clcogi2teqvffvvc.apps.googleusercontent.com',
      );
    }
    isInitialize = true;
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Must initialize (v7.x)
      await googleSignIn.initialize();

      // Authenticate / sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        // user cancelled sign in
        return null;
      }

      // Get idToken
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: "ERROR_MISSING_ID_TOKEN",
          message: "Missing Google ID Token",
        );
      }

      // Get accessToken via authorizationClient for scopes
      const List<String> scopes = ['email', 'profile'];
      GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(scopes);

      // If not yet granted, request scopes (UI)
      if (authorization?.accessToken == null) {
        authorization = await googleUser.authorizationClient.authorizeScopes(
          scopes,
        );
        if (authorization.accessToken == null) {
          throw FirebaseAuthException(
            code: "ERROR_MISSING_ACCESS_TOKEN",
            message: "User did not grant required permissions",
          );
        }
      }

      final String accessToken = authorization!.accessToken;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            "Name": user.displayName,
            "Email": user.email,
            "Id": user.uid,
            "Image": user.photoURL ?? "<some default url>",
          });
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      print("GoogleSignInException: ${e.code} — ${e.description}");
      rethrow;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  Future<User> signInWithApple(
    BuildContext context, {
    List<Scope> scopes = const [],
  }) async {
    final result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: scopes),
    ]);
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final AppleIdCredential = result.credential!;
        final oAuthCredential = OAuthProvider('apple.com');
        final credential = oAuthCredential.credential(
          idToken: String.fromCharCodes(AppleIdCredential.identityToken!),
        );
        final UserCredential = await auth.signInWithCredential(credential);
        final firebaseUser = UserCredential.user!;
        if (scopes.contains(Scope.fullName)) {
          final fullName = AppleIdCredential.fullName;
          if (fullName != null &&
              fullName.givenName != null &&
              fullName.familyName != null) {
            final displayName = '${fullName.givenName}${fullName.familyName}';
            await firebaseUser.updateDisplayName(displayName);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          }
        }
        return firebaseUser;
      case AuthorizationStatus.error:
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: result.error.toString(),
        );

      case AuthorizationStatus.cancelled:
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      default:
        throw UnimplementedError();
    }
  }
}
