import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/communication/domain/entities/conversation.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/client/features/communication/presentation/cubit/communication_state.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen>
    with TickerProviderStateMixin {
  // Views:
  // 1 = Conversations List
  // 2 = Support Chat Screen
  // 3 = Driver Chat Screen
  // 4 = Group Chat Screen
  // 5 = Calling Screen (Outgoing)
  // 6 = Incoming Call Screen
  // 7 = Active Call Screen
  int _currentView = 1;

  CommunicationLoaded? _communication;

  Conversation? get _activeConversation => _communication?.activeConversation;

  List<Conversation> get _conversations =>
      _communication?.conversations ?? const [];

  // Search input
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Message input
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Active call details
  String _callName = '';
  String _callRole = '';
  String _callInitials = '';
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  // Reserved for a future realtime "agent typing" indicator (no simulation).
  final bool _isTyping = false;
  String _selectedFilter = 'All'; // 'All', 'Support', 'Drivers', 'Groups'

  // Voice message simulation states
  bool _voiceIsPlaying = false;
  double _voicePlayProgress = 0.0;
  Timer? _voiceTimer;

  // Animation controller for pulsing calling waves
  late AnimationController _pulseController;

  // Missed call notifications stack
  final List<String> _notifications = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    context.read<CommunicationCubit>().load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _callTimer?.cancel();
    _voiceTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS ---

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onBackPress() {
    if (_currentView > 1 && _currentView < 5) {
      setState(() => _currentView = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _selectConversation(Conversation conv) {
    context.read<CommunicationCubit>().selectConversation(conv);
    setState(() {
      if (conv.category == 'Support') {
        _currentView = 2;
      } else if (conv.category == 'Driver') {
        _currentView = 3;
      } else {
        _currentView = 4;
      }
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeConversation == null) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final newMessage = ChatMessage(
      id: 'msg_${math.Random().nextInt(10000)}',
      sender: 'client',
      senderName: 'You',
      text: text,
      time: timeStr,
    );

    setState(() {
      _messageController.clear();
    });
    context.read<CommunicationCubit>().addMessage(newMessage);

    _scrollToBottom();
  }

  // Voice message simulation playback
  void _toggleVoiceMessage() {
    if (_voiceIsPlaying) {
      _voiceTimer?.cancel();
      setState(() {
        _voiceIsPlaying = false;
      });
    } else {
      setState(() {
        _voiceIsPlaying = true;
        _voicePlayProgress = 0.0;
      });

      _voiceTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _voicePlayProgress += 0.05;
          if (_voicePlayProgress >= 1.0) {
            _voicePlayProgress = 0.0;
            _voiceIsPlaying = false;
            timer.cancel();
          }
        });
      });
    }
  }

  // Call simulation triggers
  void _startOutgoingCall(String name, String role, String initials) {
    setState(() {
      _callName = name;
      _callRole = role;
      _callInitials = initials;
      _currentView = 5;
    });

    // Simulate answer after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!mounted || _currentView != 5) return;
      _acceptIncomingCall();
    });
  }

  void _triggerIncomingCallSimulation() {
    // Pick first driver
    final driver = _conversations.firstWhere((c) => c.category == 'Driver');
    setState(() {
      _callName = driver.name;
      _callRole = 'Shuttle Driver • Active Trip';
      _callInitials = driver.initials;
      _currentView = 6; // Incoming Call view
    });
  }

  void _acceptIncomingCall() {
    _callTimer?.cancel();
    setState(() {
      _callDurationSeconds = 0;
      _currentView = 7; // Active Call
    });

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  void _declineCall(bool simulateMissed) {
    _callTimer?.cancel();
    setState(() {
      _currentView = 1;
    });

    if (simulateMissed) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

      final missedCallMessage = ChatMessage(
        id: 'msg_${math.Random().nextInt(10000)}',
        sender: 'other',
        senderName: _callName,
        text: '📞 Missed Call',
        time: timeStr,
      );

      // Find the corresponding conversation and append the missed call
      final idx = _conversations.indexWhere((c) => c.initials == _callInitials);
      if (idx != -1) {
        context.read<CommunicationCubit>().addMessage(
          missedCallMessage,
          conversationId: _conversations[idx].id,
        );
        context.read<CommunicationCubit>().incrementUnread(_callInitials);
        setState(() {
          _notifications.insert(0, 'Missed call from $_callName');
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Missed call from $_callName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _hangUpCall() {
    _callTimer?.cancel();
    setState(() {
      _currentView = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call ended'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- SCREEN RENDERS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) {
        if (state is CommunicationLoading) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CommunicationError) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            body: EmptyState(
              title: 'Messages unavailable',
              subtitle: state.message,
            ),
          );
        }

        _communication = state as CommunicationLoaded;

        // Use full-screen layout for calls, standard scaffold for chats
        if (_currentView >= 5) {
          return _buildCallViews(scheme);
        }

        return Scaffold(
          backgroundColor: scheme.surfaceContainerHighest,
          appBar: _buildAppBar(scheme),
          body: SafeArea(
            child: Column(
              children: [
                // Alert banner if there are missed calls
                if (_notifications.isNotEmpty) _buildNotificationAlerts(scheme),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildCurrentView(scheme),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBar(ColorScheme scheme) {
    if (_currentView == 1) {
      return AppBar(
        title: const Text(
          'Chat Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<CommunicationCubit>().load(),
          ),
          IconButton(
            icon: const Icon(
              Icons.ring_volume_rounded,
              color: Colors.greenAccent,
            ),
            tooltip: 'Simulate Incoming Call',
            onPressed: _triggerIncomingCallSimulation,
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      );
    }

    // Detail screens appbar
    if (_activeConversation == null) return null;
    final name = _activeConversation!.name;
    final initials = _activeConversation!.initials;
    final isOnline = _activeConversation!.isOnline;

    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: _onBackPress,
      ),
      title: Row(
        children: [
          Stack(
            children: [
              AppAvatar(initials: initials, radius: 18),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_activeConversation!.category == 'Driver') ...[
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () => _startOutgoingCall(
              _activeConversation!.name,
              'Shuttle Driver',
              _activeConversation!.initials,
            ),
          ),
        ],
        const SizedBox(width: 8),
      ],
      elevation: 1,
    );
  }

  Widget _buildNotificationAlerts(ColorScheme scheme) {
    return Container(
      color: Colors.redAccent.withAlpha(25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.phone_missed_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _notifications.first,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            onPressed: () {
              setState(() {
                _notifications.removeAt(0);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(ColorScheme scheme) {
    return switch (_currentView) {
      1 => _buildConversationsList(scheme),
      2 => _buildSupportChat(scheme),
      3 => _buildDriverChat(scheme),
      4 => _buildGroupChat(scheme),
      _ => const SizedBox.shrink(),
    };
  }

  // --- SCREEN 1: CONVERSATIONS LIST ---
  Widget _buildConversationsList(ColorScheme scheme) {
    // Filter list
    final filtered = _conversations.where((c) {
      final matchesSearch =
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      return switch (_selectedFilter) {
        'Drivers' => c.category == 'Driver',
        'Support' => c.category == 'Support',
        'Groups' => c.category == 'Group',
        'All' || _ => true,
      };
    }).toList();

    return Column(
      key: const ValueKey('view1'),
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search chats, contacts, messages...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
            ),
          ),
        ),

        // Filter chips row
        _buildFilterChips(scheme),

        // Chats list
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  title: 'No conversations found',
                  subtitle: 'Filter or search in your active shuttle runs.',
                  emoji: '💬',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const AppSeparator(),
                  itemBuilder: (context, idx) {
                    final chat = filtered[idx];
                    return _buildConversationItem(chat, scheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme scheme) {
    final filters = ['All', 'Drivers', 'Support', 'Groups'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSel = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              selected: isSel,
              selectedColor: scheme.primary,
              backgroundColor: scheme.surface,
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConversationItem(Conversation chat, ColorScheme scheme) {
    final isMissed = chat.lastMessage.contains('📞 Missed Call');
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectConversation(chat),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  // Avatar with online status
                  Stack(
                    children: [
                      AppAvatar(initials: chat.initials, radius: 24),
                      if (chat.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Content details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                chat.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              chat.time,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  chat.category,
                                  scheme,
                                ).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                chat.category,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _getCategoryColor(
                                    chat.category,
                                    scheme,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                chat.lastMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: chat.unreadCount > 0
                                      ? scheme.onSurface
                                      : Colors.grey,
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMissed) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.phone_missed_rounded,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Unread count
                  if (chat.unreadCount > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${chat.unreadCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat, ColorScheme scheme) {
    return switch (cat) {
      'Driver' => scheme.secondary,
      'Support' => scheme.error,
      'Group' => Colors.teal,
      _ => Colors.grey,
    };
  }

  // --- SCREEN 2: SUPPORT CHAT ---
  Widget _buildSupportChat(ColorScheme scheme) {
    if (_activeConversation == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('view2'),
      children: [
        // Ticket ID Status Bar
        _buildSupportSubHeader(scheme),

        // Chat message area
        Expanded(child: _buildMessagesList(scheme)),

        // Typing indicator
        if (_isTyping) _buildTypingIndicator(scheme),

        // Chat input field
        _buildChatInputField(scheme),
      ],
    );
  }

  Widget _buildSupportSubHeader(ColorScheme scheme) {
    final ticketId = _activeConversation!.meta?['ticketId'] ?? '#TK-XXXX';
    final status = _activeConversation!.meta?['status'] ?? 'Open';
    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'Support Ticket Reference: $ticketId',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: DRIVER CHAT ---
  Widget _buildDriverChat(ColorScheme scheme) {
    if (_activeConversation == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('view3'),
      children: [
        // Trip details mini card
        _buildDriverTripBanner(scheme),

        // Messages
        Expanded(child: _buildMessagesList(scheme)),

        // Typing indicator
        if (_isTyping) _buildTypingIndicator(scheme),

        // Chat input field
        _buildChatInputField(scheme),
      ],
    );
  }

  Widget _buildDriverTripBanner(ColorScheme scheme) {
    final meta = _activeConversation!.meta ?? {};
    final route = meta['route'] ?? 'Banha → Smart Village';
    final vehicle = meta['vehicle'] ?? 'Comfort Van';
    final eta = meta['eta'] ?? '8 mins';
    final rating = meta['rating'] ?? '4.9 ★';

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: scheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$vehicle • $rating',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  eta,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: scheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Quick actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDriverQuickActionChip('📞 Call', () {
                _startOutgoingCall(
                  _activeConversation!.name,
                  'Shuttle Driver',
                  _activeConversation!.initials,
                );
              }, scheme),
              _buildDriverQuickActionChip('📍 Share Location', () {
                context.read<CommunicationCubit>().addMessage(
                  ChatMessage(
                    id: 'd_loc',
                    sender: 'client',
                    senderName: 'You',
                    text: '📍 Shared Live Location',
                    time: 'Just now',
                  ),
                );
                _scrollToBottom();
              }, scheme),
              _buildDriverQuickActionChip('⏰ Late 5m', () {
                context.read<CommunicationCubit>().addMessage(
                  ChatMessage(
                    id: 'd_late',
                    sender: 'client',
                    senderName: 'You',
                    text: 'I will be late by 5 minutes, please hold for me.',
                    time: 'Just now',
                  ),
                );
                _scrollToBottom();
              }, scheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverQuickActionChip(
    String label,
    VoidCallback onTap,
    ColorScheme scheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline.withAlpha(50)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- SCREEN 4: GROUP CHAT ---
  Widget _buildGroupChat(ColorScheme scheme) {
    if (_activeConversation == null) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('view4'),
      children: [
        // Group Members & Details Card
        _buildGroupDetailsHeader(scheme),

        // Message timeline
        Expanded(child: _buildMessagesList(scheme)),

        // Typing indicator
        if (_isTyping) _buildTypingIndicator(scheme),

        // Chat input field
        _buildChatInputField(scheme),
      ],
    );
  }

  Widget _buildGroupDetailsHeader(ColorScheme scheme) {
    final meta = _activeConversation!.meta ?? {};
    final route = meta['route'] ?? 'Route Info';
    final count = meta['membersCount'] ?? '10 members';
    final shuttle = meta['shuttle'] ?? '';

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count • $shuttle',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const Icon(
                Icons.people_alt_rounded,
                size: 20,
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scrolling list of conversation avatars.
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSmallAvatarCircle('AM', scheme),
                _buildSmallAvatarCircle('SK', scheme),
                _buildSmallAvatarCircle('HR', scheme),
                _buildSmallAvatarCircle('KA', scheme),
                _buildSmallAvatarCircle('MZ', scheme),
                _buildSmallAvatarCircle('YA', scheme),
                _buildSmallAvatarCircle('LF', scheme),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.outline.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '+8',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatarCircle(String initials, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: AppAvatar(initials: initials, radius: 15),
    );
  }

  // --- COMMON CHAT WIDGETS ---

  Widget _buildMessagesList(ColorScheme scheme) {
    final messages = _activeConversation!.messages;
    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, idx) {
        final msg = messages[idx];
        final isUser = msg.sender == 'user' || msg.sender == 'client';
        return _buildMessageItem(msg, isUser, scheme);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isUser, ColorScheme scheme) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name (only for other speakers in Group Chat)
            if (!isUser && _activeConversation!.category == 'Group') ...[
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Content depending on message type
            _buildMessageContent(msg, isUser, scheme),

            const SizedBox(height: 6),
            // Timestamp and read receipt
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.time,
                  style: TextStyle(
                    fontSize: 8,
                    color: isUser ? Colors.white.withAlpha(160) : Colors.grey,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 11,
                    color: msg.isRead ? Colors.blueAccent : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    ChatMessage msg,
    bool isUser,
    ColorScheme scheme,
  ) {
    if (msg.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.surfaceContainerHighest,
                    scheme.outline.withAlpha(80),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.image_rounded,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black.withAlpha(150),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg.attachmentName ?? 'image.png',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isUser ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
          Text(
            msg.attachmentSize ?? '0 KB',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      );
    }

    if (msg.type == 'voice') {
      return Row(
        children: [
          GestureDetector(
            onTap: _toggleVoiceMessage,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: isUser
                  ? scheme.onPrimary.withAlpha(40)
                  : scheme.primary.withAlpha(30),
              child: Icon(
                _voiceIsPlaying ? Icons.pause : Icons.play_arrow,
                color: isUser ? scheme.onPrimary : scheme.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom wave rendering
                Row(
                  children: List.generate(15, (index) {
                    final height = 4 + (math.Random(index).nextDouble() * 16);
                    // Determine if wave segment is played or pending
                    final isPlayed =
                        _voiceIsPlaying && (index / 15.0) < _voicePlayProgress;
                    return Container(
                      width: 3,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isPlayed
                            ? (isUser ? Colors.blueAccent : scheme.primary)
                            : (isUser
                                  ? Colors.white.withAlpha(80)
                                  : Colors.grey.withAlpha(80)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _voiceIsPlaying
                      ? _formatDuration(
                          (double.parse(msg.duration!.split(':').last) *
                                  _voicePlayProgress)
                              .toInt(),
                        )
                      : msg.duration ?? '0:00',
                  style: TextStyle(
                    fontSize: 9,
                    color: isUser ? Colors.white.withAlpha(160) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Default text message
    return Text(
      msg.text,
      style: TextStyle(
        fontSize: 12,
        color: isUser ? scheme.onPrimary : scheme.onSurface,
        height: 1.35,
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme scheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.zero,
          ),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BouncingDot(),
            const SizedBox(width: 4),
            const _BouncingDot(delayMs: 200),
            const SizedBox(width: 4),
            const _BouncingDot(delayMs: 400),
            const SizedBox(width: 8),
            Text(
              '${_activeConversation!.name.split(' ').first} is typing...',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputField(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(60))),
      ),
      child: Row(
        children: [
          // Attachment simulator
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: Colors.grey),
            onPressed: () {
              // Simulate uploading image
              context.read<CommunicationCubit>().addMessage(
                ChatMessage(
                  id: 'sim_att',
                  sender: 'user',
                  senderName: 'User',
                  text: 'Attached image',
                  time: 'Just now',
                  type: 'image',
                  attachmentName: 'screenshot_evidence.jpg',
                  attachmentSize: '290 KB',
                ),
              );
              _scrollToBottom();
            },
          ),

          // Voice Message Simulator
          IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: Colors.grey),
            onPressed: () {
              // Simulate voice message send
              context.read<CommunicationCubit>().addMessage(
                ChatMessage(
                  id: 'sim_voice',
                  sender: 'user',
                  senderName: 'User',
                  text: '🎙️ Voice Message',
                  time: 'Just now',
                  type: 'voice',
                  duration: '0:08',
                ),
              );
              _scrollToBottom();
            },
          ),

          // Message input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                fillColor: scheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 5, 6, 7: CALL UI SCREENS ---
  Widget _buildCallViews(ColorScheme scheme) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Premium dark blue-slate background
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glowing pulsing circles
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: List.generate(3, (index) {
                      final val =
                          (_pulseController.value + (index * 0.33)) % 1.0;
                      return Container(
                        width: 140 + (val * 240),
                        height: 140 + (val * 240),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withAlpha(
                            (255 * (1.0 - val) * 0.15).toInt(),
                          ),
                          border: Border.all(
                            color: scheme.primary.withAlpha(
                              (255 * (1.0 - val) * 0.3).toInt(),
                            ),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Call Main Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Caller Profile
                  AppAvatar(initials: _callInitials, radius: 46),
                  const SizedBox(height: 24),

                  Text(
                    _callName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _callRole,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    _currentView == 5
                        ? 'Ringing...'
                        : _currentView == 6
                        ? 'Incoming Shuttle Call...'
                        : _formatDuration(_callDurationSeconds),
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentView == 6
                          ? Colors.greenAccent
                          : Colors.white.withAlpha(180),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // Bottom action buttons
                  _buildCallControlPanel(scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlPanel(ColorScheme scheme) {
    if (_currentView == 6) {
      // Incoming call: Decline (Red) or Accept (Green)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCallActionButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent,
            label: 'Decline',
            onTap: () => _declineCall(true), // Registers missed call
          ),
          _buildCallActionButton(
            icon: Icons.call_rounded,
            color: Colors.greenAccent,
            label: 'Accept',
            onTap: _acceptIncomingCall,
          ),
        ],
      );
    }

    // Outgoing or Active call: Mute, Speaker, Hangup
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToggleCallButton(Icons.mic_off_rounded, 'Mute'),
            _buildToggleCallButton(Icons.volume_up_rounded, 'Speaker'),
          ],
        ),
        const SizedBox(height: 40),
        _buildCallActionButton(
          icon: Icons.call_end_rounded,
          color: Colors.redAccent,
          label: 'Hang Up',
          onTap: _hangUpCall,
        ),
      ],
    );
  }

  Widget _buildToggleCallButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withAlpha(30),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Bouncing dot typing indicator animation widget
class _BouncingDot extends StatefulWidget {
  final int delayMs;

  const _BouncingDot({this.delayMs = 0});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
