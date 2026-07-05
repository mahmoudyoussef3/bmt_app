import 'package:flutter/material.dart';

import 'client_colors.dart';

abstract final class ClientSpacing {
  const ClientSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 56;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(24, 16, 24, 32);
  static const EdgeInsets card = EdgeInsets.all(24);
  static const EdgeInsets panel = EdgeInsets.all(24);
}

abstract final class ClientRadius {
  const ClientRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double sheet = 32;
  static const double pill = 999;
}

abstract final class ClientMotion {
  const ClientMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class ClientElevation {
  const ClientElevation._();

  static List<BoxShadow> sm(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(8),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> md(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> lg(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(16),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
