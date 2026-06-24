import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  const AuthUser({required this.id, required this.email, required this.name});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }
}

/// Result of exchanging a Supabase OAuth session for our own backend
/// token. [isNewUser] tells the caller whether to route through
/// onboarding (first-ever sign-in) or straight to home.
class SocialLoginResult {
  final String token;
  final bool isNewUser;
  const SocialLoginResult({required this.token, required this.isNewUser});
}

/// Talks to the backend's /auth/register, /auth/login and /auth/social
/// endpoints.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// Registers a new account. Throws [ApiException]/[ServerException] on failure.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return AuthUser.fromJson(response.data!);
  }

  /// Logs in with email/password. The backend expects OAuth2 form-encoded
  /// data with the email passed as `username`.
  ///
  /// Returns the bearer token on success.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': email,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    final token = response.data!['access_token'] as String;
    return token;
  }

  /// Exchanges a Supabase session access token (obtained client-side
  /// after a Google/Facebook OAuth login via supabase_flutter) for our
  /// own backend bearer token. The backend verifies the token against
  /// Supabase and finds-or-creates the matching local user.
  Future<SocialLoginResult> loginWithSupabaseToken(String supabaseAccessToken) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/social',
      data: {
        'access_token': supabaseAccessToken,
      },
    );
    final data = response.data!;
    return SocialLoginResult(
      token: data['access_token'] as String,
      isNewUser: data['is_new_user'] as bool? ?? false,
    );
  }
}
