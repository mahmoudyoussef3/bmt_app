import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';

class _BookingItem {
  final String id;
  final String customerName;
  final String customerPhone;
  final String tripId;
  final String route;
  final String departureTime;
  final String seats;
  String paymentStatus; // مؤكد, معلق, ملغي
  final String amount;
  final String dateType; // today, tomorrow, week

  _BookingItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.tripId,
    required this.route,
    required this.departureTime,
    required this.seats,
    required this.paymentStatus,
    required this.amount,
    required this.dateType,
  });
}

class BookingManagementPage extends StatefulWidget {
  final bool showBackButton;

  const BookingManagementPage({this.showBackButton = true, super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, today, tomorrow, week

  // Realistic mock data
  final List<_BookingItem> _bookings = [
    _BookingItem(
      id: 'BK-9872',
      customerName: 'سارة أحمد',
      customerPhone: '01012345678',
      tripId: 'TR-224',
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      seats: 'مقعد 5',
      paymentStatus: 'مؤكد',
      amount: '١٢٠ ج.م',
      dateType: 'today',
    ),
    _BookingItem(
      id: 'BK-9873',
      customerName: 'خالد محمود',
      customerPhone: '01234567890',
      tripId: 'TR-221',
      route: 'بنها ← مدينة نصر',
      departureTime: '08:45 ص',
      seats: 'مقعد 12، 13',
      paymentStatus: 'معلق',
      amount: '٢٤٠ ج.م',
      dateType: 'today',
    ),
    _BookingItem(
      id: 'BK-9874',
      customerName: 'رنا يوسف',
      customerPhone: '01122334455',
      tripId: 'TR-223',
      route: 'بنها ← المهندسين',
      departureTime: '09:00 ص',
      seats: 'مقعد 4',
      paymentStatus: 'ملغي',
      amount: '١٢٠ ج.م',
      dateType: 'today',
    ),
    _BookingItem(
      id: 'BK-9875',
      customerName: 'عمر فاروق',
      customerPhone: '01555667788',
      tripId: 'TR-224',
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      seats: 'مقعد 8',
      paymentStatus: 'مؤكد',
      amount: '١٢٠ ج.م',
      dateType: 'tomorrow',
    ),
    _BookingItem(
      id: 'BK-9876',
      customerName: 'ياسمين علي',
      customerPhone: '01009876543',
      tripId: 'TR-228',
      route: 'بنها ← التجمع الخامس',
      departureTime: '09:30 ص',
      seats: 'مقعد 1',
      paymentStatus: 'معلق',
      amount: '١٥٠ ج.م',
      dateType: 'tomorrow',
    ),
    _BookingItem(
      id: 'BK-9877',
      customerName: 'مصطفى حسين',
      customerPhone: '01201122334',
      tripId: 'TR-221',
      route: 'بنها ← مدينة نصر',
      departureTime: '08:45 ص',
      seats: 'مقعد 6',
      paymentStatus: 'مؤكد',
      amount: '١٢٠ ج.م',
      dateType: 'week',
    ),
    _BookingItem(
      id: 'BK-9878',
      customerName: 'طارق محمد',
      customerPhone: '01199887766',
      tripId: 'TR-223',
      route: 'بنها ← المهندسين',
      departureTime: '09:00 ص',
      seats: 'مقعد 9، 10',
      paymentStatus: 'مؤكد',
      amount: '٢٤٠ ج.م',
      dateType: 'week',
    ),
    _BookingItem(
      id: 'BK-9879',
      customerName: 'منى شريف',
      customerPhone: '01054321098',
      tripId: 'TR-224',
      route: 'بنها ← القرية الذكية',
      departureTime: '08:30 ص',
      seats: 'مقعد 3',
      paymentStatus: 'ملغي',
      amount: '١٢٠ ج.م',
      dateType: 'week',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_BookingItem> get _filteredBookings {
    final query = _searchQuery.trim().toLowerCase();
    return _bookings.where((b) {
      // 1. Filter by Chip
      bool matchesChip = true;
      if (_selectedFilter == 'today') {
        matchesChip = b.dateType == 'today';
      } else if (_selectedFilter == 'tomorrow') {
        matchesChip = b.dateType == 'tomorrow';
      } else if (_selectedFilter == 'week') {
        matchesChip = b.dateType == 'today' || b.dateType == 'tomorrow' || b.dateType == 'week';
      }

      // 2. Filter by Search Query
      bool matchesQuery = true;
      if (query.isNotEmpty) {
        matchesQuery = b.id.toLowerCase().contains(query) ||
            b.customerName.toLowerCase().contains(query) ||
            b.customerPhone.contains(query);
      }

      return matchesChip && matchesQuery;
    }).toList();
  }

  void _showActionToast(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(label),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مؤكد':
        return Colors.green.shade400;
      case 'معلق':
        return Colors.orange.shade400;
      case 'ملغي':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  // Swipe Action: Edit booking status
  void _editBooking(_BookingItem booking) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل حالة الحجز ${booking.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('مؤكد'),
                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                  onTap: () {
                    setState(() => booking.paymentStatus = 'مؤكد');
                    Navigator.pop(context);
                    _showActionToast('تم تعديل حالة الحجز إلى مؤكد');
                  },
                ),
                ListTile(
                  title: const Text('معلق'),
                  leading: const Icon(Icons.pending_actions_rounded, color: Colors.orange),
                  onTap: () {
                    setState(() => booking.paymentStatus = 'معلق');
                    Navigator.pop(context);
                    _showActionToast('تم تعديل حالة الحجز إلى معلق');
                  },
                ),
                ListTile(
                  title: const Text('ملغي'),
                  leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                  onTap: () {
                    setState(() => booking.paymentStatus = 'ملغي');
                    Navigator.pop(context);
                    _showActionToast('تم تعديل حالة الحجز إلى ملغي');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Swipe Action: Cancel booking
  void _cancelBooking(_BookingItem booking) {
    setState(() {
      booking.paymentStatus = 'ملغي';
    });
    _showActionToast('تم إلغاء الحجز ${booking.id}');
  }

  // Tap Card: Details Bottom Sheet
  void _showBookingDetails(_BookingItem booking) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تفاصيل الحجز ${booking.id}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    StatusChip(
                      label: booking.paymentStatus,
                      color: _getStatusColor(booking.paymentStatus),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.large),
                _detailRow(context, Icons.person_rounded, 'اسم العميل', booking.customerName),
                _detailRow(context, Icons.phone_android_rounded, 'رقم الهاتف', booking.customerPhone),
                _detailRow(context, Icons.directions_bus_rounded, 'رحلة / مسار', '${booking.tripId} | ${booking.route}'),
                _detailRow(context, Icons.access_time_rounded, 'وقت الانطلاق', booking.departureTime),
                _detailRow(context, Icons.chair_rounded, 'المقاعد المحددة', booking.seats),
                _detailRow(context, Icons.monetization_on_rounded, 'المبلغ الإجمالي', booking.amount),
                const SizedBox(height: AppSpacing.large),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('تعديل الحجز'),
                        onPressed: () {
                          Navigator.pop(context);
                          _editBooking(booking);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.error),
                          foregroundColor: scheme.error,
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('إلغاء الحجز'),
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelBooking(booking);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.medium),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // FAB Dialog: Create New Booking
  void _createNewBookingDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final seatsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إنشاء حجز جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم العميل'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  TextField(
                    controller: seatsCtrl,
                    decoration: const InputDecoration(labelText: 'أرقام المقاعد (مثال: مقعد 3)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                    setState(() {
                      _bookings.insert(
                        0,
                        _BookingItem(
                          id: 'BK-${9880 + _bookings.length}',
                          customerName: nameCtrl.text,
                          customerPhone: phoneCtrl.text,
                          tripId: 'TR-224',
                          route: 'بنها ← القرية الذكية',
                          departureTime: '08:30 ص',
                          seats: seatsCtrl.text.isNotEmpty ? seatsCtrl.text : 'مقعد غير محدد',
                          paymentStatus: 'معلق',
                          amount: '١٢٠ ج.م',
                          dateType: 'today',
                        ),
                      );
                    });
                    Navigator.pop(context);
                    _showActionToast('تم إنشاء الحجز بنجاح');
                  } else {
                    _showActionToast('يرجى ملء الاسم ورقم الهاتف');
                  }
                },
                child: const Text('حفظ حجز'),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الحجوزات'),
          centerTitle: true,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: _createNewBookingDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('حجز جديد'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(color: scheme.outline.withOpacity(0.12)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'بحث برقم الحجز، رقم الهاتف، أو اسم العميل...',
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withOpacity(0.4),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurface.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip(label: 'جميع الحجوزات', value: 'all'),
                    const SizedBox(width: AppSpacing.small),
                    _filterChip(label: 'حجوزات اليوم', value: 'today'),
                    const SizedBox(width: AppSpacing.small),
                    _filterChip(label: 'حجوزات غداً', value: 'tomorrow'),
                    const SizedBox(width: AppSpacing.small),
                    _filterChip(label: 'حجوزات الأسبوع', value: 'week'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Booking List Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'قائمة الحجوزات (${_filteredBookings.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  Text(
                    'اسحب الحجز لليمين أو اليسار للتعديل السريع',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.45),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),

              // Dismissible List of Bookings
              Expanded(
                child: _filteredBookings.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد حجوزات تطابق البحث',
                          style: TextStyle(color: scheme.onSurface.withOpacity(0.45)),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          final b = _filteredBookings[index];
                          final statusColor = _getStatusColor(b.paymentStatus);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                            child: Dismissible(
                              key: Key(b.id + b.paymentStatus),
                              direction: DismissDirection.horizontal,
                              // Swipe right (start-to-end) triggers cancel logic
                              confirmDismiss: (dir) async {
                                if (dir == DismissDirection.startToEnd) {
                                  _cancelBooking(b);
                                } else {
                                  _editBooking(b);
                                }
                                return false; // Never dismiss completely from the screen view list, just trigger local state update
                              },
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(AppTokens.radius),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Row(
                                  children: [
                                    Icon(Icons.cancel_rounded, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'إلغاء الحجز',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade900.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(AppTokens.radius),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'تعديل الحالة',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.edit_rounded, color: Colors.white),
                                  ],
                                ),
                              ),
                              child: Card(
                                elevation: AppTokens.surfaceElevation,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTokens.radius),
                                ),
                                child: InkWell(
                                  onTap: () => _showBookingDetails(b),
                                  borderRadius: BorderRadius.circular(AppTokens.radius),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.medium),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              b.id,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: scheme.primary,
                                                fontSize: 15,
                                              ),
                                            ),
                                            StatusChip(
                                              label: b.paymentStatus,
                                              color: statusColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.small),
                                        Text(
                                          b.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xSmall),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'الرحلة: ${b.tripId}',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: scheme.secondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              b.seats,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: scheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                            Text(
                                              b.amount,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final scheme = Theme.of(context).colorScheme;
    final bool isSelected = _selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? scheme.onPrimary : scheme.onSurface,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.3),
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(color: scheme.outline.withOpacity(0.08)),
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
    );
  }
}
