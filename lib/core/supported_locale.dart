/// The locales MindForge ships, and the **only** enumeration of them in the
/// repository.
///
/// `lib/l10n/`'s `supportedLocales`, the `CFBundleLocalizations` array in
/// `ios/Runner/Info.plist`, and the test harness's locale matrix are all
/// projections of this enum, asserted against it. A second list is how a locale
/// ends up shipped in one place and unreachable in another.
///
/// The enum is **pure**: it names no `Locale`, no `TextDirection` and no
/// Flutter type, so `lib/core/` stays Flutter-free and the data layer can
/// depend on it.
enum SupportedLocale {
  /// English. The template ARB, the source of truth for keys, and the fallback
  /// when the system locale is not one of these.
  en('en'),

  /// German. The text-expansion stress case — roughly 30% longer than English.
  de('de'),

  /// Persian. Arabic script, right-to-left, Eastern Arabic numerals.
  fa('fa'),

  /// Kurdish Sorani. Arabic script plus the Sorani letters ڕ ڵ ۆ ێ ھ,
  /// right-to-left.
  ///
  /// Not served by `GlobalMaterialLocalizations` and carries no `intl` number
  /// symbols; both gaps are measured in `docs/decisions/0001-localisation.md`
  /// and closed in E04.
  ckb('ckb');

  const SupportedLocale(this.tag);

  /// The BCP-47 language tag. This exact ASCII string is what the
  /// `settings.locale_tag` column stores.
  final String tag;

  /// Whether text in this locale reads right to left.
  ///
  /// Recorded here so E04 has one authority for direction. Nothing under
  /// `lib/data/` reads it — direction is a render fact, not a storage concern.
  bool get isRightToLeft => this == fa || this == ckb;

  /// The locale whose [tag] is exactly [tag], or `null` if there is none.
  ///
  /// The match is **exact and total**: it never throws, and it does not fall
  /// back from `fa-IR` to `fa` or from `EN` to `en`. A near miss that resolved
  /// would silently give someone the wrong language, and the caller that most
  /// needs this — reading a possibly-stale `locale_tag` out of the database —
  /// wants `null` so it can degrade to the system locale.
  static SupportedLocale? tryParse(String tag) {
    for (final locale in values) {
      if (locale.tag == tag) return locale;
    }
    return null;
  }
}
