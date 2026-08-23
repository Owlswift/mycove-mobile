import 'package:flutter_test/flutter_test.dart';
import 'package:communityhub/core/voice/voice_intent_parser.dart';

void main() {
  group('checkDues — real STT mishearings from residents', () {
    test('"owing" heard correctly routes to checkDues', () {
      final p = parseVoiceCommand('How much am I owing the estate')!;
      expect(p.intent, VoiceIntent.checkDues);
      expect(p.matchedBy, contains('owing'));
    });

    // Regression: on-device STT frequently hears "owing" as "going".
    test('"going" (misheard "owing") routes to checkDues', () {
      final p = parseVoiceCommand('How much am I going the estate')!;
      expect(p.intent, VoiceIntent.checkDues);
      expect(p.matchedBy, contains('going'));
    });

    // Regression: on-device STT frequently hears "debt" as "date".
    test('"date" (misheard "debt") routes to checkDues', () {
      final p = parseVoiceCommand('What is my date to the estate')!;
      expect(p.intent, VoiceIntent.checkDues);
      expect(p.matchedBy, contains('date'));
    });

    test('"debt" itself routes to checkDues', () {
      final p = parseVoiceCommand('What is my debt to the estate')!;
      expect(p.intent, VoiceIntent.checkDues);
      expect(p.matchedBy, contains('debt'));
    });

    test('plain dues phrasing still works', () {
      expect(parseVoiceCommand("what's my dues balance")!.intent,
          VoiceIntent.checkDues);
      expect(parseVoiceCommand('do I have any levies')!.intent,
          VoiceIntent.checkDues);
    });
  });

  group('core intents', () {
    test('buy electricity', () {
      final p = parseVoiceCommand('buy electricity 2000 naira')!;
      expect(p.intent, VoiceIntent.buyElectricity);
      expect(p.amount, 2000);
      expect(p.matchedBy, contains('electricity'));
    });

    test('buy airtime with network', () {
      final p = parseVoiceCommand('buy 1000 mtn airtime')!;
      expect(p.intent, VoiceIntent.buyAirtime);
      expect(p.amount, 1000);
      expect(p.network, 'mtn');
    });

    test('electricity spend by month beats plain buy', () {
      final p = parseVoiceCommand('how much electricity have I bought this month')!;
      expect(p.intent, VoiceIntent.electricitySpendByMonth);
      expect(p.month, DateTime.now().month);
    });

    test('dues months paid beats generic dues', () {
      final p = parseVoiceCommand('how many months dues have I paid')!;
      expect(p.intent, VoiceIntent.duesMonthsPaid);
      expect(p.matchedBy, ['month', 'paid']);
    });

    test('wallet balance', () {
      final p = parseVoiceCommand("what's my balance")!;
      expect(p.intent, VoiceIntent.checkBalance);
      expect(p.matchedBy, contains('balance'));
    });

    test('transaction history', () {
      final p = parseVoiceCommand('show my transactions')!;
      expect(p.intent, VoiceIntent.transactionHistory);
    });

    test('next meeting', () {
      final p = parseVoiceCommand('when is my next meeting')!;
      expect(p.intent, VoiceIntent.nextMeeting);
      expect(p.matchedBy, contains('next meeting'));
    });

    test('last meeting report', () {
      final p = parseVoiceCommand('what was discussed at the last meeting')!;
      expect(p.intent, VoiceIntent.lastMeetingReport);
    });

    test('meeting decisions via decision+meeting pair', () {
      final p =
          parseVoiceCommand('what were the key decisions made in the meeting')!;
      expect(p.intent, VoiceIntent.meetingDecisions);
      expect(p.matchedBy, contains('meeting'));
    });

    test('meeting action items', () {
      final p = parseVoiceCommand('what are the action items from the meeting')!;
      expect(p.intent, VoiceIntent.meetingActionItems);
    });

    test('visitor count with weeks', () {
      final p = parseVoiceCommand('how many visitors in the past 3 weeks')!;
      expect(p.intent, VoiceIntent.visitorCount);
      expect(p.weekCount, 3);
    });

    test('new updates', () {
      final p = parseVoiceCommand('any new updates')!;
      expect(p.intent, VoiceIntent.newUpdates);
    });
  });

  group('false positives — mishearing variants must not hijack other intents', () {
    // "updates" contains the substring "date" — a bare 'date' keyword must
    // not route this to checkDues.
    test('"any new updates" stays newUpdates', () {
      final p = parseVoiceCommand('any new updates')!;
      expect(p.intent, VoiceIntent.newUpdates);
    });

    // "going" appears in plenty of unrelated phrases.
    test('"am I going to the meeting" stays nextMeeting', () {
      final p = parseVoiceCommand('am I going to the meeting')!;
      expect(p.intent, VoiceIntent.nextMeeting);
    });
  });

  group('unparsed turns', () {
    test('unrelated phrase returns null', () {
      expect(parseVoiceCommand('tell me a joke'), isNull);
    });

    test('empty transcript returns null', () {
      expect(parseVoiceCommand(''), isNull);
    });
  });
}