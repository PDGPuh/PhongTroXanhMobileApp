import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<String?> requestGoogleIdToken(String clientId) async {
  try {
    final googleSignIn = GoogleSignIn(
      serverClientId: clientId,
      clientId: kIsWeb ? clientId : null,
      scopes: const ['email', 'profile', 'openid'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  } catch (e) {
    debugPrint('Google Sign-In Error: $e');
    return null;
  }
}
