import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

/// Handles Google Sign-In and returns an authenticated HTTP client for APIs.
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const List<String> _scopes = [
    'email',
    sheets.SheetsApi.spreadsheetsScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Signs the user in and returns the account.
  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Returns an authenticated HTTP client that can be used with googleapis.
  Future<http.Client> getAuthClient() async {
    final account = _currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw Exception('User is not signed in.');
    }
    final auth = await account.authentication;
    return _AuthenticatedClient(http.Client(), auth.accessToken!);
  }
}

/// A thin wrapper around [http.Client] that injects the Bearer token.
class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._inner, this._token);

  final http.Client _inner;
  final String _token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
