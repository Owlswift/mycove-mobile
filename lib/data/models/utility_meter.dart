enum MeterType { prepaid, postpaid }

MeterType meterTypeFromJson(String value) =>
    value == 'POSTPAID' ? MeterType.postpaid : MeterType.prepaid;

String meterTypeToJson(MeterType type) =>
    type == MeterType.postpaid ? 'POSTPAID' : 'PREPAID';

class UtilityMeter {
  const UtilityMeter({
    required this.id,
    required this.discoCode,
    required this.discoName,
    required this.meterNumber,
    required this.meterType,
    this.customerName,
    this.address,
  });

  factory UtilityMeter.fromJson(Map<String, dynamic> json) {
    return UtilityMeter(
      id: json['id'] as String,
      discoCode: json['discoCode'] as String,
      discoName: json['discoName'] as String,
      meterNumber: json['meterNumber'] as String,
      meterType: meterTypeFromJson(json['meterType'] as String),
      customerName: json['customerName'] as String?,
      address: json['address'] as String?,
    );
  }

  final String id;
  final String discoCode;
  final String discoName;
  final String meterNumber;
  final MeterType meterType;
  final String? customerName;
  final String? address;
}

/// A DISCO entry for the picker, fetched from `GET /utilities/discos` (see
/// AppState.discos) rather than hardcoded — [code] is the exact serviceID
/// VTpass (and BuyPower, via its own internal translation) expects.
/// [shortCode] is the real-world abbreviation shown in the app (e.g.
/// "IBEDC") — it also doubles as the bundled logo asset's filename,
/// lowercased (assets/images/discos/ibedc.png), see [discoLogoAsset].
class Disco {
  const Disco(this.code, this.shortCode, this.name);

  factory Disco.fromJson(Map<String, dynamic> json) => Disco(
    json['code'] as String,
    json['shortCode'] as String,
    json['name'] as String,
  );

  final String code;
  final String shortCode;
  final String name;
}

/// Falls back to the raw code if somehow not found — keeps display code
/// simple rather than throwing over a cosmetic lookup.
String discoShortCode(List<Disco> discos, String code) => discos
    .firstWhere((d) => d.code == code, orElse: () => Disco(code, code, code))
    .shortCode;

/// The bundled logo's asset path for a DISCO — the file may not exist yet
/// (logos are added incrementally), so callers should wrap this in an
/// `errorBuilder` that falls back to a placeholder rather than assume it's
/// there.
String discoLogoAsset(Disco disco) =>
    'assets/images/discos/${disco.shortCode.toLowerCase()}.png';

/// Cosmetic grouping for read-only display (e.g. "0123 4567 8901") — the
/// live entry field itself stays plain digits, no input masking.
String formatMeterNumber(String raw) {
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}
