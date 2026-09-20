import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycove/features/resident/presentation/pages/domestic_staff_flow_page.dart';
import 'package:mycove/features/resident/presentation/widgets/domestic_format.dart';
import 'package:mycove/features/resident/presentation/widgets/domestic_illustration.dart';

Widget _app(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  test('day and hour wording', () {
    expect(daysLabel([1, 2, 3, 4, 5]), 'Mon–Fri');
    expect(daysLabel([2, 4]), 'Tue, Thu');
    expect(daysLabel([]), 'Any day');
    expect(hoursLabel('07:00', '18:00'), '7:00 AM – 6:00 PM');
    expect(hoursLabel(null, null), 'Any time');
    expect(initialsOf('Mary Johnson'), 'MJ');
  });

  testWidgets('illustration draws with its code text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(_app(const Scaffold(body: Padding(padding: EdgeInsets.all(24), child: DomesticIllustration()))));
    await tester.pumpAndSettle();
    expect(find.text('465297'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add flow: basics -> hours -> review', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(const DomesticStaffFlowPage()));
    await tester.pumpAndSettle();
    expect(find.text('Basic details'), findsOneWidget);

    // Nothing entered: Next is refused with a message
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Enter their name.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let the toast slide away
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Mary Johnson');
    await tester.enterText(find.byType(TextField).at(1), '0801 234 5678');
    await tester.tap(find.text('T').first);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Access hours'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('08:00 AM'), findsOneWidget);
    expect(find.text('02:00 PM'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Review details'), findsOneWidget);
    expect(find.text('+2348012345678'), findsOneWidget);
    expect(find.text('Mary Johnson'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('8:00 AM – 2:00 PM'), findsOneWidget);
    expect(find.text('Require approval for each request'), findsOneWidget);
    expect(find.text('Add domestic staff'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
