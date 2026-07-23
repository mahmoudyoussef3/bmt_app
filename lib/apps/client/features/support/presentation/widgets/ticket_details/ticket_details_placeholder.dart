import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Stand-in shown before the ticket is on screen — while it loads, and if it
/// fails to load. Both keep a back-navigable app bar so the client is never
/// stranded on a blank page.
class TicketDetailsPlaceholder extends StatelessWidget {
  const TicketDetailsPlaceholder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ClientAppBar(
        title: context.l10n.support_ticketDetailsTitle,
        backgroundColor: Colors.transparent,
      ),
      body: Center(child: child),
    );
  }
}
