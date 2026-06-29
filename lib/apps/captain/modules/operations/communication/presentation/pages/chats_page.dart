import 'package:bmt_app/apps/captain/modules/operations/communication/presentation/pages/chat_details_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تواصل الرحلة')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChatDetailsPage(tripId: tripId, title: 'جميع الركاب'),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.campaign_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('إرسال رسالة لجميع الركاب'),
              subtitle: const Text('تنبيه جماعي مرتبط بهذه الرحلة'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
