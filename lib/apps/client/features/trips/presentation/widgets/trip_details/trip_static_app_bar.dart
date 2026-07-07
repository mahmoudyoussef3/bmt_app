import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// A plain app bar for Trip Details' loading/error/empty states.
class TripStaticAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TripStaticAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ClientColors.surfaceFor(context),
      title: Text(title),
    );
  }
}
