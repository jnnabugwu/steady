/// Whether this device's iCloud account can back Steady's data.
///
/// CloudKit is the whole auth story (CLAUDE.md §1): the Apple Account is the
/// account, so there is no login, password or session here, only "is the
/// device signed in to iCloud". iCloud is optional (CLAUDE.md §7): when
/// it can't be used, Steady keeps working and the data stays on this
/// device until it can sync.
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
  /// the status isn't read. Local debug builds stay quiet about it until
  /// CloudKit is set up.
  notConfigured;

  /// Whether iCloud is known not to be syncing this device's data, for a
  /// reason the user can see (and usually fix) in Settings.
  ///
  /// True for [noAccount], [restricted] and [temporarilyUnavailable]. The
  /// app never blocks on it (CLAUDE.md §7): data is kept on the device and
  /// syncs once iCloud can be used. False for [available], for
  /// [notConfigured] (the build has no CloudKit, which isn't the user's to
  /// fix) and for [couldNotDetermine] (CloudKit didn't say, so there's
  /// nothing definite to tell the user).
  bool get blocksSync =>
      this == noAccount || this == restricted || this == temporarilyUnavailable;
}
