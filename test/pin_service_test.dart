import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/core/service/pin_service.dart';

void main() {
  group('PinService Authentication Session Tests', () {
    setUp(() {
      // Ensure we start from locked state
      PinService.logout();
    });

    test('should start as unauthenticated', () {
      expect(PinService.isAuthenticated(), isFalse);
    });

    test('should authenticate successfully', () {
      expect(PinService.isAuthenticated(), isFalse);
      
      PinService.authenticate();
      
      expect(PinService.isAuthenticated(), isTrue);
    });

    test('should logout / lock successfully', () {
      PinService.authenticate();
      expect(PinService.isAuthenticated(), isTrue);
      
      PinService.logout();
      
      expect(PinService.isAuthenticated(), isFalse);
    });
  });
}
