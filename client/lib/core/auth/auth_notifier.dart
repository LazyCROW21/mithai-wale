import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/api_client.dart';
import 'auth_models.dart';

enum AuthStatus { unknown, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState._(this.status, [this.session]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.signedOut() : this._(AuthStatus.signedOut);
  const AuthState.signedIn(AuthSession s) : this._(AuthStatus.signedIn, s);

  final AuthStatus status;
  final AuthSession? session;
}

/// Owns the signed-in session and the shared [ApiClient].
///
/// Tokens are persisted in a Hive box so the session survives restarts.
/// (Swap for secure storage before shipping to production devices.)
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.unknown()) {
    api = ApiClient(
      getTokens: () => _tokens,
      onTokens: _saveTokens,
      onSessionExpired: () => unawaited(signOut(callServer: false)),
    );
  }

  static const _boxName = 'auth';
  static const _tokensKey = 'tokens';
  static const _sessionKey = 'session';

  /// Current state, readable outside the notifier (e.g. router redirects).
  AuthState get current => state;

  late final ApiClient api;
  Tokens? _tokens;
  Box<String>? _box;

  /// Restores a saved session on startup.
  Future<void> restore() async {
    _box = await Hive.openBox<String>(_boxName);
    final raw = _box!.get(_tokensKey);
    if (raw == null) {
      state = const AuthState.signedOut();
      return;
    }
    _tokens = Tokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    try {
      final j = await api.get('/auth/me') as Map<String, dynamic>;
      await _box!.put(_sessionKey, jsonEncode(j));
      state = AuthState.signedIn(AuthSession.fromJson(j));
    } on ApiException catch (e) {
      debugPrint('Session restore failed: $e');
      final cached = _box!.get(_sessionKey);
      if (e.isNetwork && cached != null) {
        // Offline start: trust the last known session until the network is back.
        state = AuthState.signedIn(
          AuthSession.fromJson(jsonDecode(cached) as Map<String, dynamic>),
        );
      } else {
        await _saveTokens(null);
        state = const AuthState.signedOut();
      }
    }
  }

  /// Throws [ApiException] on failure.
  Future<void> signIn({
    required String franchiseCode,
    required String username,
    required String password,
  }) async {
    final j = await api.post(
      '/auth/login',
      auth: false,
      body: {
        'tenant': franchiseCode.trim(),
        'username': username.trim(),
        'password': password,
      },
    ) as Map<String, dynamic>;
    await _saveTokens(Tokens.fromJson(j));
    await _box!.put(_sessionKey, jsonEncode(j));
    state = AuthState.signedIn(AuthSession.fromJson(j));
  }

  Future<void> signOut({bool callServer = true}) async {
    final refresh = _tokens?.refreshToken;
    if (callServer && refresh != null) {
      try {
        await api.post('/auth/logout', body: {'refreshToken': refresh}, auth: false);
      } catch (_) {/* best effort */}
    }
    await _saveTokens(null);
    state = const AuthState.signedOut();
  }

  Future<void> _saveTokens(Tokens? t) async {
    _tokens = t;
    final box = _box ?? await Hive.openBox<String>(_boxName);
    _box = box;
    if (t == null) {
      await box.delete(_tokensKey);
      await box.delete(_sessionKey);
    } else {
      await box.put(
        _tokensKey,
        jsonEncode({'accessToken': t.accessToken, 'refreshToken': t.refreshToken}),
      );
    }
  }
}

/// App-wide instance. The router's redirect needs it outside the widget tree.
final AuthNotifier appAuth = AuthNotifier();

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => appAuth,
);

/// The signed-in session. Throws if read while signed out; only use below the
/// router's auth guard.
final sessionProvider = Provider<AuthSession>((ref) {
  final s = ref.watch(authProvider).session;
  if (s == null) throw StateError('No active session');
  return s;
});

/// Shared API client (token-aware).
final apiClientProvider = Provider<ApiClient>(
  (ref) => ref.watch(authProvider.notifier).api,
);
