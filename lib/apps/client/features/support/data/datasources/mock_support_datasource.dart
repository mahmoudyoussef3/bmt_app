import '../../domain/entities/support_ticket.dart';
import '../models/support_ticket_model.dart';

class MockSupportDatasource {
  const MockSupportDatasource();

  Future<List<String>> getCategories() async {
    return const [
      'Booking Issue',
      'Driver Issue',
      'Vehicle Issue',
      'Route Issue',
      'Technical Issue',
      'Refund Request',
      'Other',
    ];
  }

  Future<List<SupportTicketModel>> getTickets() async {
    return const [
      SupportTicketModel(
        id: '#TK-9402',
        category: 'Driver Issue',
        title: 'Shuttle departed 15 minutes early',
        description:
            'I arrived at the stop at 8:28 AM but the shuttle was already gone. I had to take a taxi.',
        priority: 'High',
        status: TicketStatus.inProgress,
        dateCreated: 'Jun 2, 2026',
        attachedImages: ['screenshot_828am_map.png'],
        conversation: [
          {
            'sender': 'user',
            'text':
                'I missed my shuttle because the captain left before scheduled departure time.',
            'time': '10:15 AM',
          },
          {
            'sender': 'agent',
            'text':
                'Apologies for the inconvenience, Ahmed. We are checking the shuttle logs and will update you shortly.',
            'time': '11:04 AM',
          },
        ],
      ),
      SupportTicketModel(
        id: '#TK-8139',
        category: 'Technical Issue',
        title: 'App crashed during seat selection',
        description:
            'The screen turned grey when I pressed seat 14. I had to restart the app.',
        priority: 'Medium',
        status: TicketStatus.resolved,
        dateCreated: 'May 28, 2026',
        conversation: [
          {
            'sender': 'user',
            'text': 'Grey screen error during checkout.',
            'time': '02:30 PM',
          },
          {
            'sender': 'agent',
            'text':
                'This is fixed in the latest client version. Please update your application.',
            'time': '03:12 PM',
          },
          {
            'sender': 'user',
            'text': 'Working fine now, thanks.',
            'time': '04:00 PM',
          },
        ],
      ),
    ];
  }
}
