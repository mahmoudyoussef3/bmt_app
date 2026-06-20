import 'package:flutter/material.dart';

import 'client_colors.dart';

abstract final class ClientSpacing {
  const ClientSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(md, sm, md, xl);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets panel = EdgeInsets.all(lg);
}

abstract final class ClientRadius {
  const ClientRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double sheet = 28;
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
      color: ClientColors.shadowFor(context).withAlpha(18),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> md(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(24),
      blurRadius: 22,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> lg(BuildContext context) => [
    BoxShadow(
      color: ClientColors.shadowFor(context).withAlpha(34),
      blurRadius: 34,
      offset: const Offset(0, 18),
    ),
  ];
}
