import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mycove/app.dart';

/// Real network + real timers only work reliably under `integration_test`
/// (real device/desktop target, real event loop) — the plain `flutter_test`
/// harness runs every test inside a `fake_async` zone that never sees real
/// socket I/O complete, so it hangs forever on any genuine HTTP call. This
/// suite hits the live MyCove API on localhost, so it has to run here.
///
/// Run with the backend up (docker compose + `npm run start:dev` in
/// communityhub-api) via: `flutter test integration_test/app_flow_test.dart -d <device>`

/// flutter_secure_storage would otherwise read/write the real device
/// Keychain, leaking a login token across test runs and breaking test
/// isolation (a stale token would auto-login before the login screen
/// renders). Fake the channel with a plain in-memory map instead — cleared
/// before every test via setUp() below, since a token saved by one test
/// must not silently auto-login the next one.
final _secureStorageMock = <String, String>{};

void _mockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>();
    switch (call.method) {
      case 'read':
        return _secureStorageMock[args!['key'] as String];
      case 'write':
        _secureStorageMock[args!['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        _secureStorageMock.remove(args!['key'] as String);
        return null;
      case 'deleteAll':
        _secureStorageMock.clear();
        return null;
      case 'containsKey':
        return _secureStorageMock.containsKey(args!['key'] as String);
      case 'readAll':
        return _secureStorageMock;
      case 'isProtectedDataAvailable':
        return true;
      default:
        return null;
    }
  });
}

/// Pumps in small real-time steps until [finder] matches something, or
/// [timeout] elapses. Plain `pumpAndSettle()` isn't an option on screens with
/// a perpetually-animating `CircularProgressIndicator` (the bootstrap gate,
/// the payment "processing" screen) — it never sees a settled frame and
/// hangs until its own timeout.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyCoveApp()));
  // Auto-login resolves against the real backend before the login screen
  // appears — wait it out rather than pumpAndSettle() past the bootstrap
  // spinner.
  await pumpUntilFound(tester, find.text('MyCove'));
}

/// Tap [tapFinder], then wait in real time for [waitFinder] to appear.
/// Every tap in these tests either triggers a real HTTP round trip or
/// crosses a bootstrap/processing screen with a perpetual spinner, so a
/// plain `pumpAndSettle()` is unreliable here — timing is genuine wall-clock
/// network latency, not fake-clock frames.
Future<void> tapAndWait(WidgetTester tester, Finder tapFinder, Finder waitFinder) async {
  await tester.tap(tapFinder);
  await pumpUntilFound(tester, waitFinder);
  // The target text can appear a frame or two before layout (e.g. the
  // bottom nav bar) has fully settled — without this, an immediate
  // follow-up tap can hit a stale, not-yet-final position.
  await tester.pumpAndSettle();
}

Future<void> pumpUntilAnyFound(WidgetTester tester, List<Finder> finders, {Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Running as a real app (unlike plain flutter_test), so google_fonts
    // fetches Caprasimo/Figtree from the network exactly like a real device
    // would — no need to fall back to system fonts here.
    _mockSecureStorage();
  });

  setUp(() {
    _secureStorageMock.clear();
  });

  testWidgets('resident: login -> dashboard -> dues -> payment -> receipt', (tester) async {
    await pumpApp(tester);

    expect(find.text('MyCove'), findsOneWidget);
    expect(find.text('Resident'), findsOneWidget);
    expect(find.text('Security Guard'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '0803 555 0142');
    await tester.enterText(find.byType(TextField).at(1), 'estate123');
    await tapAndWait(tester, find.text('Log In'), find.text('Ifeoma'));

    // Dashboard.
    expect(find.text('Ifeoma'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // Dashboard -> Dues tab (bottom nav).
    await tester.tap(find.text('Dues'));
    await tester.pumpAndSettle();
    expect(find.text('Dues & Payments'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);

    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Payment'), findsOneWidget);

    await tester.tap(find.text('Confirm Payment'));
    await tester.pump(); // enter 'processing' (synchronous state change before the first await)
    expect(find.text('Processing with Paystack…'), findsOneWidget);

    // The mock Paystack gateway settles ~1.4s after initiate; the client
    // polls verify every 500ms. Poll the widget tree in real time instead
    // of guessing an exact wait.
    await pumpUntilFound(tester, find.text('Payment successful'));
    expect(find.text('Payment successful'), findsOneWidget);

    await tapAndWait(tester, find.text('View Receipt'), find.text('Payment Receipt'));
    expect(find.text('Payment Receipt'), findsOneWidget);
    expect(find.text('₦45,000'), findsOneWidget);
  });

  testWidgets('resident: create a visitor pass', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).at(0), '0803 555 0142');
    await tester.enterText(find.byType(TextField).at(1), 'estate123');
    await tapAndWait(tester, find.text('Log In'), find.text('Home'));

    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    expect(find.text('Visitor Passes'), findsOneWidget);

    await tester.tap(find.text('+ New Visitor Pass'));
    await tester.pumpAndSettle();
    expect(find.text('New Visitor Pass'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Test Visitor');
    await tester.enterText(find.byType(TextField).at(1), '0700 000 0000');
    await tapAndWait(tester, find.text('Generate Pass'), find.text('Fallback code'));

    expect(find.text('Visitor Pass'), findsOneWidget);
    expect(find.text('Test Visitor'), findsOneWidget);
    expect(find.text('Fallback code'), findsOneWidget);
  });

  testWidgets('guard: scan -> result -> record entry -> log', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).at(0), '0803 555 0142');
    await tester.enterText(find.byType(TextField).at(1), 'estate123');

    // Switch to guard role before logging in.
    await tester.tap(find.text('Security Guard'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '0805 222 9981');
    await tester.enterText(find.byType(TextField).at(1), 'guard123');
    await tapAndWait(tester, find.text('Log In'), find.text('Security Gate'));

    expect(find.text('Security Gate'), findsOneWidget);
    expect(find.text('Simulate Scan'), findsOneWidget);

    // Either a valid/expired pass or "Code Not Recognized" — all three render one of these titles.
    final possibleResults = [find.text('Pass Valid'), find.text('Pass Expired'), find.text('Code Not Recognized')];
    await tester.tap(find.text('Simulate Scan'));
    await pumpUntilAnyFound(tester, possibleResults);
    await tester.pumpAndSettle();
    final resultShown = possibleResults.any((f) => f.evaluate().isNotEmpty);
    expect(resultShown, isTrue);

    await tester.tap(find.text('← Back to scanner'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Chioma Nwosu'), findsOneWidget);
  });

  testWidgets('login: wrong password shows error, temp1234 triggers force reset', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).at(0), '0803 555 0142');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tapAndWait(tester, find.text('Log In'), find.text('Incorrect phone number or password.'));
    expect(find.text('Incorrect phone number or password.'), findsOneWidget);

    // temp1234 is the seeded force-reset demo account's password, tied to
    // its own phone number (08099990000) — not Ifeoma's — since the real
    // backend checks an actual phone+password pair rather than treating
    // "temp1234" as a magic value.
    await tester.enterText(find.byType(TextField).at(0), '0809 999 0000');
    await tester.enterText(find.byType(TextField).at(1), 'temp1234');
    await tapAndWait(tester, find.text('Log In'), find.text('Welcome, New'));
    expect(find.text('Welcome, New'), findsOneWidget);
  });
}
