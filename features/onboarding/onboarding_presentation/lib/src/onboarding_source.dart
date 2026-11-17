/// Screen 3's answers to "Where did you hear about Steady?", in the order
/// they're shown.
///
/// **Each value's `name` is the code** the app sends as the
/// `onboarding_source` analytics event's only property
/// (docs/design/onboarding.md): `friend`, `instagram`, `reddit`,
/// `appStore`, `tiktok`, `other`. There's no free text. Nothing here is
/// stored, and it never reaches the coach. Renaming a value changes the
/// analytics contract, so don't; `test/onboarding_copy_test.dart` pins
/// every code.
enum OnboardingSource {
  /// "A friend or family".
  friend('A friend or family'),

  /// "Instagram".
  instagram('Instagram'),

  /// "Reddit".
  reddit('Reddit'),

  /// "App Store search".
  appStore('App Store search'),

  /// "TikTok".
  tiktok('TikTok'),

  /// "Something else".
  other('Something else');

  OnboardingSource(this.label);

  /// What the row says.
  final String label;

  /// The analytics code: the value's `name`.
  String get code => name;
}
