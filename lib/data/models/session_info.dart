class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.jti,
    required this.platform,
    required this.lastUsedAt,
    this.deviceName,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as String,
      jti: json['jti'] as String,
      platform: json['platform'] as String, // ANDROID | IOS
      deviceName: json['deviceName'] as String?,
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }

  final String id;
  final String jti;
  final String platform;
  final String? deviceName;
  final DateTime lastUsedAt;
}
