import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

/// Service managing Firebase Authentication (including Google Sign-In)
/// and Cloud Firestore database operations.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Gets the currently authenticated user (if any).
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Triggers the Google Sign-In flow, authenticates with Firebase,
  /// and saves/updates the user's profile details in the Cloud Firestore database.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log("[Firebase Auth] Starting Google Sign-In flow...");
      
      // 1. Trigger the interactive Google Sign-In selection layout
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        developer.log("[Firebase Auth] Google Sign-In was canceled by the user.");
        return null;
      }

      // 2. Obtain OAuth authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase Auth using the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        developer.log("[Firebase Auth] Successfully authenticated with Firebase. User: ${user.displayName}");
        
        // 5. Save/Update user profile in Cloud Firestore database
        await syncUserProfile(user);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log("[Firebase Auth] FirebaseAuthException: [${e.code}] - ${e.message}");
      rethrow;
    } catch (e) {
      developer.log("[Firebase Auth] Unexpected error during Google Sign-In: $e");
      return null;
    }
  }

  /// Syncs/Saves the authenticated user's profile to the Firestore 'users' collection.
  Future<void> syncUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      await userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'No Name',
        'email': user.email ?? 'No Email',
        'photoURL': user.photoURL ?? '',
        'lastSignIn': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(), // Will be ignored if doc already exists
      }, SetOptions(merge: true));

      developer.log("[Firestore] User profile synced successfully for ${user.email}");
    } catch (e) {
      developer.log("[Firestore] Error syncing user profile to database: $e");
    }
  }

  /// Signs the user out from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      developer.log("[Firebase Auth] Successfully signed out.");
    } catch (e) {
      developer.log("[Firebase Auth] Error during sign out: $e");
    }
  }
}
