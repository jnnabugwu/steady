/// Whether this device's iCloud account can back Steady's data.
///
/// CloudKit is the whole auth story (CLAUDE.md §1): the Apple Account is the
/// account, so there is no login, password or session here, only "is the
/// device signed in to iCloud". iCloud is required, with no local-only
/// fallback (CLAUDE.md §7).
///
/// The first five values mirror CloudKit's `CKAccountStatus`.
/// [notConfigured] is Steady's own: the build has no CloudKit container or
/// entitlement yet, so the status can't be read at all.
enum AccountStatus {
  /// Signed in to iCloud, and CloudKit can be used.
  available,

  /// No iCloud account is signed in on this device.
  noAccount,

  /// iCloud is restricted on this device (Screen Time, a device management
  /// profile or parental controls).
  restricted,

  /// Signed in, but iCloud can't be used right now (for example, the
  /// account is still being set up or needs its terms accepted).
  temporarilyUnavailable,

  /// CloudKit couldn't tell. Also what an unrecognised status from the
  /// platform maps to.
  couldNotDetermine,

  /// This build has no CloudKit container or entitlement configured, so
  /// the status isn't read. Never blocks the app, so local debug builds
  /// stay usable until CloudKit is set up.
  notConfigured;

  /// Whether this status definitively means the user must sign in (or lift
  /// a restriction) before using Steady.
  ///
  /// Only [noAccount] and [restricted] do. [temporarilyUnavailable],
  /// [couldNotDetermine] and [notConfigured] never block: they're either
  /// transient or not the user's to fix, and blocking on them would lock
  /// someone out of their own data for no reason they can act on.
  bool get requiresSignIn => this == noAccount || this == restricted;
}
