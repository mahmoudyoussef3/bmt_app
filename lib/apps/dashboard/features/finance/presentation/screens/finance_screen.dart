import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/finance_entities.dart';
import '../cubit/finance_cubit.dart';
import '../cubit/finance_state.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المركز المالي وعمليات الدفع'),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: () => context.read<FinanceCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<FinanceCubit, FinanceState>(
          listenWhen: (previous, current) {
            return current is FinanceLoaded && current.actionMessage != null;
          },
          listener: (context, state) {
            if (state is FinanceLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.actionMessage!,
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              context.read<FinanceCubit>().clearActionMessage();
            }
          },
          builder: (context, state) {
            return switch (state) {
              FinanceLoading() => const Center(child: CircularProgressIndicator()),
              FinanceError(:final message) => _ErrorView(message: message),
              FinanceLoaded() => _LoadedView(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<FinanceCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final FinanceLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        children: [
          // 1. Dashboard Metrics
          _MetricsRow(metrics: state.metrics),
          const SizedBox(height: AppSpacing.medium),

          // 2. Navigation Tabs
          _TabSelector(
            selectedIndex: state.selectedSectionIndex,
            onTabSelected: (index) => context.read<FinanceCubit>().selectSection(index),
          ),
          const SizedBox(height: AppSpacing.medium),

          // 3. Tab Content
          Expanded(
            child: _buildSectionContent(state.selectedSectionIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(int index) {
    return switch (index) {
      0 => _PaymentsSection(state: state),
      1 => _ReviewQueueSection(state: state),
      2 => _RefundsSection(state: state),
      3 => _SubscriptionsSection(state: state),
      4 => _RevenueSection(state: state),
      _ => const SizedBox(),
    };
  }
}

// -------------------------------------------------------------
// METRICS ROW WIDGET
// -------------------------------------------------------------
class _MetricsRow extends StatelessWidget {
  final RevenueMetrics metrics;
  const _MetricsRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = AppSpacing.small;
        final int columns = constraints.maxWidth < 800 ? 2 : 5;

        if (columns == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _MetricCard(title: 'إيرادات اليوم', value: '${metrics.todayRevenue.toStringAsFixed(0)} ج.م', icon: Icons.today, color: const Color(0xFF10B981))),
                  SizedBox(width: spacing),
                  Expanded(child: _MetricCard(title: 'إيرادات الأسبوع', value: '${metrics.weeklyRevenue.toStringAsFixed(0)} ج.م', icon: Icons.date_range, color: Colors.blue)),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(child: _MetricCard(title: 'إيرادات الشهر', value: '${metrics.monthlyRevenue.toStringAsFixed(0)} ج.م', icon: Icons.calendar_month, color: Colors.purple)),
                  SizedBox(width: spacing),
                  Expanded(child: _MetricCard(title: 'الاشتراكات النشطة', value: '${metrics.activeSubscriptions}', icon: Icons.card_membership, color: Colors.orange)),
                ],
              ),
              SizedBox(height: spacing),
              _MetricCard(
                title: 'إجمالي إيرادات الحجوزات',
                value: '${metrics.totalBookingsRevenue.toStringAsFixed(0)} ج.م',
                icon: Icons.account_balance_wallet,
                color: Colors.teal,
                isFullWidth: true,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _MetricCard(title: 'إيرادات اليوم', value: '${metrics.todayRevenue.toStringAsFixed(0)} ج.م', icon: Icons.today, color: const Color(0xFF10B981))),
            SizedBox(width: spacing),
            Expanded(child: _MetricCard(title: 'إيرادات الأسبوع', value: '${metrics.weeklyRevenue.toStringAsFixed(0)} ج.م', icon: Icons.date_range, color: Colors.blue)),
            SizedBox(width: spacing),
            Expanded(child: _MetricCard(title: 'إيرادات الشهر', value: '${metrics.monthlyRevenue.toStringAsFixed(0)} ج.م', icon: Icons.calendar_month, color: Colors.purple)),
            SizedBox(width: spacing),
            Expanded(child: _MetricCard(title: 'الاشتراكات النشطة', value: '${metrics.activeSubscriptions}', icon: Icons.card_membership, color: Colors.orange)),
            SizedBox(width: spacing),
            Expanded(child: _MetricCard(title: 'إجمالي إيرادات الحجوزات', value: '${metrics.totalBookingsRevenue.toStringAsFixed(0)} ج.م', icon: Icons.account_balance_wallet, color: Colors.teal)),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB SELECTOR
// -------------------------------------------------------------
class _TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _TabSelector({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final tabs = [
      _TabItem(title: 'المدفوعات', icon: Icons.receipt_long, index: 0),
      _TabItem(title: 'طلبات المراجعة', icon: Icons.fact_check, index: 1),
      _TabItem(title: 'المرتجعات', icon: Icons.assignment_return, index: 2),
      _TabItem(title: 'الاشتراكات', icon: Icons.subscriptions, index: 3),
      _TabItem(title: 'الإيرادات', icon: Icons.trending_up, index: 4),
    ];

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: tabs.map((tab) {
                final isSelected = selectedIndex == tab.index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    avatar: Icon(
                      tab.icon,
                      size: 18,
                      color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                    label: Text(
                      tab.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onTabSelected(tab.index);
                      }
                    },
                    selectedColor: scheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem {
  final String title;
  final IconData icon;
  final int index;
  const _TabItem({required this.title, required this.icon, required this.index});
}

// -------------------------------------------------------------
// SECTION 1: PAYMENTS (المدفوعات)
// -------------------------------------------------------------
class _PaymentsSection extends StatelessWidget {
  final FinanceLoaded state;
  const _PaymentsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();

    // 1. Filter the list
    final filteredPayments = state.payments.where((p) {
      final matchesSearch = state.searchQuery.isEmpty ||
          p.clientName.contains(state.searchQuery) ||
          p.id.contains(state.searchQuery) ||
          p.tripCode.contains(state.searchQuery);

      final matchesMethod = state.paymentMethodFilter == null || p.paymentMethod == state.paymentMethodFilter;
      final matchesStatus = state.paymentStatusFilter == null || p.status == state.paymentStatusFilter;

      return matchesSearch && matchesMethod && matchesStatus;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 900;
        final selected = state.selectedPayment;

        Widget tableWidget = Column(
          children: [
            // Filter controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'بحث باسم العميل، رقم العملية، أو كود الرحلة...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => cubit.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: DropdownButtonFormField<FinancePaymentMethod>(
                    initialValue: state.paymentMethodFilter,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ...FinancePaymentMethod.values.map(
                        (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                      ),
                    ],
                    onChanged: (val) => cubit.setPaymentMethodFilter(val),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: DropdownButtonFormField<PaymentStatus>(
                    initialValue: state.paymentStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'الحالة',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ...PaymentStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      ),
                    ],
                    onChanged: (val) => cubit.setPaymentStatusFilter(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: AppCard(
                child: filteredPayments.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد عمليات تطابق البحث',
                        subtitle: 'يرجى مراجعة معايير التصفية والبحث.',
                      )
                    : _PaymentsTableWidget(
                        payments: filteredPayments,
                        selectedId: state.selectedPaymentId,
                        onSelect: cubit.selectPayment,
                      ),
              ),
            ),
          ],
        );

        if (!useSplit) {
          if (selected != null) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => cubit.selectPayment(null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للقائمة'),
                  ),
                ),
                Expanded(child: _PaymentDetailPanel(payment: selected)),
              ],
            );
          }
          return tableWidget;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: tableWidget),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              flex: 4,
              child: selected == null
                  ? const AppCard(
                      child: EmptyState(
                        title: 'اختر عملية لعرض تفاصيلها',
                        subtitle: 'اضغط على أي صف في الجدول لمعاينة سجل وتفاصيل العملية كاملة.',
                      ),
                    )
                  : _PaymentDetailPanel(payment: selected),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentsTableWidget extends StatelessWidget {
  final List<PaymentRecord> payments;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _PaymentsTableWidget({
    required this.payments,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: scheme.outlineVariant.withAlpha(50),
        ),
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('رقم العملية', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الرحلة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: payments.take(50).map((p) {
            final isSelected = p.id == selectedId;
            return DataRow(
              selected: isSelected,
              onSelectChanged: (_) => onSelect(isSelected ? null : p.id),
              cells: [
                DataCell(Text(p.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(p.clientName)),
                DataCell(Text(p.tripCode)),
                DataCell(Text('${p.amount.toStringAsFixed(0)} ج.م')),
                DataCell(_PaymentMethodBadge(method: p.paymentMethod)),
                DataCell(_PaymentStatusBadge(status: p.status)),
                DataCell(Text(p.date.toString().substring(0, 16))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PaymentDetailPanel extends StatelessWidget {
  final PaymentRecord payment;
  const _PaymentDetailPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined, size: 28),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'تفاصيل العملية المالية',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),
          _DetailField(label: 'رقم العملية', value: payment.id),
          _DetailField(label: 'اسم العميل', value: payment.clientName),
          _DetailField(label: 'كود الرحلة', value: payment.tripCode),
          _DetailField(label: 'مبلغ العملية', value: '${payment.amount.toStringAsFixed(2)} جنيه مصري'),
          _DetailField(label: 'طريقة الدفع المستخدمة', value: payment.paymentMethod.label),
          _DetailField(
            label: 'تاريخ وتوقيت العملية',
            value: payment.date.toString().substring(0, 19),
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('حالة العملية الحالية:', style: TextStyle(fontWeight: FontWeight.w500)),
              _PaymentStatusBadge(status: payment.status),
            ],
          ),
          const Divider(height: AppSpacing.large),
          const Text(
            'سجل عمليات الدفع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.small),
          _HistoryTimelineItem(
            time: payment.date.toString().substring(11, 16),
            title: 'إنشاء الفاتورة للعميل',
            desc: 'تم تكوين الفاتورة وطلب الدفع عبر ${payment.paymentMethod.label}.',
          ),
          _HistoryTimelineItem(
            time: payment.date.add(const Duration(minutes: 2)).toString().substring(11, 16),
            title: payment.status == PaymentStatus.success ? 'تأكيد استلام المبلغ' : 'العملية قيد المراجعة/المعالجة',
            desc: payment.status == PaymentStatus.success
                ? 'تم استلام وتأكيد المعاملة بنجاح.'
                : 'بانتظار مراجعة إيصال الدفع من موظف العمليات.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String desc;
  final bool isLast;

  const _HistoryTimelineItem({
    required this.time,
    required this.title,
    required this.desc,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: scheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(time, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.medium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  final FinancePaymentMethod method;
  const _PaymentMethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (method) {
      FinancePaymentMethod.instapay => (Colors.purple.shade50, Colors.purple.shade900),
      FinancePaymentMethod.vodafoneCash => (Colors.red.shade50, Colors.red.shade900),
      FinancePaymentMethod.cash => (Colors.amber.shade50, Colors.amber.shade900),
      FinancePaymentMethod.card => (Colors.blue.shade50, Colors.blue.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        method.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      PaymentStatus.success => (Colors.green.shade50, Colors.green.shade900),
      PaymentStatus.pending => (Colors.orange.shade50, Colors.orange.shade900),
      PaymentStatus.cancelled => (Colors.red.shade50, Colors.red.shade900),
      PaymentStatus.refunded => (Colors.grey.shade100, Colors.grey.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// -------------------------------------------------------------
// SECTION 2: REVIEW QUEUE (طلبات المراجعة)
// -------------------------------------------------------------
class _ReviewQueueSection extends StatefulWidget {
  final FinanceLoaded state;
  const _ReviewQueueSection({required this.state});

  @override
  State<_ReviewQueueSection> createState() => _ReviewQueueSectionState();
}

class _ReviewQueueSectionState extends State<_ReviewQueueSection> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();

    final pendingReviews = widget.state.receiptReviews.where((r) {
      final matchesStatus = widget.state.receiptStatusFilter == null
          ? r.status == ReceiptReviewStatus.pending
          : r.status == widget.state.receiptStatusFilter;
      return matchesStatus;
    }).toList();

    final selected = widget.state.selectedReceipt;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 950;

        Widget queueList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قائمة إيصالات الحجوزات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                DropdownButton<ReceiptReviewStatus?>(
                  value: widget.state.receiptStatusFilter ?? ReceiptReviewStatus.pending,
                  underline: const SizedBox(),
                  items: ReceiptReviewStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.label, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (status) => cubit.setReceiptStatusFilter(status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Expanded(
              child: AppCard(
                child: pendingReviews.isEmpty
                    ? const EmptyState(
                        title: 'صندوق المراجعة فارغ',
                        subtitle: 'لا توجد طلبات معلقة للمراجعة بالفلتر المحدد.',
                      )
                    : ListView.separated(
                        itemCount: pendingReviews.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = pendingReviews[index];
                          final isSelected = r.id == widget.state.selectedReceiptId;
                          return ListTile(
                            selected: isSelected,
                            onTap: () {
                              cubit.selectReceipt(r.id);
                              _notesController.clear();
                            },
                            title: Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('العملية: ${r.transactionId} | الرحلة: ${r.tripCode}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${r.amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  r.date.toString().substring(5, 16),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );

        Widget workspacePanel = selected == null
            ? const AppCard(
                child: EmptyState(
                  title: 'اختر طلب مراجعة لمعاينته',
                  subtitle: 'تظهر هنا صورة الإيصال ومطابقة البيانات وأزرار القرار (قبول / رفض / إعادة رفع).',
                ),
              )
            : _ReceiptWorkspace(
                receipt: selected,
                notesController: _notesController,
                zoom: widget.state.receiptZoom,
                rotation: widget.state.receiptRotation,
                actionLoading: widget.state.actionLoading,
                onZoomIn: () => cubit.setReceiptZoom(widget.state.receiptZoom + 0.25),
                onZoomOut: () => cubit.setReceiptZoom(widget.state.receiptZoom - 0.25),
                onRotate: () => cubit.setReceiptRotation(widget.state.receiptRotation + 90.0),
                onAccept: () {
                  cubit.reviewReceipt(selected.id, ReceiptReviewStatus.accepted, notes: _notesController.text);
                  _notesController.clear();
                },
                onReject: () {
                  cubit.reviewReceipt(selected.id, ReceiptReviewStatus.rejected, notes: _notesController.text);
                  _notesController.clear();
                },
                onRequestReupload: () {
                  cubit.reviewReceipt(selected.id, ReceiptReviewStatus.reuploadRequested, notes: _notesController.text);
                  _notesController.clear();
                },
              );

        if (!useSplit) {
          if (selected != null) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => cubit.selectReceipt(null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للطلبات'),
                  ),
                ),
                Expanded(child: workspacePanel),
              ],
            );
          }
          return queueList;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: queueList),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 7, child: workspacePanel),
          ],
        );
      },
    );
  }
}

class _ReceiptWorkspace extends StatelessWidget {
  final ReceiptReview receipt;
  final TextEditingController notesController;
  final double zoom;
  final double rotation;
  final bool actionLoading;

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRotate;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRequestReupload;

  const _ReceiptWorkspace({
    required this.receipt,
    required this.notesController,
    required this.zoom,
    required this.rotation,
    required this.actionLoading,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRotate,
    required this.onAccept,
    required this.onReject,
    required this.onRequestReupload,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب مراجعة #${receipt.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'العميل: ${receipt.clientName} | الرحلة: ${receipt.tripCode}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${receipt.amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 2),
                  _ReceiptStatusBadge(status: receipt.status),
                ],
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),

          // Main Review Split: Left/Right inside workspace
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Interactive Receipt Mockup Container
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Center(
                          child: Transform.rotate(
                            angle: rotation * pi / 180,
                            child: Transform.scale(
                              scale: zoom,
                              child: _buildReceiptVisual(context),
                            ),
                          ),
                        ),
                        // Zoom/Rotate controls
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.zoom_in), onPressed: onZoomIn, tooltip: 'تكبير'),
                                IconButton(icon: const Icon(Icons.zoom_out), onPressed: onZoomOut, tooltip: 'تصغير'),
                                IconButton(icon: const Icon(Icons.rotate_right), onPressed: onRotate, tooltip: 'تدوير'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),

                // 2. Action Desk details
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('معلومات التحويل المطالب بها:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.small),
                        _InfoRow(label: 'رقم المعاملة (المرجع)', value: receipt.transactionId),
                        _InfoRow(label: 'المبلغ المحوّل', value: '${receipt.amount.toStringAsFixed(2)} ج.م'),
                        _InfoRow(label: 'تاريخ الرفع', value: receipt.date.toString().substring(0, 16)),
                        const Divider(height: AppSpacing.large),

                        // Review Note
                        if (receipt.status == ReceiptReviewStatus.pending) ...[
                          const Text('ملاحظات المراجعة (تُرسل للعميل عند الرفض):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: AppSpacing.small),
                          TextField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'مثال: إيصال غير واضح، يرجى إعادة إرساله...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),

                          // Decision Actions
                          if (actionLoading)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            FilledButton.icon(
                              onPressed: onAccept,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(42),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('قبول وتفعيل الحجز'),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: onReject,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      minimumSize: const Size(0, 42),
                                    ),
                                    icon: const Icon(Icons.close),
                                    label: const Text('رفض العملية'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: onRequestReupload,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                      minimumSize: const Size(0, 42),
                                    ),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('طلب إعادة رفع'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('قرار المراجعة المسجل:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                _ReceiptStatusBadge(status: receipt.status),
                                if (receipt.notes != null) ...[
                                  const SizedBox(height: 8),
                                  Text('ملاحظات: ${receipt.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: AppSpacing.large),

                        // Ticket History Logs
                        const Text('سجل حركة الإيصال:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: AppSpacing.small),
                        ...receipt.history.map((log) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text('• $log', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Generates a mock visual card representing the bank receipt
  Widget _buildReceiptVisual(BuildContext context) {
    return Container(
      width: 260,
      height: 420,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('instaPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              Icon(Icons.qr_code, color: Colors.purple.shade900, size: 28),
            ],
          ),
          const SizedBox(height: 4),
          const Text('معاملة دفع ناجحة', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const Divider(height: 24),
          const SizedBox(height: 10),
          const Text('المرسل إليه:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Text('شركة باصات النقل المتميز (BMT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('المرسل:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Text(receipt.clientName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('رقم الحساب أو المحفظة:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Text('*** *** **8792', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 12),
          const Text('رقم المعاملة الفريد (RRN):', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Text(receipt.transactionId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
            child: Column(
              children: [
                const Text('القيمة المحولة:', style: TextStyle(fontSize: 10, color: Colors.purple)),
                Text('${receipt.amount.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
          ),
          const Spacer(),
          Text('تاريخ المعاملة: ${receipt.date.toString().substring(0, 16)}', style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReceiptStatusBadge extends StatelessWidget {
  final ReceiptReviewStatus status;
  const _ReceiptStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReceiptReviewStatus.pending => (Colors.orange.shade50, Colors.orange.shade900),
      ReceiptReviewStatus.accepted => (Colors.green.shade50, Colors.green.shade900),
      ReceiptReviewStatus.rejected => (Colors.red.shade50, Colors.red.shade900),
      ReceiptReviewStatus.reuploadRequested => (Colors.blue.shade50, Colors.blue.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// -------------------------------------------------------------
// SECTION 3: REFUNDS (المرتجعات)
// -------------------------------------------------------------
class _RefundsSection extends StatelessWidget {
  final FinanceLoaded state;
  const _RefundsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();

    final filteredRefunds = state.refundRequests.where((r) {
      final matchesStatus = state.refundStatusFilter == null || r.status == state.refundStatusFilter;
      return matchesStatus;
    }).toList();

    final selected = state.selectedRefund;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 900;

        Widget tableWidget = Column(
          children: [
            Row(
              children: [
                const Text('تصفية طلبات الاسترداد:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: AppSpacing.medium),
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: state.refundStatusFilter == null,
                  onSelected: (sel) => cubit.setRefundStatusFilter(null),
                ),
                const SizedBox(width: AppSpacing.small),
                ...RefundStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: ChoiceChip(
                        label: Text(s.label),
                        selected: state.refundStatusFilter == s,
                        onSelected: (sel) => cubit.setRefundStatusFilter(sel ? s : null),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: AppCard(
                child: filteredRefunds.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد طلبات مرتجع',
                        subtitle: 'لم يتم العثور على طلبات استرداد مطابقة للمعيار.',
                      )
                    : ListView.separated(
                        itemCount: filteredRefunds.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = filteredRefunds[index];
                          final isSelected = r.id == state.selectedRefundId;
                          return ListTile(
                            selected: isSelected,
                            onTap: () => cubit.selectRefund(r.id),
                            title: Text('طلب استرداد #${r.id} (${r.clientName})'),
                            subtitle: Text('العملية الأصلية: ${r.transactionId} | سبب الاسترداد: ${r.reason}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${r.amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                _RefundStatusBadge(status: r.status),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );

        Widget detailWidget = selected == null
            ? const AppCard(
                child: EmptyState(
                  title: 'اختر طلب مرتجع لمعاينته',
                  subtitle: 'اضغط على أي عنصر في القائمة لمراجعة العملية والسبب وتأكيد أو رفض الاسترداد.',
                ),
              )
            : _RefundDetailsPanel(
                refund: selected,
                actionLoading: state.actionLoading,
                onApprove: () => cubit.processRefund(selected.id, RefundStatus.approved),
                onReject: () => cubit.processRefund(selected.id, RefundStatus.rejected),
              );

        if (!useSplit) {
          if (selected != null) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => cubit.selectRefund(null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للقائمة'),
                  ),
                ),
                Expanded(child: detailWidget),
              ],
            );
          }
          return tableWidget;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: tableWidget),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 5, child: detailWidget),
          ],
        );
      },
    );
  }
}

class _RefundDetailsPanel extends StatelessWidget {
  final RefundRequest refund;
  final bool actionLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RefundDetailsPanel({
    required this.refund,
    required this.actionLoading,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_return_outlined, size: 28),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text('معالجة طلب الاسترداد #${refund.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),
          _DetailField(label: 'اسم العميل', value: refund.clientName),
          _DetailField(label: 'رقم العملية الأصلية', value: refund.transactionId),
          _DetailField(label: 'مبلغ الاسترداد المطالب به', value: '${refund.amount.toStringAsFixed(2)} جنيه مصري'),
          _DetailField(label: 'تاريخ تقديم طلب المرتجع', value: refund.date.toString().substring(0, 16)),
          _DetailField(label: 'سبب طلب الاسترداد', value: refund.reason),
          const Divider(height: AppSpacing.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('حالة طلب الاسترداد:', style: TextStyle(fontWeight: FontWeight.w500)),
              _RefundStatusBadge(status: refund.status),
            ],
          ),
          const Divider(height: AppSpacing.large),
          if (refund.status == RefundStatus.pending) ...[
            if (actionLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('الموافقة وإرجاع المبلغ'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('رفض طلب المرتجع'),
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: AppSpacing.medium),
          const Text('سجل الموافقات والحركات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: AppSpacing.small),
          ...refund.history.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('• $log', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              )),
        ],
      ),
    );
  }
}

class _RefundStatusBadge extends StatelessWidget {
  final RefundStatus status;
  const _RefundStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RefundStatus.pending => (Colors.orange.shade50, Colors.orange.shade900),
      RefundStatus.approved => (Colors.green.shade50, Colors.green.shade900),
      RefundStatus.rejected => (Colors.red.shade50, Colors.red.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// -------------------------------------------------------------
// SECTION 4: SUBSCRIPTIONS (الاشتراكات)
// -------------------------------------------------------------
class _SubscriptionsSection extends StatelessWidget {
  final FinanceLoaded state;
  const _SubscriptionsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();

    final filteredSubscriptions = state.subscriptions.where((s) {
      final matchesStatus = state.subscriptionStatusFilter == null || s.status == state.subscriptionStatusFilter;
      return matchesStatus;
    }).toList();

    final selected = state.selectedSubscription;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 900;

        Widget tableWidget = Column(
          children: [
            Row(
              children: [
                const Text('حالة الاشتراك:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: AppSpacing.medium),
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: state.subscriptionStatusFilter == null,
                  onSelected: (_) => cubit.setSubscriptionStatusFilter(null),
                ),
                const SizedBox(width: AppSpacing.small),
                ...SubscriptionStatus.values.map((s) => ChoiceChip(
                      label: Text(s.label),
                      selected: state.subscriptionStatusFilter == s,
                      onSelected: (sel) => cubit.setSubscriptionStatusFilter(sel ? s : null),
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: AppCard(
                child: filteredSubscriptions.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد اشتراكات',
                        subtitle: 'لم يتم العثور على سجلات اشتراكات مطابقة.',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
                          ),
                          child: DataTable(
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('رقم الاشتراك', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('باقة الاشتراك', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الرحلات المتبقية', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('تاريخ الانتهاء', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredSubscriptions.take(40).map((s) {
                              final isSelected = s.id == state.selectedSubscriptionId;
                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: (_) => cubit.selectSubscription(s.id),
                                cells: [
                                  DataCell(Text(s.id, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  DataCell(Text(s.clientName)),
                                  DataCell(Text(s.packageName)),
                                  DataCell(Text('${s.amount.toStringAsFixed(0)} ج.م')),
                                  DataCell(Text(s.status == SubscriptionStatus.active ? '${s.remainingRides} رحلات' : '0')),
                                  DataCell(Text(s.endDate.toString().substring(0, 10))),
                                  DataCell(_SubscriptionStatusBadge(status: s.status)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );

        Widget detailWidget = selected == null
            ? const AppCard(
                child: EmptyState(
                  title: 'اختر اشتراك لعرض التفاصيل والإدارة',
                  subtitle: 'اضغط على أي اشتراك في الجدول لتفعيله أو إلغائه فورياً.',
                ),
              )
            : _SubscriptionDetailPanel(
                subscription: selected,
                actionLoading: state.actionLoading,
                onCancel: () => cubit.cancelSubscription(selected.id),
              );

        if (!useSplit) {
          if (selected != null) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => cubit.selectSubscription(null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للاشتراكات'),
                  ),
                ),
                Expanded(child: detailWidget),
              ],
            );
          }
          return tableWidget;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: tableWidget),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 4, child: detailWidget),
          ],
        );
      },
    );
  }
}

class _SubscriptionDetailPanel extends StatelessWidget {
  final SubscriptionRecord subscription;
  final bool actionLoading;
  final VoidCallback onCancel;

  const _SubscriptionDetailPanel({
    required this.subscription,
    required this.actionLoading,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_membership_outlined, size: 28),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text('إدارة حزمة الاشتراك', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const Divider(height: AppSpacing.large),
          _DetailField(label: 'رقم الاشتراك الفريد', value: subscription.id),
          _DetailField(label: 'اسم المشترك', value: subscription.clientName),
          _DetailField(label: 'باقة الاشتراك الحالية', value: subscription.packageName),
          _DetailField(label: 'سعر الاشتراك والفوترة', value: '${subscription.amount.toStringAsFixed(2)} ج.م'),
          _DetailField(label: 'عدد الرحلات المتبقية للعميل', value: '${subscription.remainingRides} رحلات متاحة'),
          _DetailField(label: 'تاريخ بدء الاشتراك', value: subscription.startDate.toString().substring(0, 10)),
          _DetailField(label: 'تاريخ وتوقيت انتهاء الاشتراك', value: subscription.endDate.toString().substring(0, 10)),
          const Divider(height: AppSpacing.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('حالة الاشتراك الحالية:', style: TextStyle(fontWeight: FontWeight.w500)),
              _SubscriptionStatusBadge(status: subscription.status),
            ],
          ),
          const Divider(height: AppSpacing.large),
          if (subscription.status == SubscriptionStatus.active) ...[
            if (actionLoading)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: onCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text('إلغاء الاشتراك الفعال فوراً'),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'الاشتراك منتهي أو تم إلغاؤه مسبقاً، ولا يمكن إجراء تعديلات عليه.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubscriptionStatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  const _SubscriptionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      SubscriptionStatus.active => (Colors.green.shade50, Colors.green.shade900),
      SubscriptionStatus.expired => (Colors.grey.shade100, Colors.grey.shade700),
      SubscriptionStatus.cancelled => (Colors.red.shade50, Colors.red.shade900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// -------------------------------------------------------------
// SECTION 5: REVENUE (الإيرادات)
// -------------------------------------------------------------
class _RevenueSection extends StatelessWidget {
  final FinanceLoaded state;
  const _RevenueSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Charts & breakdowns
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مخطط الإيرادات الأسبوعي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text('توضيح حركة المبيعات وتدفق الإيرادات اليومية في السبعة أيام الأخيرة.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(height: AppSpacing.large),
                // Simulated Chart Widget
                Expanded(child: _RevenueChartWidget(payments: state.payments)),
              ],
            ),
          ),
          const VerticalDivider(width: 32),
          // Right Side: Breakdown list
          Expanded(
            flex: 4,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Text('نسبة توزيع طرق الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: AppSpacing.medium),
                _MethodBreakdownItem(
                  method: FinancePaymentMethod.instapay,
                  payments: state.payments,
                ),
                _MethodBreakdownItem(
                  method: FinancePaymentMethod.vodafoneCash,
                  payments: state.payments,
                ),
                _MethodBreakdownItem(
                  method: FinancePaymentMethod.card,
                  payments: state.payments,
                ),
                _MethodBreakdownItem(
                  method: FinancePaymentMethod.cash,
                  payments: state.payments,
                ),
                const Divider(height: AppSpacing.large),
                const Text('ملخص مؤشرات الإيرادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: AppSpacing.medium),
                _RevenueMetricSummaryRow(label: 'متوسط قيمة العملية', value: '${_calculateAverageTxnValue().toStringAsFixed(1)} ج.م'),
                _RevenueMetricSummaryRow(label: 'إجمالي العمليات الناجحة', value: '${state.payments.where((p) => p.status == PaymentStatus.success).length} عملية'),
                _RevenueMetricSummaryRow(label: 'المرتجعات المقبولة', value: '${state.payments.where((p) => p.status == PaymentStatus.refunded).length} عملية مستردة'),
                _RevenueMetricSummaryRow(label: 'إيرادات الاشتراكات (مضمنة)', value: '${_calculateTotalSubscriptionsRevenue().toStringAsFixed(0)} ج.م'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverageTxnValue() {
    final successPayments = state.payments.where((p) => p.status == PaymentStatus.success).toList();
    if (successPayments.isEmpty) return 0.0;
    final total = successPayments.map((p) => p.amount).reduce((a, b) => a + b);
    return total / successPayments.length;
  }

  double _calculateTotalSubscriptionsRevenue() {
    return state.subscriptions.where((s) => s.status == SubscriptionStatus.active).map((s) => s.amount).fold(0.0, (a, b) => a + b);
  }
}

class _MethodBreakdownItem extends StatelessWidget {
  final FinancePaymentMethod method;
  final List<PaymentRecord> payments;

  const _MethodBreakdownItem({
    required this.method,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final successPayments = payments.where((p) => p.status == PaymentStatus.success).toList();
    final total = successPayments.isEmpty ? 1.0 : successPayments.map((p) => p.amount).fold(0.0, (a, b) => a + b);

    final methodTotal = successPayments.where((p) => p.paymentMethod == method).map((p) => p.amount).fold(0.0, (a, b) => a + b);

    final double percentage = methodTotal / total;

    final color = switch (method) {
      FinancePaymentMethod.instapay => Colors.purple,
      FinancePaymentMethod.vodafoneCash => Colors.red,
      FinancePaymentMethod.card => Colors.blue,
      FinancePaymentMethod.cash => Colors.amber,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(method.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('${(percentage * 100).toStringAsFixed(1)}% (${methodTotal.toStringAsFixed(0)} ج.م)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            color: color,
            backgroundColor: color.withAlpha(20),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _RevenueMetricSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _RevenueMetricSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// REVENUE CHART WIDGET (simulated bar/line graph)
// -------------------------------------------------------------
class _RevenueChartWidget extends StatelessWidget {
  final List<PaymentRecord> payments;
  const _RevenueChartWidget({required this.payments});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // We will aggregate sales for the last 7 days
    final now = DateTime.now();
    final List<MapEntry<String, double>> dailyTotals = [];

    final arabicDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dateStr = targetDate.toString().substring(0, 10);
      final dayName = arabicDays[targetDate.weekday % 7];

      final double total = payments.where((p) {
        return p.status == PaymentStatus.success && p.date.toString().substring(0, 10) == dateStr;
      }).fold(0.0, (sum, p) => sum + p.amount);

      dailyTotals.add(MapEntry(dayName, total));
    }

    final double maxVal = dailyTotals.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxCeiling = maxVal == 0 ? 1000 : ((maxVal / 500).ceil() * 500).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-Axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final double value = maxCeiling * (4 - index) / 4;
            return Text(
              '${value.toStringAsFixed(0)} ج',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            );
          }),
        ),
        const SizedBox(width: 8),

        // Bars Container
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyTotals.map((entry) {
                  final double barHeightPercentage = maxCeiling == 0 ? 0.0 : (entry.value / maxCeiling);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tooltip value
                      Text(
                        entry.value.toStringAsFixed(0),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: scheme.primary),
                      ),
                      const SizedBox(height: 4),
                      // The visual bar
                      Container(
                        width: 24,
                        height: (box.maxHeight - 35) * barHeightPercentage,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [scheme.primary, scheme.secondary],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Day Label
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
