import 'package:pata/data/local/hive_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Erreur Google Sign-In: $e');
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return true;
    } catch (e) {
      print('Erreur anonyme: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    // On garde les données locales pour consultation hors ligne
    // await HiveService.clearAll();  // ← Commenté
  }
}