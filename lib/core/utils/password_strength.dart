import 'dart:math' as math;

enum StrengthLevel { weak, fair, strong, veryStrong }

/// Entropy of a randomly generated password: length × log2(pool size).
class PasswordStrength {
  const PasswordStrength._(this.bits);

  factory PasswordStrength.of({required int length, required int poolSize}) =>
      PasswordStrength._(poolSize < 2 ? 0 : (length * math.log(poolSize) / math.ln2).round());

  final int bits;

  StrengthLevel get level => bits < 50
      ? StrengthLevel.weak
      : bits < 80
          ? StrengthLevel.fair
          : bits < 110
              ? StrengthLevel.strong
              : StrengthLevel.veryStrong;

  /// Fill of the strength meter; 140 bits reads as full.
  double get fraction => (bits / 140).clamp(0.0, 1.0);
}
