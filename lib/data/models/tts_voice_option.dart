/// One entry from `flutter_tts`'s `getVoices` — only the two fields
/// `setVoice` actually needs (name + locale); iOS also returns
/// gender/quality/identifier, which aren't needed here.
class TtsVoiceOption {
  const TtsVoiceOption({required this.name, required this.locale});

  factory TtsVoiceOption.fromMap(Map<dynamic, dynamic> map) => TtsVoiceOption(
    name: map['name'] as String,
    locale: map['locale'] as String,
  );

  final String name;
  final String locale;

  Map<String, String> toVoiceMap() => {'name': name, 'locale': locale};

  @override
  bool operator ==(Object other) =>
      other is TtsVoiceOption && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}
