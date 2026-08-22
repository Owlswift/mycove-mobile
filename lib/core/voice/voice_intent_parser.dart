/// Turns a speech-to-text transcript into one of the intents the backend's
/// `POST /voice/prepare` understands — no LLM call, just keyword and number
/// matching, deliberately scoped to the small, fixed intent set the backend
/// actually supports (see VoiceCommandDto). Swapping this for an LLM-backed
/// parser later doesn't touch anything downstream, since both would produce
/// the same [ParsedVoiceCommand] shape.
library;

import '../../data/models/utility_meter.dart' show Disco, UtilityMeter;

enum VoiceIntent {
  buyElectricity,
  buyAirtime,
  checkBalance,
  transactionHistory,
  checkDues,
  duesMonthsPaid,
  electricitySpendByMonth,
  nextMeeting,
  visitorCount,
  newUpdates,
}

/// Only the intents the backend's `/voice/prepare` actually understands
/// need an API string — the rest (added later, resolved fully client-side
/// from data already in `AppState`) never reach that endpoint at all.
String voiceIntentToApi(VoiceIntent intent) => switch (intent) {
  VoiceIntent.buyElectricity => 'BUY_ELECTRICITY',
  VoiceIntent.buyAirtime => 'BUY_AIRTIME',
  VoiceIntent.checkBalance => 'CHECK_BALANCE',
  VoiceIntent.transactionHistory => 'TRANSACTION_HISTORY',
  _ => throw StateError('$intent has no backend /voice/prepare equivalent'),
};

class ParsedVoiceCommand {
  const ParsedVoiceCommand({required this.intent, this.amount, this.network, this.month, this.weekCount});

  final VoiceIntent intent;
  final int? amount;
  final String? network;
  final int? month; // 1-12, for electricitySpendByMonth
  final int? weekCount; // for visitorCount
}

/// Null means the transcript didn't match anything this parser understands
/// — the caller should show a "sorry, I didn't understand that" response
/// rather than guess.
ParsedVoiceCommand? parseVoiceCommand(String rawText) {
  final text = rawText.toLowerCase().trim();
  if (text.isEmpty) return null;

  final amount = extractAmount(text);

  // Airtime/network words checked before electricity's, since "recharge"
  // and network names are unambiguous, whereas a generic "buy" alone
  // shouldn't be assumed to mean either.
  if (_matchesAny(text, [
    'airtime',
    'air time',
    'a time', // on-device STT frequently splits "airtime" into "a time"
    'recharge',
    'top up',
    'topup',
    'credit my phone',
  ])) {
    return ParsedVoiceCommand(
      intent: VoiceIntent.buyAirtime,
      amount: amount,
      network: extractNetwork(text),
    );
  }
  // Checked before the plain electricity/buy keywords below, since "how
  // much electricity have I bought" contains the bare word "electricity"
  // and would otherwise be mistaken for a fresh BUY_ELECTRICITY command.
  if (text.contains('electricity') &&
      _matchesAny(text, ['bought', 'spent', 'used', 'purchase', 'purchased'])) {
    return ParsedVoiceCommand(intent: VoiceIntent.electricitySpendByMonth, month: extractMonth(text));
  }
  if (_matchesAny(text, [
    'electricity',
    'light',
    'meter',
    'power',
    'nepa',
    'phcn',
  ])) {
    return ParsedVoiceCommand(intent: VoiceIntent.buyElectricity, amount: amount);
  }
  if (_matchesAny(text, [
    'transaction history',
    'transaction',
    'recent purchase',
    'recent activity',
    'my transactions',
  ])) {
    return const ParsedVoiceCommand(intent: VoiceIntent.transactionHistory);
  }
  // Checked before "months"-less generic phrasing, and before the plain
  // balance check below, since "how many months dues have I paid" also
  // contains "dues" (which checkDues would otherwise claim first).
  if (text.contains('month') && text.contains('paid')) {
    return const ParsedVoiceCommand(intent: VoiceIntent.duesMonthsPaid);
  }
  // Checked before the plain balance check below, since "what's my dues
  // balance" contains "balance" and would otherwise resolve to the wallet's
  // CHECK_BALANCE instead of the (unrelated) estate dues balance. Levies
  // are a separate concept from dues (one-off named charges, shown on the
  // same Dues page) but residents don't reliably distinguish the two out
  // loud — "levies" alone routes here too, and the spoken answer covers
  // both (see _answerCheckDues).
  if (_matchesAny(text, ['owing', 'owe', 'dues', 'levies', 'levy'])) {
    return const ParsedVoiceCommand(intent: VoiceIntent.checkDues);
  }
  if (_matchesAny(text, [
    'balance',
    'how much do i have',
    'how much i get',
    'what do i have',
    'my wallet',
  ])) {
    return const ParsedVoiceCommand(intent: VoiceIntent.checkBalance);
  }
  if (_matchesAny(text, ['next meeting', 'meeting'])) {
    return const ParsedVoiceCommand(intent: VoiceIntent.nextMeeting);
  }
  if (_matchesAny(text, ['visitor', 'visitors', 'guest', 'guests'])) {
    return ParsedVoiceCommand(intent: VoiceIntent.visitorCount, weekCount: extractWeekCount(text));
  }
  if (_matchesAny(text, ['update', 'updates', 'announcement', 'announcements', 'news', 'notice', 'notices'])) {
    return const ParsedVoiceCommand(intent: VoiceIntent.newUpdates);
  }
  return null;
}

