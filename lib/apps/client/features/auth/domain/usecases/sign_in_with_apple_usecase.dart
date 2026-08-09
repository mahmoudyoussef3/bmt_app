import '../entities/social_auth_result.dart';
import '../repositories/social_auth_repository.dart';

class SignInWithAppleUseCase {
  const SignInWithAppleUseCase(this.repository);

  final SocialAuthRepository repository;

  Future<SocialAuthResult> call() => repository.signInWithApple();
}
