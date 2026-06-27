// lib/features/backup/data/datasources/google_auth_datasource.dart
import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:routine/core/config/secrets.dart';

import '../../../../core/error/exceptions.dart';

const String kDriveAppDataScope =
    'https://www.googleapis.com/auth/drive.appdata';

/// Adds `Authorization: Bearer <token>` to every outgoing request.
/// Replaces the removed `authClient` extension.
class _BearerAuthClient extends http.BaseClient {
  _BearerAuthClient(this._inner, this._accessToken);

  final http.Client _inner;
  final String _accessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class GoogleAuthDataSource {
  static const List<String> _scopes = <String>[kDriveAppDataScope];

  bool _initialized = false;

  /// 7.x has no `currentUser` getter — we track the latest account from the
  /// `authenticationEvents` stream ourselves.
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: Secrets.googleApi);

    _authSub = GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
      }
    });

    _initialized = true;
  }

  /// Returns the current account, attempting a silent recovery if needed.
  Future<GoogleSignInAccount?> _resolveAccount() async {
    if (_currentUser != null) return _currentUser;
    final account = await GoogleSignIn.instance
        .attemptLightweightAuthentication();
    if (account != null) _currentUser = account;
    return _currentUser;
  }

  /// Interactive sign-in + scope authorization.
  Future<void> signIn() async {
    await _ensureInitialized();
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();
      _currentUser = account;

      // Only call authorizeScopes if the Drive scope isn't already granted.
      // authorizeScopes() launches a second consent UI — skipping it when
      // unnecessary avoids a hang if the pending Future never resolves
      // (e.g. the consent screen is suppressed or the scope is missing from
      // your OAuth client in Google Cloud Console).
      final existing = await account.authorizationClient
          .authorizationForScopes(_scopes);
      if (existing == null) {
        await account.authorizationClient.authorizeScopes(_scopes);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException('Cancelled');
      }
      throw AuthException(e.description ?? 'Google sign-in failed.');
    } on Exception catch (e) {
      // Catches PlatformException thrown by authorizeScopes on Android
      // (e.g. access_denied, network_error, sign_in_required) that the
      // previous bare `catch (e)` was silently re-throwing as AuthException
      // but only after a potential indefinite hang.
      throw AuthException('Drive authorization failed: $e');
    }
  }

  /// Non-interactive (silent) sign-in. Returns true if a user is available.
  Future<bool> signInSilently() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      _currentUser = account;
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<bool> get isSignedIn async {
    await _ensureInitialized();
    return (await _resolveAccount()) != null;
  }

  /// Builds an authenticated [http.Client] for `googleapis` DriveApi.
  /// Throws [AuthExpiredException] if no valid token can be obtained.
  Future<http.Client> authClient() async {
    await _ensureInitialized();

    final GoogleSignInAccount? account = await _resolveAccount();

    if (account == null) {
      throw const AuthExpiredException('Not signed in.');
    }

    try {
      // Use already-granted scopes if possible; otherwise prompt.
      final GoogleSignInClientAuthorization authorization =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
          await account.authorizationClient.authorizeScopes(_scopes);

      return _BearerAuthClient(http.Client(), authorization.accessToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException('Cancelled');
      }
      throw const AuthExpiredException('Authorization expired.');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Call when disposing (optional — the datasource usually lives app-wide).
  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }
}