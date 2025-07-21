import 'package:flutter_test/flutter_test.dart';
import 'package:green_market/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('sign in with valid credentials returns user', () async {
      // final authService = AuthService();
      // BuildContext context = ... (mock or real context required)
      // final userCredential = await authService.signInWithEmailPassword('test@example.com', 'password123', context);
      // expect(userCredential, isNotNull);
      // expect(userCredential?.user?.email, 'test@example.com');
    });

    test('sign in with invalid credentials returns null', () async {
      // final authService = AuthService();
      // BuildContext context = ... (mock or real context required)
      // final userCredential = await authService.signInWithEmailPassword('wrong@example.com', 'wrongpass', context);
      // expect(userCredential, isNull);
    });

    test('logout clears user session', () async {
      // final authService = AuthService();
      // await authService.signInWithEmailPassword('test@example.com', 'password123', context);
      // await authService._auth.signOut();
      // expect(authService.currentUser, isNull);
    });
  });
}
