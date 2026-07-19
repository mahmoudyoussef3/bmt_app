import 'package:flutter/material.dart';

/// Full-screen centered message shown when the daily booking data fails to
/// load before any step can be rendered.
class DailyBookingMessage extends StatelessWidget {
  const DailyBookingMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
