import '../models/conversation_model.dart';

class MockCommunicationDatasource {
  const MockCommunicationDatasource();

  Future<List<ConversationModel>> getConversations() async {
    return const [
      ConversationModel(
        id: 'conv_driver_ahmed',
        name: 'Captain Ahmed Mohamed',
        category: 'Driver',
        lastMessage: 'I have arrived at Banha Station stop. Gate 2.',
        time: '8:42 AM',
        initials: 'AM',
        isOnline: true,
        unreadCount: 1,
        meta: {
          'vehicle': 'MB-15-2847 (Comfort Van)',
          'route': 'Banha Station → Smart Village',
          'eta': 'Arrived',
          'rating': '4.9 ★',
        },
        messages: [
          ChatMessageModel(
            id: 'd1',
            sender: 'other',
            senderName: 'Captain Ahmed',
            text: 'Good morning, Ahmed. I am on my way to the pickup point.',
            time: '8:20 AM',
          ),
          ChatMessageModel(
            id: 'd2',
            sender: 'user',
            senderName: 'User',
            text: 'Great, thanks! Should I wait near the main gate?',
            time: '8:22 AM',
          ),
          ChatMessageModel(
            id: 'd3',
            sender: 'other',
            senderName: 'Captain Ahmed',
            text: 'Yes, near Gate 2 under the blue banner.',
            time: '8:24 AM',
          ),
          ChatMessageModel(
            id: 'd4',
            sender: 'other',
            senderName: 'Captain Ahmed',
            text: 'I have arrived at Banha Station stop. Gate 2.',
            time: '8:42 AM',
            isRead: false,
          ),
        ],
      ),
      ConversationModel(
        id: 'conv_group_banha',
        name: 'Shuttle Group: Banha #12',
        category: 'Group',
        lastMessage: 'Is anyone late today? We are moving in 5 mins.',
        time: 'Yesterday',
        initials: 'BG',
        meta: {
          'membersCount': '14 members',
          'route': 'Banha Station ↔ Smart Village Daily',
          'shuttle': 'Plate: MB-15-2847',
        },
        messages: [
          ChatMessageModel(
            id: 'g1',
            sender: 'other',
            senderName: 'Sara Kamel',
            text: 'AC is freezing cold today, can we adjust it?',
            time: 'Yesterday, 8:10 AM',
          ),
          ChatMessageModel(
            id: 'g2',
            sender: 'other',
            senderName: 'Captain Ahmed',
            text: 'Sure, I will turn down the fan speed.',
            time: 'Yesterday, 8:12 AM',
          ),
          ChatMessageModel(
            id: 'g3',
            sender: 'other',
            senderName: 'Hazem Refaat',
            text: 'Thanks Sara, was about to ask as well!',
            time: 'Yesterday, 8:15 AM',
          ),
          ChatMessageModel(
            id: 'g4',
            sender: 'other',
            senderName: 'Sara Kamel',
            text: 'Is anyone late today? We are moving in 5 mins.',
            time: 'Yesterday, 8:35 AM',
          ),
        ],
      ),
      ConversationModel(
        id: 'conv_support',
        name: 'Priority Support Desk',
        category: 'Support',
        lastMessage: '🎙️ Voice Message (0:14)',
        time: 'Monday',
        initials: 'SD',
        isOnline: true,
        meta: {'ticketId': '#TK-9402', 'status': 'Under Review'},
        messages: [
          ChatMessageModel(
            id: 's1',
            sender: 'user',
            senderName: 'User',
            text:
                'I faced a problem with my seat reservation. Screen locked up during payment confirmation.',
            time: 'Monday, 10:15 AM',
          ),
          ChatMessageModel(
            id: 's2',
            sender: 'other',
            senderName: 'Support Agent',
            text: 'Let me look into this transaction for you. One moment.',
            time: 'Monday, 10:20 AM',
          ),
          ChatMessageModel(
            id: 's3',
            sender: 'other',
            senderName: 'Support Agent',
            text:
                'I have attached the invoice of your transaction. Please confirm the details.',
            time: 'Monday, 10:22 AM',
            type: 'image',
            attachmentName: 'invoice_receipt_TK9402.png',
            attachmentSize: '410 KB',
          ),
          ChatMessageModel(
            id: 's4',
            sender: 'other',
            senderName: 'Support Agent',
            text: 'Audio message from agent',
            time: 'Monday, 10:23 AM',
            type: 'voice',
            duration: '0:14',
          ),
        ],
      ),
      ConversationModel(
        id: 'conv_driver_khaled',
        name: 'Captain Khaled Zaki',
        category: 'Driver',
        lastMessage: 'Sent a photo',
        time: '2 days ago',
        initials: 'KZ',
        meta: {
          'vehicle': 'MB-09-5829 (Luxury Coach)',
          'route': 'Cairo Center ↔ Banha Express',
          'eta': 'No active trip',
          'rating': '4.8 ★',
        },
        messages: [
          ChatMessageModel(
            id: 'k1',
            sender: 'user',
            senderName: 'User',
            text:
                'Hello Captain, did you find a black notebook left in seat 4?',
            time: '2 days ago',
          ),
          ChatMessageModel(
            id: 'k2',
            sender: 'other',
            senderName: 'Captain Khaled',
            text: 'Let me double check the rear seats at the end of the line.',
            time: '2 days ago',
          ),
          ChatMessageModel(
            id: 'k3',
            sender: 'other',
            senderName: 'Captain Khaled',
            text:
                'Yes! I found it. I left it at the Banha Station lost & found office.',
            time: '2 days ago',
            type: 'image',
            attachmentName: 'lost_notebook_photo.jpg',
            attachmentSize: '890 KB',
          ),
        ],
      ),
    ];
  }
}
