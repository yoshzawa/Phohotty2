import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:msal_mobile/msal_mobile.dart';

class FbUser {
	final String uid;
	final String? displayName;
	final String? email;
	final String? photoUrl;
	final List<String> providers;

	FbUser({
		required this.uid,
		this.displayName,
		this.email,
		this.photoUrl,
		this.providers = const [],
	});

	factory FbUser.fromFirebaseUser(User user) {
		return FbUser(
			uid: user.uid,
			displayName: user.displayName,
			email: user.email,
			photoUrl: user.photoURL,
			providers: user.providerData.map((p) => p.providerId).toList(),
		);
	}
}

class FbAuth {
	FbAuth._();
	static final FbAuth instance = FbAuth._();

	final FirebaseAuth _auth = FirebaseAuth.instance;
	final GoogleSignIn _googleSignIn = GoogleSignIn();

  // TODO: Azure ADで払い出されたクライアントIDに書き換えてください
  static const String _clientId = '0416410b-6a99-4dfd-8f54-3f9361ed8e61';
  static const String _authority = 'https://login.microsoftonline.com/common';
  late PublicClientApplication _publicClientApplication;

	void initializeMsal() async {
    _publicClientApplication = await PublicClientApplication.createPublicClientApplication(
      androidConfig: AndroidConfig(
        clientId: _clientId,
        redirectUri: 'msal$_clientId://auth',
        authority: _authority,
      ),
      iosConfig: IosConfig(
        clientId: _clientId,
        redirectUri: 'msal$_clientId://auth',
        authority: _authority,
      ),
    );
  }


	Stream<FbUser?> get authStateChanges =>
			_auth.authStateChanges().map((u) => u == null ? null : FbUser.fromFirebaseUser(u));

	FbUser? get currentUser =>
			_auth.currentUser == null ? null : FbUser.fromFirebaseUser(_auth.currentUser!);

	Future<FbUser?> signInWithGoogle() async {
		try {
			final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
			if (googleUser == null) return null; // ユーザーがサインインをキャンセル

			final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

			final credential = GoogleAuthProvider.credential(
				accessToken: googleAuth.accessToken,
				idToken: googleAuth.idToken,
			);

			final UserCredential userCredential = await _auth.signInWithCredential(credential);
			final user = userCredential.user;
			if (user == null) return null;
			return FbUser.fromFirebaseUser(user);
		} catch (e) {
			rethrow;
		}
	}

	Future<FbUser?> signInWithMicrosoft() async {
    try {
      final result = await _publicClientApplication.acquireToken(scopes: ['user.read']);
      final String accessToken = result.accessToken;

      final OAuthCredential credential = OAuthProvider('microsoft.com').credential(
        accessToken: accessToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return null;
      return FbUser.fromFirebaseUser(user);
    } catch (e) {
      // Handle exceptions
      print(e);
      rethrow;
    }
  }

	Future<void> signOut() async {
		await _auth.signOut();
		try {
			await _googleSignIn.signOut();
      await _publicClientApplication.logout();
		} catch (_) {}
	}
}
