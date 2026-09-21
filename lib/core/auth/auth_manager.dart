import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile.dart';
import '../config/app_config.dart';
import '../services/service_locator.dart';

class AuthManager extends ChangeNotifier {
  static final AuthManager instance = AuthManager._internal();

  AuthManager._internal();

  ProfileModel? _currentProfile;
  String? _fallbackToken;
  String? _fallbackUserId;
  String? _fallbackEmail;
  bool _isInitialized = false;

  ProfileModel? get currentProfile => _currentProfile;
  String? get currentUserId =>
      _fallbackUserId ?? Supabase.instance.client.auth.currentUser?.id;
  String? get currentUserEmail =>
      _fallbackEmail ?? Supabase.instance.client.auth.currentUser?.email;
  bool get isAuthenticated => currentToken != null;

  String? get currentToken {
    if (AppConfig.isSupabaseConfigured) {
      try {
        return Supabase.instance.client.auth.currentSession?.accessToken ??
            _fallbackToken;
      } catch (_) {
        return _fallbackToken;
      }
    }
    return _fallbackToken;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (AppConfig.isSupabaseConfigured) {
      try {
        // ignore: deprecated_member_use
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: AppConfig.supabaseAnonKey,
        );

        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          _fallbackToken = session.accessToken;
          _fallbackUserId = session.user.id;
          _fallbackEmail = session.user.email;
          unawaited(_syncProfile(session.user));
        }

        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final s = data.session;
          if (s != null) {
            _fallbackToken = s.accessToken;
            _fallbackUserId = s.user.id;
            _fallbackEmail = s.user.email;
            _syncProfile(s.user);
          } else if (data.event == AuthChangeEvent.signedOut) {
            _fallbackToken = null;
            _fallbackUserId = null;
            _fallbackEmail = null;
            _currentProfile = null;
          }
          notifyListeners();
        });
      } catch (e) {
        debugPrint('Supabase initialization failed: $e. Falling back to local mode.');
      }
    } else {
      _fallbackToken = 'demo-jwt-token';
      _fallbackUserId = '00000000-0000-0000-0000-000000000001';
      _fallbackEmail = 'user@transition.org';
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signInWithGoogle({String? preferredRole}) async {
    if (AppConfig.isSupabaseConfigured) {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.transition://login-callback',
        queryParams: preferredRole != null ? {'role': preferredRole} : null,
      );
    } else {
      _fallbackToken = 'demo-google-token';
      _fallbackUserId = '00000000-0000-0000-0000-000000000004';
      _fallbackEmail = 'google.user@transition.org';
      _currentProfile = ProfileModel(
        id: _fallbackUserId!,
        name: 'Google Verified User',
        role: preferredRole ?? 'citizen',
        location: 'Metro Civic Zone',
      );
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    String? preferredRole,
  }) async {
    if (AppConfig.isSupabaseConfigured) {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        _fallbackToken = response.session?.accessToken;
        _fallbackUserId = response.user?.id;
        _fallbackEmail = response.user?.email;
        if (response.user != null) {
          await _syncProfile(response.user!, preferredRole: preferredRole);
        }
      }
    } else {
      _fallbackToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      _fallbackUserId = '00000000-0000-0000-0000-000000000001';
      _fallbackEmail = email;
      _currentProfile = ProfileModel(
        id: _fallbackUserId!,
        name: email.split('@').first,
        role: preferredRole ?? 'citizen',
      );
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
    String? role,
  }) async {
    final chosenRole = role ?? 'citizen';
    final chosenName = name?.trim().isNotEmpty == true ? name!.trim() : email.split('@').first;
    if (AppConfig.isSupabaseConfigured) {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': chosenName,
          'role': chosenRole,
        },
      );
      if (response.session != null) {
        _fallbackToken = response.session?.accessToken;
        _fallbackUserId = response.user?.id;
        _fallbackEmail = response.user?.email;
        if (response.user != null) {
          await _syncProfile(
            response.user!,
            preferredName: chosenName,
            preferredRole: chosenRole,
          );
        }
      } else if (response.user != null) {
        _fallbackUserId = response.user?.id;
        _fallbackEmail = response.user?.email;
        _currentProfile = ProfileModel(
          id: response.user!.id,
          name: chosenName,
          role: chosenRole,
        );
      }
    } else {
      _fallbackToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      _fallbackUserId = '00000000-0000-0000-0000-000000000001';
      _fallbackEmail = email;
      _currentProfile = ProfileModel(
        id: _fallbackUserId!,
        name: chosenName,
        role: chosenRole,
      );
    }
    notifyListeners();
  }

  Future<void> _syncProfile(
    User user, {
    String? preferredName,
    String? preferredRole,
  }) async {
    final profileService = ServiceLocator.instance.profileService;

    // 1. Try to fetch existing profile from backend
    try {
      final profile = await profileService.getMyProfile();
      _currentProfile = profile;
      notifyListeners();
      return;
    } catch (_) {
      // Backend profile not found or backend unreachable
    }

    final metadataName = user.userMetadata?['name'] ??
        user.userMetadata?['full_name'] ??
        preferredName ??
        user.email?.split('@').first ??
        'User';
    final metadataRole = (user.userMetadata?['role'] ?? preferredRole ?? 'citizen')
        .toString()
        .toLowerCase();

    // 2. Try to create profile in backend
    try {
      final newProfile = await profileService.createProfile(
        ProfileCreate(
          name: metadataName.toString(),
          role: metadataRole,
        ),
      );
      _currentProfile = newProfile;
      notifyListeners();
      return;
    } catch (_) {
      // Backend create failed
    }

    // 3. Fallback client profile
    _currentProfile = ProfileModel(
      id: user.id,
      name: metadataName.toString(),
      role: metadataRole,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    _fallbackToken = null;
    _fallbackUserId = null;
    _fallbackEmail = null;
    _currentProfile = null;
    notifyListeners();
  }

  void setProfile(ProfileModel? profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  void setDemoSession({
    required String token,
    required String userId,
    required String email,
    ProfileModel? profile,
  }) {
    _fallbackToken = token;
    _fallbackUserId = userId;
    _fallbackEmail = email;
    _currentProfile = profile;
    notifyListeners();
  }
}
