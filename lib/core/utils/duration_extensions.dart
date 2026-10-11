extension DurationParsing on String {
  Duration toDuration() {
    final cleaned = replaceAll(',', '.');
    final parts = cleaned.split(':');
    if (parts.length != 3) return Duration.zero;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final secondParts = parts[2].split('.');
    final seconds = int.tryParse(secondParts[0]) ?? 0;
    final milliseconds = secondParts.length > 1
        ? int.tryParse(secondParts[1].padRight(3, '0').substring(0, 3)) ?? 0
        : 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}

extension DurationFormatting on Duration {
  String toTimestamp() {
    final h = inHours.toString().padLeft(2, '0');
    final m = (inMinutes % 60).toString().padLeft(2, '0');
    final s = (inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String toShortTimestamp() {
    if (inHours > 0) return toTimestamp();
    final m = inMinutes.toString().padLeft(2, '0');
    final s = (inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
