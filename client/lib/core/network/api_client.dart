import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URL of the backend.
///
/// Override per build: `flutter run --dart-define=API_URL=https://api.example.com/api/v1`.
/// Defaults to the host machine (the Android emulator reaches it at 10.0.2.2).
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return 'http://${isAndroid ? '10.0.2.2' : 'localhost'}:3000/api/v1';
}

/// Error from the backend (non-2xx) or the network.
class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.isNetwork = false});

  final String message;
  final int? status;
  final bool isNetwork;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Access/refresh token pair.
@immutable
class Tokens {
  const Tokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory Tokens.fromJson(Map<String, dynamic> j) => Tokens(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
      );
}

/// Thin JSON HTTP client with bearer auth and transparent token refresh.
///
/// The owner of the session ([AuthNotifier]) supplies token storage through
/// [getTokens] / [onTokens] and is told when the session is no longer
/// recoverable through [onSessionExpired].
class ApiClient {
  ApiClient({
    required this.getTokens,
    required this.onTokens,
    required this.onSessionExpired,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final Tokens? Function() getTokens;
  final Future<void> Function(Tokens? tokens) onTokens;
  final void Function() onSessionExpired;
  final http.Client _http;

  Future<void>? _refreshing;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    var res = await _raw(method, path, body: body, query: query, auth: auth);
    if (res.statusCode == 401 && auth && getTokens() != null) {
      if (await _refresh()) {
        res = await _raw(method, path, body: body, query: query, auth: auth);
      }
      if (res.statusCode == 401) onSessionExpired();
    }
    return _decode(res);
  }

  Future<http.Response> _raw(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    required bool auth,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final req = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json';
    final token = getTokens()?.accessToken;
    if (auth && token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);
    try {
      return await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 15)),
      );
    } on TimeoutException {
      throw const ApiException('Request timed out', isNetwork: true);
    } catch (e) {
      throw ApiException('$e', isNetwork: true);
    }
  }

  /// Refresh tokens are single-use, so concurrent 401s share one refresh call.
  Future<bool> _refresh() async {
    final current = getTokens();
    if (current == null) return false;
    final inFlight = _refreshing;
    if (inFlight != null) {
      await inFlight;
      return getTokens() != null;
    }
    final completer = Completer<void>();
    _refreshing = completer.future;
    try {
      final res = await _raw(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': current.refreshToken},
        auth: false,
      );
      if (res.statusCode != 200) {
        await onTokens(null);
        return false;
      }
      await onTokens(Tokens.fromJson(jsonDecode(res.body) as Map<String, dynamic>));
      return true;
    } on ApiException {
      return false; // network failure: keep tokens, let the caller surface the error
    } finally {
      completer.complete();
      _refreshing = null;
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    String message = res.reasonPhrase ?? 'Request failed';
    try {
      final j = jsonDecode(res.body);
      final err = j is Map ? j['error'] : null;
      final m = err is Map ? err['message'] : null;
      if (m is String) message = m;
    } catch (_) {}
    throw ApiException(message, status: res.statusCode);
  }
}
