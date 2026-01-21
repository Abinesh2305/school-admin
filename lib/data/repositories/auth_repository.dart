import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../services/auth_service.dart';
import '../models/user_model.dart';

/// Authentication repository interface
abstract class IAuthRepository {
  Future<Result<UserModel>> login(String email, String password);
}

/// Authentication repository implementation
class AuthRepository implements IAuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  @override
  Future<Result<UserModel>> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true && result['user'] != null) {
        final userData = result['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        return Success(user);
      } else {
        return Failure(
          result['message'] as String? ?? 'Login failed',
        );
      }
    } catch (e) {
      return Failure(
        'An error occurred during login: ${e.toString()}',
      );
    }
  }
}

