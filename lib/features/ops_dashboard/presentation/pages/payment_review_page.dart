import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';

class _ManualPaymentItem {
  final String id;
  final String customerName;
  final String bookingNumber;
  final String paymentMethod;
  final String amount;
  final String receiptLabel;
  final DateTime createdAt;
  String status;

  _ManualPaymentItem({
    required this.id,
    required this.customerName,
    required this.bookingNumber,
    required this.paymentMethod,
    required this.amount,
    required this.receiptLabel,
    required this.createdAt,
    required this.status,
  });
}

String _arabicDigits(Object value) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var text = value.toString();
  for (var i = 0; i < western.length; i++) {
    text = text.replaceAll(western[i], arabic[i]);
  }
  return text;
}

String _displayNumber(String value) {
  final digits = value.replaceAll(RegExp('[^0-9]'), '');
  return _arabicDigits(digits);
}

class PaymentReviewPage extends StatefulWidget {
  final bool showBackButton;

  const PaymentReviewPage({this.showBackButton = true, super.key});

  @override
  State<PaymentReviewPage> createState() => _PaymentReviewPageState();
}

class _PaymentReviewPageState extends State<PaymentReviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _tabs = const ['قيد المراجعة', 'مقبول', 'مرفوض'];

  final List<_ManualPaymentItem> _payments = [
    _ManualPaymentItem(
      id: 'PAY-1001',
      customerName: 'سارة أحمد',
      bookingNumber: 'BK-9872',
      paymentMethod: 'إنستا باي',
      amount: '١٢٠ ج.م',
      receiptLabel: 'إيصال تحويل',
      createdAt: DateTime(2026, 6, 5, 10, 12),
      status: 'قيد المراجعة',
    ),
    _ManualPaymentItem(
      id: 'PAY-1002',
      customerName: 'خالد محمود',
      bookingNumber: 'BK-9873',
      paymentMethod: 'فودافون كاش',
      amount: '٢٤٠ ج.م',
      receiptLabel: 'صورة محفظة',
      createdAt: DateTime(2026, 6, 5, 10, 20),
      status: 'قيد المراجعة',
    ),
    _ManualPaymentItem(
      id: 'PAY-1003',
      customerName: 'عمر فاروق',
      bookingNumber: 'BK-9875',
      paymentMethod: 'تحويل بنكي',
      amount: '١٢٠ ج.م',
      receiptLabel: 'إيصال بنك',
      createdAt: DateTime(2026, 6, 5, 9, 48),
      status: 'قيد المراجعة',
    ),
    _ManualPaymentItem(
      id: 'PAY-1004',
      customerName: 'ياسمين علي',
      bookingNumber: 'BK-9876',
      paymentMethod: 'إنستا باي',
      amount: '١٥٠ ج.م',
      receiptLabel: 'لقطة شاشة',
      createdAt: DateTime(2026, 6, 4, 17, 35),
      status: 'مقبول',
    ),
    _ManualPaymentItem(
      id: 'PAY-1005',
      customerName: 'رنا يوسف',
      bookingNumber: 'BK-9874',
      paymentMethod: 'فودافون كاش',
      amount: '١٢٠ ج.م',
      receiptLabel: 'صورة غير واضحة',
      createdAt: DateTime(2026, 6, 4, 13, 5),
      status: 'مرفوض',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_ManualPaymentItem> _paymentsFor(String status) {
    return _payments.where((payment) => payment.status == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'قيد المراجعة':
        return Colors.orange.shade300;
      case 'مقبول':
        return Colors.green.shade400;
      case 'مرفوض':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _formatDate(DateTime date) {
    final day = _arabicDigits(date.day.toString().padLeft(2, '0'));
    final month = _arabicDigits(date.month.toString().padLeft(2, '0'));
    final hour = _arabicDigits(date.hour.toString().padLeft(2, '0'));
    final minute = _arabicDigits(date.minute.toString().padLeft(2, '0'));
    return '$day/$month - $hour:$minute';
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

  void _acceptPayment(_ManualPaymentItem payment) {
    setState(() {
      payment.status = 'مقبول';
      _tabController.index = 1;
    });
    _showActionToast(
      'تم قبول الدفع للحجز ${_displayNumber(payment.bookingNumber)}',
    );
  }

  void _rejectPayment(_ManualPaymentItem payment) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('رفض الدفع ${_displayNumber(payment.id)}'),
            content: const Text('سيتم نقل الدفع إلى تبويب مرفوض.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  setState(() {
                    payment.status = 'مرفوض';
                    _tabController.index = 2;
                  });
                  Navigator.pop(context);
                  _showActionToast('تم رفض الدفع');
                },
                child: const Text('رفض'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReceipt(_ManualPaymentItem payment) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'صورة الإيصال ${_displayNumber(payment.bookingNumber)}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.34,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.14),
                      ),
                    ),
                    child: _ReceiptArtwork(
                      label: payment.receiptLabel,
                      amount: payment.amount,
                      large: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                _DialogInfoRow(
                  label: 'اسم العميل',
                  value: payment.customerName,
                ),
                _DialogInfoRow(
                  label: 'رقم الحجز',
                  value: _displayNumber(payment.bookingNumber),
                ),
                _DialogInfoRow(
                  label: 'طريقة الدفع',
                  value: payment.paymentMethod,
                ),
                _DialogInfoRow(label: 'المبلغ', value: payment.amount),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراجعة المدفوعات'),
          centerTitle: true,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((status) {
              final count = _paymentsFor(status).length;
              return Tab(text: '$status (${_arabicDigits(count)})');
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((status) {
            final payments = _paymentsFor(status);
            return _PaymentStatusList(
              payments: payments,
              statusColor: _statusColor(status),
              formatDate: _formatDate,
              onAccept: _acceptPayment,
              onReject: _rejectPayment,
              onViewReceipt: _showReceipt,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PaymentStatusList extends StatelessWidget {
  final List<_ManualPaymentItem> payments;
  final Color statusColor;
  final String Function(DateTime date) formatDate;
  final void Function(_ManualPaymentItem payment) onAccept;
  final void Function(_ManualPaymentItem payment) onReject;
  final void Function(_ManualPaymentItem payment) onViewReceipt;

  const _PaymentStatusList({
    required this.payments,
    required this.statusColor,
    required this.formatDate,
    required this.onAccept,
    required this.onReject,
    required this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (payments.isEmpty) {
      return Center(
        child: Text(
          'لا توجد مدفوعات في هذا التبويب',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.xLarge : AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          itemCount: payments.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.medium),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _PaymentCard(
              payment: payment,
              statusColor: statusColor,
              createdAtText: formatDate(payment.createdAt),
              onAccept: payment.status == 'مقبول'
                  ? null
                  : () => onAccept(payment),
              onReject: payment.status == 'مرفوض'
                  ? null
                  : () => onReject(payment),
              onViewReceipt: () => onViewReceipt(payment),
            );
          },
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final _ManualPaymentItem payment;
  final Color statusColor;
  final String createdAtText;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback onViewReceipt;

  const _PaymentCard({
    required this.payment,
    required this.statusColor,
    required this.createdAtText,
    required this.onAccept,
    required this.onReject,
    required this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: AppTokens.cardElevation,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 680;

            final receipt = _ReceiptThumbnail(
              label: payment.receiptLabel,
              amount: payment.amount,
              onTap: onViewReceipt,
            );

            final details = _PaymentDetails(
              payment: payment,
              statusColor: statusColor,
              createdAtText: createdAtText,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      receipt,
                      const SizedBox(height: AppSpacing.medium),
                      details,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      receipt,
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: details),
                    ],
                  ),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    _PaymentActionButton(
                      label: 'قبول',
                      icon: Icons.check_rounded,
                      onPressed: onAccept,
                      isPrimary: true,
                    ),
                    _PaymentActionButton(
                      label: 'رفض',
                      icon: Icons.close_rounded,
                      onPressed: onReject,
                      isDestructive: true,
                    ),
                    _PaymentActionButton(
                      label: 'عرض الصورة',
                      icon: Icons.image_rounded,
                      onPressed: onViewReceipt,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final _ManualPaymentItem payment;
  final Color statusColor;
  final String createdAtText;

  const _PaymentDetails({
    required this.payment,
    required this.statusColor,
    required this.createdAtText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                payment.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            StatusChip(label: payment.status, color: statusColor),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'تاريخ الإرسال: $createdAtText',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _PaymentFact(
              icon: Icons.person_rounded,
              label: 'اسم العميل',
              value: payment.customerName,
            ),
            _PaymentFact(
              icon: Icons.confirmation_number_rounded,
              label: 'رقم الحجز',
              value: _displayNumber(payment.bookingNumber),
            ),
            _PaymentFact(
              icon: Icons.account_balance_wallet_rounded,
              label: 'طريقة الدفع',
              value: payment.paymentMethod,
            ),
            _PaymentFact(
              icon: Icons.payments_rounded,
              label: 'المبلغ',
              value: payment.amount,
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptThumbnail extends StatelessWidget {
  final String label;
  final String amount;
  final VoidCallback onTap;

  const _ReceiptThumbnail({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: Container(
        width: 112,
        height: 132,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        ),
        child: _ReceiptArtwork(label: label, amount: amount),
      ),
    );
  }
}

class _ReceiptArtwork extends StatelessWidget {
  final String label;
  final String amount;
  final bool large;

  const _ReceiptArtwork({
    required this.label,
    required this.amount,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.onSurface.withValues(alpha: 0.18);

    return Padding(
      padding: EdgeInsets.all(large ? AppSpacing.large : AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: large ? 42 : 28,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: scheme.primary,
              size: large ? 28 : 18,
            ),
          ),
          SizedBox(height: large ? AppSpacing.medium : AppSpacing.small),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: large ? 15 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: large ? AppSpacing.medium : AppSpacing.small),
          Container(height: 7, decoration: _lineDecoration(lineColor)),
          const SizedBox(height: 6),
          Container(height: 7, decoration: _lineDecoration(lineColor)),
          const SizedBox(height: 6),
          Container(
            width: large ? 160 : 70,
            height: 7,
            decoration: _lineDecoration(lineColor),
          ),
          const Spacer(),
          Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.primary,
              fontSize: large ? 18 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _lineDecoration(Color color) {
    return BoxDecoration(color: color, borderRadius: BorderRadius.circular(99));
  }
}

class _PaymentFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PaymentFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.56),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PaymentActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _PaymentActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: color,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.32),
        side: BorderSide(
          color: onPressed == null
              ? scheme.outline.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.38),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
    );
  }
}