bool looksLikeConfirmation(String text) {
  final t = text.toLowerCase().trim();
  return _matchesAny(t, [
    'confirm',
    'yes',
    'yeah',
    'yep',
    'proceed',
    'go ahead',
    'do it',
    'okay',
    'ok',
    'sure',
  ]);
}

bool looksLikeCancellation(String text) {
  final t = text.toLowerCase().trim();
  return _matchesAny(t, [
    'cancel',
    'no',
    'nope',
    'stop',
    'never mind',
    'nevermind',
  ]);
}

bool _matchesAny(String text, List<String> keywords) =>
    keywords.any(text.contains);

const _spokenDigits = {
  'zero': '0',
  'oh': '0',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
};

/// Meter numbers are raw 10-13 digit strings, not spoken like money — kept
/// separate from [extractAmount] so "2 3 4 5 6 7 8 9 0 1 1 1" isn't run
/// through k/thousand-word parsing meant for naira amounts. Residents often
/// read a long meter number out digit by digit rather than as one number,
/// and on-device speech recognition doesn't reliably collapse "one one
/// one..." into "111" the way it does for shorter, more "number-like"
/// utterances — so spelled-out single digits are matched too, not just
/// literal numeral characters.
String? extractDigitsOnly(String text) {
  final raw = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (raw.length >= 10) return raw;

  final buffer = StringBuffer();
  for (final word in text.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
    if (RegExp(r'^\d+$').hasMatch(word)) {
      buffer.write(word);
    } else if (_spokenDigits.containsKey(word)) {
      buffer.write(_spokenDigits[word]);
    }
  }
  final spelled = buffer.toString();
  return spelled.length >= 10 ? spelled : null;
}

const _discoNameStopWords = {
  'electricity',
  'electric',
  'distribution',
  'company',
  'plc',
  'and',
  'of',
};

/// Matches a spoken utterance against the estate's real DISCO list (fetched
/// from the backend, so this can't be a fixed keyword list) — checked first
/// against each DISCO's short code (least ambiguous, e.g. "ikedc"), then
/// against distinctive words from its full name (e.g. "ikeja"), skipping
/// generic words nearly every DISCO's name shares ("electricity" etc).
///
/// Falls back to the closest DISCO by edit distance against the short code
/// when nothing matches exactly — on-device speech recognition has no idea
/// "IBEDC" is a utility company, so it tends to autocorrect it toward a
/// real word/acronym it *does* know (e.g. "IBTC", a bank). A distance-2
/// threshold catches that kind of near-miss without matching wildly
/// unrelated words — but only among words spoken right after "from", since
/// that's how a provider actually gets named ("...electricity from
/// IBEDC"). Scanning every word in the sentence against short 4-6 letter
/// codes produces false positives on ordinary words (e.g. plain "need" is
/// edit-distance 2 from "PHED"), which wrongly picked a DISCO even when
/// the resident never named one and just meant "use my saved meter".
Disco? extractDisco(String text, List<Disco> discos) {
  final t = text.toLowerCase();
  for (final d in discos) {
    if (t.contains(d.shortCode.toLowerCase())) return d;
  }
  for (final d in discos) {
    final words = d.name
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_discoNameStopWords.contains(w));
    if (words.any(t.contains)) return d;
  }

  final fromIndex = t.indexOf('from ');
  if (fromIndex == -1) return null;
  final afterFrom = t.substring(fromIndex + 'from '.length);

  Disco? closest;
  var bestDistance = 3;
  for (final candidate in afterFrom.split(RegExp(r'\s+')).where((w) => w.length >= 3)) {
    for (final d in discos) {
      final distance = _levenshtein(candidate, d.shortCode.toLowerCase());
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = d;
      }
    }
  }
  return closest;
}

