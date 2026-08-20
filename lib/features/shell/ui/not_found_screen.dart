import 'package:flutter/material.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// What an unknown location renders.
///
/// A screen rather than a red box: a stale deep link or a mistyped URL is
/// something a person can hit, and `go_router`'s default error page is an
/// English stack trace on a red field.
class NotFoundScreen extends StatelessWidget {
  /// Creates the screen.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);

    return Scaffold(
      backgroundColor: colours.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(
            AppLocalizations.of(context).notFoundTitle,
            style: type.title.copyWith(color: colours.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
