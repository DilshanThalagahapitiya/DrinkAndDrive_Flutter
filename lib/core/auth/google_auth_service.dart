// ============================================================
// Google Auth Service
// ============================================================
// Handles Google Sign-In for all roles (Customer, Driver,
// Rider, Hotel). Uses the google_sign_in Flutter package.
//
// IMPORTANT: You must configure Google OAuth client IDs:
//   - Android: Add google-services.json to android/app/
//   - iOS: Add GoogleService-Info.plist to ios/Runner/
//   These come from the Firebase/Google Cloud Console.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._();
  GoogleAuthService._();

  // serverClientId = Web Client ID from Google Cloud Console.
  // The iOS CLIENT_ID is read automatically from GoogleService-Info.plist.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // This is the Web Client ID that the backend will verify the token against.
    // It must match GOOGLE_CLIENT_ID in DAD_Backend/.env.local
    serverClientId: '943078584636-uhs1ncblcuc441ktjae7lqj2v9iuua1r.apps.googleusercontent.com',
  );

  /// Signs in with Google and returns the Google account.
  /// Throws an exception with detailed error info if sign-in fails.
  Future<GoogleSignInAccount?> signIn() async {
    debugPrint('🟢 [GoogleAuth] Starting Google Sign-In...');
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('⚠️ [GoogleAuth] Sign-in was cancelled by user');
        return null;
      }
      debugPrint('✅ [GoogleAuth] Signed in as: ${account.email}');
      debugPrint('✅ [GoogleAuth] Display name: ${account.displayName}');
      return account;
    } catch (e, stackTrace) {
      // Any sign-in error (cancelled, network, config, etc.)
      debugPrint('❌ [GoogleAuth] Sign-in error: $e');
      debugPrint('❌ [GoogleAuth] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets the Google ID token for sending to the backend.
  /// Requires the user to be signed in first.
  Future<String?> getIdToken() async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      debugPrint('⚠️ [GoogleAuth] No current user - cannot get ID token');
      return null;
    }
    try {
      final auth = await account.authentication;
      debugPrint('🟢 [GoogleAuth] Got ID token (length: ${auth.idToken?.length ?? 0})');
      if (auth.idToken == null) {
        debugPrint('❌ [GoogleAuth] ID token is NULL');
        debugPrint('❌ [GoogleAuth] Access token present: ${auth.accessToken != null}');
      }
      return auth.idToken;
    } catch (e, stackTrace) {
      debugPrint('❌ [GoogleAuth] Failed to get ID token: $e');
      debugPrint('❌ [GoogleAuth] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Signs out from Google.
  Future<void> signOut() async {
    debugPrint('🟢 [GoogleAuth] Signing out from Google...');
    await _googleSignIn.signOut();
    debugPrint('✅ [GoogleAuth] Signed out');
  }

  /// Checks if a user is currently signed in with Google.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Gets the current Google account.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}