int _levenshtein(String a, String b) {
  final costs = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    var previousDiagonal = costs[0];
    costs[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final previousAbove = costs[j];
      costs[j] = a[i - 1] == b[j - 1]
          ? previousDiagonal
          : 1 + [previousDiagonal, previousAbove, costs[j - 1]].reduce((x, y) => x < y ? x : y);
      previousDiagonal = previousAbove;
    }
  }
  return costs[b.length];
}

/// Picks which of a resident's *saved* meters an utterance means when they
/// have more than one — by its DISCO name (same word-matching as
/// [extractDisco], just against `UtilityMeter.discoName` directly since a
/// saved meter already carries that string) or by the meter number's
/// trailing digits (e.g. "the one ending in 1111").
UtilityMeter? matchMeterChoice(String text, List<UtilityMeter> meters) {
  final t = text.toLowerCase();
  for (final m in meters) {
    final words = m.discoName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_discoNameStopWords.contains(w));
    if (words.any(t.contains)) return m;
  }
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 3) {
    for (final m in meters) {
      if (m.meterNumber.endsWith(digits)) return m;
    }
  }
  return null;
}

const _monthNames = {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};

/// 1-12, or null if no month reference is present. "This month" resolves
/// to the current calendar month rather than requiring a named month.
int? extractMonth(String text) {
  final t = text.toLowerCase();
  if (t.contains('this month')) return DateTime.now().month;
  for (final entry in _monthNames.entries) {
    if (t.contains(entry.key)) return entry.value;
  }
  return null;
}

/// How many weeks back a "how many visitors in the past N weeks" question
/// covers. A bare "week"/"this week" with no number defaults to 1.
int? extractWeekCount(String text) {
  final t = text.toLowerCase();
  if (!t.contains('week')) return null;
  final digitMatch = RegExp(r'(\d+)\s*weeks?').firstMatch(t);
  if (digitMatch != null) return int.tryParse(digitMatch.group(1)!);
  for (final entry in _numberUnits.entries) {
    if (t.contains('${entry.key} week')) return entry.value;
  }
  return 1;
}

String? extractNetwork(String text) {
  const map = {
    'mtn': 'mtn',
    'airtel': 'airtel',
    'glo': 'glo',
    '9mobile': 'etisalat',
    'nine mobile': 'etisalat',
    'etisalat': 'etisalat',
  };
  for (final entry in map.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Handles digit amounts ("20000", "20,000"), a "k"/"thousand" suffix
/// ("20k", "20 thousand"), and common English number words ("twenty
/// thousand", "five hundred") — covers what residents actually say for a
/// utility top-up without needing a full number-parsing library. Public
/// so a bare follow-up answer to a clarification question (e.g. "5000
/// naira", with no intent keyword) can still be parsed for its amount.
int? extractAmount(String text) {
  final kMatch = RegExp(r'(\d+(?:\.\d+)?)\s*k\b').firstMatch(text);
  if (kMatch != null) {
    final base = double.tryParse(kMatch.group(1)!);
    if (base != null) return (base * 1000).round();
  }
  final thousandMatch = RegExp(r'(\d+(?:\.\d+)?)\s*thousand\b').firstMatch(text);
  if (thousandMatch != null) {
    final base = double.tryParse(thousandMatch.group(1)!);
    if (base != null) return (base * 1000).round();
  }
  final digitMatch = RegExp(r'\d[\d,]*').firstMatch(text);
  if (digitMatch != null) {
    final cleaned = digitMatch.group(0)!.replaceAll(',', '');
    final value = int.tryParse(cleaned);
    if (value != null) return value;
  }
  return _parseNumberWords(text);
}

const _numberUnits = {
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
};
const _numberTens = {
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

int? _parseNumberWords(String text) {
  final words = text
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);

  int total = 0;
  int current = 0;
  var found = false;

  for (final word in words) {
    if (_numberUnits.containsKey(word)) {
      current += _numberUnits[word]!;
      found = true;
    } else if (_numberTens.containsKey(word)) {
      current += _numberTens[word]!;
      found = true;
    } else if (word == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
      found = true;
    } else if (word == 'thousand') {
      current = (current == 0 ? 1 : current) * 1000;
      total += current;
      current = 0;
      found = true;
    }
  }
  if (!found) return null;
  return total + current;
}
