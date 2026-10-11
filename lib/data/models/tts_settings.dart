class TtsSettings {
  final String language;
  final String? voiceName;
  final double speechRate;
  final double pitch;
  final double volume;

  const TtsSettings({
    this.language = 'fr-FR',
    this.voiceName,
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  TtsSettings copyWith({
    String? language,
    String? voiceName,
    double? speechRate,
    double? pitch,
    double? volume,
  }) {
    return TtsSettings(
      language: language ?? this.language,
      voiceName: voiceName ?? this.voiceName,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }
}
