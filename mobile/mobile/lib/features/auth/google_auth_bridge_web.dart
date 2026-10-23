// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

Future<String?> requestGoogleIdToken(String clientId) async {
  final completer = Completer<String?>();

  js.context['onGoogleAuthCallback'] = (dynamic token, dynamic error) {
    if (!completer.isCompleted) {
      if (token != null && token is String && token.isNotEmpty) {
        completer.complete(token);
      } else {
        completer.complete(null);
      }
    }
  };

  try {
    js.context.callMethod('launchGoogleSignIn', [clientId]);
  } catch (_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  return completer.future.timeout(
    const Duration(seconds: 60),
    onTimeout: () => null,
  );
}
