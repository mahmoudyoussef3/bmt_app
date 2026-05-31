import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  @override
  void initState() {
    super.initState();
    DriverService.cubitInstance.addListener(_onChange);
  }

  @override
  void dispose() {
    DriverService.cubitInstance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final notes = DriverService.cubitInstance.notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final n = notes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.body,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(170),
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (n.unread) AppBadge(text: 'New'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
