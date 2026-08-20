import 'package:mindforge/l10n/locale_numbers.dart';

/// One already-formatted label per cell, in cell order.
///
/// **The caller supplies the formatter.** `LocaleNumbers` is the app's one
/// `NumberFormat` construction site, and `ckb` borrows `fa`'s symbol data there
/// because `intl` ships none for it and would otherwise fall back to Latin
/// digits without saying so. Building a formatter here would be a second place
/// that pin has to be remembered.
///
/// **Formatted once per board, not once per tile.** Twenty-five tiles each
/// formatting their own value is twenty-five allocations per frame for a list
/// that only changes when the locale does.
///
/// The order is the SCRAMBLE'S order. A helper that sorted would put 1 in the
/// top-left corner of every board, which is the one arrangement this game may
/// not draw.
List<String> schulteTileLabels(List<int> cells, LocaleNumbers numbers) =>
    <String>[for (final value in cells) numbers.count(value)];
