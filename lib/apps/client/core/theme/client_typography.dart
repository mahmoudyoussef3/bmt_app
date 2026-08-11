import 'package:flutter/material.dart';

/// Client-app product typography scale.
///
/// All text in the client app should reference this class rather than building
/// [TextStyle] inline. This makes brand-wide font tweaks (size, weight,
/// letter-spacing) a single-file change.
///
/// Usage:
/// ```dart
/// Text('Book your ride', style: ClientTypography.headingLarge(context))
/// ```
abstract final class ClientTypography {
  ClientTypography._();

  static TextStyle displayLarge(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.05,
      );

  static TextStyle displayMedium(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.08,
      );

  static TextStyle headingLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle headingMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static TextStyle headingSmall(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle bodyLarge(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge!
      .copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle bodyMedium(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.45,
      );

  static TextStyle labelLarge(BuildContext context) => Theme.of(context)
      .textTheme
      .labelLarge!
      .copyWith(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0);

  static TextStyle labelMedium(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium!
      .copyWith(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0);

  static TextStyle labelSmall(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0);

  static TextStyle priceHero(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineMedium!
      .copyWith(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0);

  static TextStyle priceMedium(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0);

  static TextStyle priceSmall(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium!
      .copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0);
}
