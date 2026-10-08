/// What the on-device model can do on the current device.
///
/// [available] is false when the OS is too old, the device is not eligible,
/// Apple Intelligence is off, or the model is still downloading. [code] then
/// carries the reason (`DEVICE_NOT_ELIGIBLE`, `APPLE_INTELLIGENCE_NOT_ENABLED`,
/// `MODEL_NOT_READY`, `UNSUPPORTED_OS_VERSION`, `UNSUPPORTED_PLATFORM`).
class NativeAiCapabilities {
  final bool available;
  final String? code;
  final String? reason;

  /// Whether image attachments can be passed to [generateStructured]
  /// (iOS 27 and later, on models with vision support).
  final bool vision;

  /// Whether the device's current locale is one the model supports.
  final bool supportsCurrentLocale;

  final List<String> supportedLanguages;

  const NativeAiCapabilities({
    required this.available,
    this.code,
    this.reason,
    this.vision = false,
    this.supportsCurrentLocale = false,
    this.supportedLanguages = const [],
  });

  static const unsupportedPlatform = NativeAiCapabilities(
    available: false,
    code: 'UNSUPPORTED_PLATFORM',
    reason: 'Apple Foundation Models are only available on iOS.',
  );

  factory NativeAiCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return NativeAiCapabilities(
      available: map['available'] == true,
      code: map['code'] as String?,
      reason: map['reason'] as String?,
      vision: map['vision'] == true,
      supportsCurrentLocale: map['supportsCurrentLocale'] == true,
      supportedLanguages:
          (map['supportedLanguages'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  @override
  String toString() =>
      'NativeAiCapabilities(available: $available, code: $code, vision: $vision, '
      'supportsCurrentLocale: $supportsCurrentLocale)';
}
