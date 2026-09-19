import 'package:flutter_test/flutter_test.dart';
import 'package:mycove/data/models/access_log_entry.dart';
import 'package:mycove/data/models/chairman.dart';

void main() {
  test('DuesOverview parses the /finance/dues shape and sorts who is owing', () {
    final dues = DuesOverview.fromJson({
      'monthlyAmount': 45000,
      'totals': {'expected': 900000, 'collected': 630000, 'outstanding': 270000},
      'residents': [
        {'id': 'a', 'fullName': 'Ada Obi', 'house': '4 Palm Street', 'phone': '0801', 'duesBalance': 45000, 'monthsPaid': 8},
        {'id': 'b', 'fullName': 'Bayo Ade', 'house': null, 'phone': '0802', 'duesBalance': 0, 'monthsPaid': 9},
        {'id': 'c', 'fullName': 'Chi Eze', 'house': '9 Olive Close', 'phone': '0803', 'duesBalance': 225000, 'monthsPaid': 4},
      ],
    });

    expect(dues.collected, 630000);
    expect(dues.collectionRate, closeTo(0.7, 1e-9));
    expect(dues.owing.map((r) => r.fullName), ['Chi Eze', 'Ada Obi']);
  });

  test('DuesOverview copes with an estate that has no monthly rate yet', () {
    final dues = DuesOverview.fromJson({
      'monthlyAmount': null,
      'totals': {'expected': 0, 'collected': 0, 'outstanding': 0},
      'residents': <dynamic>[],
    });
    expect(dues.monthlyAmount, isNull);
    expect(dues.collectionRate, 0);
    expect(dues.owing, isEmpty);
  });

  test('TreasurySummary and complaints parse the server shapes', () {
    final treasury = TreasurySummary.fromJson({
      'totalCollected': 1000,
      'totalAllocated': 400,
      'treasuryBalance': 600,
      'projects': [
        {'id': 'p1', 'title': 'Gate', 'allocated': 400, 'spent': 100, 'remaining': 300, 'donated': 50, 'pledged': 20},
      ],
    });
    expect(treasury.fundsFor('p1')?.remaining, 300);
    expect(treasury.fundsFor('nope'), isNull);

    final complaint = AdminComplaint.fromJson({
      'id': 'c1',
      'ref': 'MC-1001',
      'category': 'Security',
      'description': 'Gate light is out',
      'status': 'IN_REVIEW',
      'createdAt': '2026-09-10T08:30:00.000Z',
      'user': {'fullName': 'Ada Obi', 'phone': '0801', 'house': '4 Palm Street'},
    });
    expect(complaint.isOpen, isTrue);
    expect(complaint.statusLabel, 'In review');
    expect(complaint.residentName, 'Ada Obi');
  });

  test('AccessLogEntry keeps which resident the visitor came to see', () {
    final entry = AccessLogEntry.fromJson({
      'id': 'e1',
      'visitor': 'Chidi',
      'entryAt': '2026-09-10T08:30:00.000Z',
      'exitAt': null,
      'resident': {'id': 'r1', 'fullName': 'Ada Obi', 'house': '4 Palm Street', 'phone': '0801'},
    });
    expect(entry.residentName, 'Ada Obi');
    expect(entry.residentHouse, '4 Palm Street');
    expect(entry.exit, isNull);
  });
}
