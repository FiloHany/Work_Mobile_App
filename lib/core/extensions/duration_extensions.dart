extension DurationX on Duration {
  /// "2h 30m" or "−1h 15m" — skips zero components, handles negatives.
  String get formatted {
    if (this == Duration.zero) return '0m';
    final neg = isNegative;
    final abs = neg ? -this : this;
    final h = abs.inHours;
    final m = abs.inMinutes % 60;
    final sign = neg ? '−' : '';
    if (h > 0 && m > 0) return '$sign${h}h ${m}m';
    if (h > 0) return '$sign${h}h';
    return '$sign${m}m';
  }

  /// "02:30" or "−01:15" — always two digits for each part.
  String get clockFormat {
    final neg = isNegative;
    final abs = neg ? -this : this;
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '${neg ? '−' : ''}$h:$m';
  }

  /// Fractional hours as double (e.g. 1h30m → 1.5).
  double get inFractionalHours => inMinutes / 60.0;

  /// Clamp to zero if negative.
  Duration get nonNegative => isNegative ? Duration.zero : this;

  bool get isZero => this == Duration.zero;
}
