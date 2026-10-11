import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haitiandollar/models/wallet_state.dart';
import 'package:haitiandollar/services/pin_auth_service.dart';
import 'package:haitiandollar/widgets/pin_keypad_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PinAuthService Unit Tests', () {
    test('setPin then verifyPin with valid PIN returns success', () async {
      // Use low iterations in unit tests for fast execution
      final auth = PinAuthService(pbkdf2Iterations: 100);
      expect(auth.isPinSet, isFalse);

      final setResult = await auth.setPin('5829');
      expect(setResult, AuthResult.success);
      expect(auth.isPinSet, isTrue);

      final verifyResult = await auth.verifyPin('5829');
      expect(verifyResult, AuthResult.success);
    });

    test('rejects weak PINs (0000, 1234, 1111, 4321)', () async {
      final auth = PinAuthService(pbkdf2Iterations: 100);

      expect(PinAuthService.isWeakPin('0000'), isTrue);
      expect(PinAuthService.isWeakPin('1234'), isTrue);
      expect(PinAuthService.isWeakPin('1111'), isTrue);
      expect(PinAuthService.isWeakPin('4321'), isTrue);
      expect(PinAuthService.isWeakPin('5829'), isFalse);

      final res1 = await auth.setPin('1234');
      expect(res1, AuthResult.weakPin);
      expect(auth.isPinSet, isFalse);

      final res2 = await auth.setPin('0000');
      expect(res2, AuthResult.weakPin);
      expect(auth.isPinSet, isFalse);
    });

    test('incorrect PIN increments fail count and triggers lockout on 3rd failure', () async {
      final auth = PinAuthService(pbkdf2Iterations: 100);
      await auth.setPin('5829');

      // Failure 1
      final res1 = await auth.verifyPin('9999');
      expect(res1, AuthResult.incorrectPin);
      expect(auth.failCount, 1);
      expect(auth.isLockedOut, isFalse);

      // Failure 2
      final res2 = await auth.verifyPin('9999');
      expect(res2, AuthResult.incorrectPin);
      expect(auth.failCount, 2);
      expect(auth.isLockedOut, isFalse);

      // Failure 3: Triggers lockout
      final res3 = await auth.verifyPin('9999');
      expect(res3, AuthResult.lockedOut);
      expect(auth.failCount, 3);
      expect(auth.isLockedOut, isTrue);
      expect(auth.lockoutSecondsRemaining, greaterThan(0));

      // Subsequent attempt while locked out is rejected immediately
      final res4 = await auth.verifyPin('5829');
      expect(res4, AuthResult.lockedOut);
    });

    test('biometric authentication remains available and succeeds during PIN lockout', () async {
      final auth = PinAuthService(pbkdf2Iterations: 100);
      await auth.setPin('5829');

      // Lock out PIN
      await auth.verifyPin('9999');
      await auth.verifyPin('9999');
      await auth.verifyPin('9999');
      expect(auth.isLockedOut, isTrue);

      // Biometrics can still authenticate
      bool bioResult = false;
      auth.biometricAuthHandler = () async => true;
      bioResult = await auth.authenticateWithBiometrics();

      expect(bioResult, isTrue);
      // Successful biometric authentication resets lockout
      expect(auth.isLockedOut, isFalse);
      expect(auth.failCount, 0);
    });

    test('duress PIN returns successDuress and can activate decoy wallet balance', () async {
      final auth = PinAuthService(pbkdf2Iterations: 100);
      await auth.setPin('5829', duressPin: '9147');
      expect(auth.hasDuressPin, isTrue);

      final wallet = WalletState(openingBalance: 500.0, pinAuthService: auth);
      expect(wallet.balance, 500.0);
      expect(wallet.isDuressActive, isFalse);

      // Verify with Duress PIN
      final res = await auth.verifyPin('9147');
      expect(res, AuthResult.successDuress);

      // Activate Duress Mode
      wallet.activateDuressMode();
      expect(wallet.isDuressActive, isTrue);
      expect(wallet.balance, 25.0); // Decoy balance displayed
      expect(wallet.balanceInHtg, 125.0);

      // Clear Duress Mode restores actual balance
      wallet.clearDuressMode();
      expect(wallet.isDuressActive, isFalse);
      expect(wallet.balance, 500.0);
    });

    test('changePin validates old PIN before applying new PIN', () async {
      final auth = PinAuthService(pbkdf2Iterations: 100);
      await auth.setPin('5829');

      // Wrong old PIN fails
      final failRes = await auth.changePin(oldPin: '0000', newPin: '7391');
      expect(failRes, AuthResult.incorrectPin);

      // Weak new PIN fails
      final weakRes = await auth.changePin(oldPin: '5829', newPin: '1234');
      expect(weakRes, AuthResult.weakPin);

      // Correct old PIN + valid new PIN succeeds
      final okRes = await auth.changePin(oldPin: '5829', newPin: '7391');
      expect(okRes, AuthResult.success);

      expect(await auth.verifyPin('5829'), AuthResult.incorrectPin);
      expect(await auth.verifyPin('7391'), AuthResult.success);
    });
  });

  group('PinKeypadSheet Widget Tests', () {
    testWidgets('renders keypad and dots without overflow down to 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final auth = PinAuthService(pbkdf2Iterations: 100);
      await auth.setPin('5829');

      bool? authenticated;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinKeypadSheet(
              authService: auth,
              locale: 'ht',
              onAuthenticated: (duress) => authenticated = !duress,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antre Kòd Sekrè Ou'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap digits 5, 8, 2, 9
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      expect(authenticated, isTrue);
    });

    testWidgets('tapping biometric clears entered PIN and authenticates', (tester) async {
      final auth = PinAuthService(pbkdf2Iterations: 100);
      auth.biometricsAvailable = true;
      await auth.setPin('5829');
      auth.biometricAuthHandler = () async => true;

      bool? authenticated;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinKeypadSheet(
              authService: auth,
              locale: 'ht',
              onAuthenticated: (duress) => authenticated = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter partial PIN '5', '8'
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();

      // Tap biometric button
      await tester.tap(find.byTooltip('Biometric'));
      await tester.pumpAndSettle();

      expect(authenticated, isTrue);
    });
  });
}
