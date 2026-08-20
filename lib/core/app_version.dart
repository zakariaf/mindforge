/// The version this build reports, as `pubspec.yaml` declares it.
///
/// **A constant, not a package read.** `package_info_plus` would be a
/// dependency, a platform channel and an async call, for one string that is
/// fixed at build time — and `dependency-hygiene` asks what a package buys
/// before it is added. `repo_layout_test` compares this against `pubspec.yaml`,
/// so the two cannot drift apart silently.
///
/// It is the build name only. The `+1` build number after it is a store
/// artefact and means nothing to a player.
const String kAppVersion = '1.0.0';

/// The SPDX identifier this app is published under.
///
/// A constant rather than an ARB message: a licence identifier is a proper noun
/// that is never translated, and writing it into four ARBs would put ASCII
/// digits in the two Arabic-script ones, which the numeral gate refuses.
const String kAppLicence = 'Apache-2.0';
