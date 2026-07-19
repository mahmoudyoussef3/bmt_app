import 'package:flutter/material.dart';

/// Stand-in shown before the ticket is on screen — while it loads, and if it
/// fails to load. Both keep a bare back-navigable app bar so the client is
/// never stranded on a blank page.
class TicketDetailsPlaceholder extends StatelessWidget {
  const TicketDetailsPlaceholder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: Center(child: child),
    );
  }
}
