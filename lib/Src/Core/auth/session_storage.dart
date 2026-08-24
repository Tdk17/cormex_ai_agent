import 'dart:convert';

import 'package:agente_vendas_saas/Src/Core/storage/secure_storage_service.dart';

import 'auth_session.dart';

class SessionStorage {
  SessionStorage(this._storage);

  static const String _sessionKey = 'agent_sales.auth_session.v1';

  final SecureStorageService _storage;
  AuthSession? _cachedSession;

  AuthSession? get cachedSession => _cachedSession;
  String? get sessionToken => _cachedSession?.sessionToken;

  Future<AuthSession?> read() async {
    if (_cachedSession != null) return _cachedSession;
    final raw = await _storage.read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      _cachedSession = AuthSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return _cachedSession;
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    _cachedSession = session;
    await _storage.write(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cachedSession = null;
    await _storage.delete(_sessionKey);
  }
}
