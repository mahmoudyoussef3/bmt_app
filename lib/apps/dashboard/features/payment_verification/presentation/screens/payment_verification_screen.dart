import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_state_views.dart';
import '../../domain/entities/booking_payment_verification.dart';
import '../cubit/payment_verification_cubit.dart';
import '../cubit/payment_verification_state.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentVerificationCubit, PaymentVerificationState>(
      listenWhen: (previous, current) => current is PaymentVerificationLoaded,
      listener: (context, state) {
        if (state is! PaymentVerificationLoaded) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        final message = state.message;
        final error = state.errorMessage;
        if (message == null && error == null) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message ?? error ?? ''),
              backgroundColor: error == null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          );
        context.read<PaymentVerificationCubit>().clearFeedback();
      },
      builder: (context, state) {
        return switch (state) {
          PaymentVerificationLoading() => const DashboardLoading(
            rows: 6,
            showHeader: true,
          ),
          PaymentVerificationError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<PaymentVerificationCubit>().load(),
          ),
          PaymentVerificationLoaded() => _VerificationLoadedView(state: state),
        };
      },
    );
  }
}

class _VerificationLoadedView extends StatelessWidget {
  final PaymentVerificationLoaded state;

  const _VerificationLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PaymentVerificationCubit>();
    final selected = state.selectedItem;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardModuleHeader(
            icon: Icons.fact_check_outlined,
            title: 'تحقق مدفوعات الحجوزات',
            subtitle:
                'راجع الإيصالات، ثبّت المقاعد، اطلب إعادة الرفع، واترك سجل مراجعة واضح لكل حجز.',
            actions: [
              OutlinedButton.icon(
                onPressed: state.isSaving ? null : cubit.load,
                icon: state.isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
            child: _VerificationToolbar(
              state: state,
              onQueryChanged: cubit.setQuery,
              onFilterChanged: cubit.setFilter,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1080;
                final queue = _VerificationQueue(
                  state: state,
                  onSelect: cubit.select,
                );
                final review = selected == null
                    ? const _NoSelectionPanel()
                    : _ReviewScreen(
                        item: selected,
                        zoom: state.receiptZoom,
                        scrollable: !compact,
                        isSaving: state.isSaving,
                        onZoomChanged: cubit.setReceiptZoom,
                        onApprove: (note) => cubit.approve(selected, note),
                        onReject: (note) => cubit.reject(selected, note),
                        onRequestReview: (note) =>
                            cubit.requestReview(selected, note),
                        onAddNote: (note) => cubit.addNote(selected, note),
                      );

                if (compact) {
                  return ListView(
                    children: [
                      SizedBox(height: 560, child: queue),
                      const SizedBox(height: AppSpacing.large),
                      review,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 420, child: queue),
                    const SizedBox(width: AppSpacing.large),
                    Expanded(child: review),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationQueue extends StatelessWidget {
  final PaymentVerificationLoaded state;
  final ValueChanged<String> onSelect;

  const _VerificationQueue({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final visibleItems = state.visibleItems;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _QueueHeader(),
          if (visibleItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.large),
              child: EmptyState(
                title: 'لا توجد حجوزات مطابقة',
                subtitle: 'غيّر البحث أو الفلتر لعرض بقية الطلبات.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.medium),
                itemCount: visibleItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.small),
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return _QueueCard(
                    item: item,
                    selected: item.id == state.selectedItem?.id,
                    onTap: () => onSelect(item.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationToolbar extends StatelessWidget {
  final PaymentVerificationLoaded state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PaymentVerificationFilter> onFilterChanged;

  const _VerificationToolbar({
    required this.state,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = SearchBar(
          hintText: 'ابحث بالعميل، الهاتف، رقم الحجز، المسار أو المرجع',
          leading: const Icon(Icons.search_rounded),
          onChanged: onQueryChanged,
        );
        final filters = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in PaymentVerificationFilter.values) ...[
                ChoiceChip(
                  label: Text(filter.label),
                  selected: state.filter == filter,
                  onSelected: (_) => onFilterChanged(filter),
                ),
                const SizedBox(width: AppSpacing.xSmall),
              ],
            ],
          ),
        );

        final stats = Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _Metric(label: 'بانتظار', value: '${state.pendingCount}'),
            _Metric(label: 'مراجعة', value: '${state.reviewCount}'),
            _Metric(label: 'مقبولة', value: '${state.approvedCount}'),
            _Metric(label: 'المعروض', value: '${state.visibleItems.length}'),
          ],
        );

        if (constraints.maxWidth < 920) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: AppSpacing.medium),
              filters,
              const SizedBox(height: AppSpacing.medium),
              stats,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 4, child: filters),
            const SizedBox(width: AppSpacing.medium),
            Expanded(flex: 4, child: stats),
          ],
        );
      },
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Icon(Icons.queue_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              'قائمة المراجعة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final BookingPaymentVerification item;
  final bool selected;
  final VoidCallback onTap;

  const _QueueCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _verificationStatusColor(context, item.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withAlpha(16)
              : scheme.surfaceContainerHighest.withAlpha(42),
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withAlpha(24),
                  foregroundColor: statusColor,
                  child: Icon(_statusIcon(item.status), size: 18),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    item.customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                StatusChip(label: item.status.label),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              item.trip.route.isEmpty ? 'مسار غير محدد' : item.trip.route,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                _InlineMeta(
                  icon: Icons.event_seat_outlined,
                  text: 'مقعد ${item.selectedSeat}',
                ),
                _InlineMeta(icon: Icons.payments_outlined, text: item.amount),
                _InlineMeta(
                  icon: Icons.schedule_outlined,
                  text: item.trip.time,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              '${item.method.label} • ${item.seatState.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: EmptyState(
        title: 'لا توجد إيصالات للمراجعة',
        subtitle:
            'ستظهر إيصالات الحجز الجديدة هنا فور وصولها أو عند تغيير الفلتر.',
      ),
    );
  }
}

class _ReviewScreen extends StatefulWidget {
  final BookingPaymentVerification item;
  final double zoom;
  final bool scrollable;
  final bool isSaving;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onRequestReview;
  final ValueChanged<String> onAddNote;

  const _ReviewScreen({
    required this.item,
    required this.zoom,
    this.scrollable = true,
    required this.isSaving,
    required this.onZoomChanged,
    required this.onApprove,
    required this.onReject,
    required this.onRequestReview,
    required this.onAddNote,
  });

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final content = [
      _ReviewHeader(item: item),
      const SizedBox(height: AppSpacing.medium),
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          final receipt = _ReceiptPreview(
            item: item,
            zoom: widget.zoom,
            onZoomChanged: widget.onZoomChanged,
          );
          final details = _ReviewDetails(
            item: item,
            notes: _notes,
            isSaving: widget.isSaving,
            onApprove: () => _confirmAndSubmit(
              context,
              title: 'اعتماد الدفع',
              message:
                  'سيتم تثبيت المقعد ${item.selectedSeat} نهائياً للحجز ${item.bookingId}.',
              confirmLabel: 'اعتماد',
              action: widget.onApprove,
            ),
            onReject: () => _confirmAndSubmit(
              context,
              title: 'رفض الدفع',
              message:
                  'سيتم رفض الدفع وتحرير المقعد ${item.selectedSeat}. اكتب سبب الرفض في الملاحظات قبل التأكيد.',
              confirmLabel: 'رفض الدفع',
              action: widget.onReject,
            ),
            onRequestReview: () => _confirmAndSubmit(
              context,
              title: 'طلب مراجعة من العميل',
              message:
                  'سيبقى المقعد مؤقتاً وسيتم تسجيل طلب مراجعة أو إعادة رفع الإيصال.',
              confirmLabel: 'طلب مراجعة',
              action: widget.onRequestReview,
            ),
            onAddNote: () => _submit(widget.onAddNote),
          );

          if (compact) {
            return Column(
              children: [
                receipt,
                const SizedBox(height: AppSpacing.medium),
                details,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: receipt),
              const SizedBox(width: AppSpacing.medium),
              Expanded(flex: 2, child: details),
            ],
          );
        },
      ),
    ];

    if (!widget.scrollable) {
      return Column(children: content);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: content,
    );
  }

  void _submit(ValueChanged<String> action) {
    action(_notes.text);
    _notes.clear();
  }

  Future<void> _confirmAndSubmit(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required ValueChanged<String> action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _submit(action);
  }
}

class _ReviewHeader extends StatelessWidget {
  final BookingPaymentVerification item;

  const _ReviewHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  '${item.amount} • ${item.method.label} • ${item.bookingId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          StatusChip(label: item.seatState.label),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final BookingPaymentVerification item;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const _ReceiptPreview({
    required this.item,
    required this.zoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'معاينة الإيصال',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if ((item.receiptUrl ?? '').isNotEmpty)
                IconButton(
                  tooltip: 'فتح الملف الأصلي',
                  onPressed: () => launchUrl(
                    Uri.parse(item.receiptUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              IconButton(
                tooltip: 'تصغير',
                onPressed: () => onZoomChanged(zoom - 0.1),
                icon: const Icon(Icons.zoom_out),
              ),
              Text('${(zoom * 100).round()}%'),
              IconButton(
                tooltip: 'تكبير',
                onPressed: () => onZoomChanged(zoom + 0.1),
                icon: const Icon(Icons.zoom_in),
              ),
            ],
          ),
          Slider(value: zoom, min: 0.8, max: 2.2, onChanged: onZoomChanged),
          const SizedBox(height: AppSpacing.medium),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Container(
              constraints: const BoxConstraints(minHeight: 360, maxHeight: 460),
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(72),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3,
                child: Center(
                  child: Transform.scale(
                    scale: zoom,
                    child: item.receiptUrl == null || item.receiptUrl!.isEmpty
                        ? _ReceiptPlaceholder(item: item)
                        : Image.network(
                            item.receiptUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _ReceiptPlaceholder(
                                  item: item,
                                  failedUrl: true,
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPlaceholder extends StatelessWidget {
  final BookingPaymentVerification item;
  final bool failedUrl;

  const _ReceiptPlaceholder({required this.item, this.failedUrl = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.large),
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withAlpha(28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failedUrl ? Icons.broken_image_outlined : Icons.image_outlined,
              size: 46,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              failedUrl ? 'تعذر عرض الإيصال' : item.receiptTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              item.referenceNumber.isEmpty
                  ? 'لا يوجد رقم مرجعي'
                  : item.referenceNumber,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: AppSpacing.large),
            _ReceiptLine(label: 'المبلغ', value: item.amount),
            _ReceiptLine(label: 'الطريقة', value: item.method.label),
            if (item.packageName.isNotEmpty)
              _ReceiptLine(label: 'الباقة', value: item.packageName),
            if (item.payerPhone.isNotEmpty)
              _ReceiptLine(label: 'هاتف المحوّل', value: item.payerPhone),
            _ReceiptLine(label: 'الحجز', value: item.bookingId),
            const SizedBox(height: AppSpacing.small),
            Text(
              item.receiptMeta,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDetails extends StatelessWidget {
  final BookingPaymentVerification item;
  final TextEditingController notes;
  final bool isSaving;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestReview;
  final VoidCallback onAddNote;

  const _ReviewDetails({
    required this.item,
    required this.notes,
    required this.isSaving,
    required this.onApprove,
    required this.onReject,
    required this.onRequestReview,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات الحجز والمقعد',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          _InfoRow(label: 'العميل', value: item.customer.name),
          _InfoRow(label: 'الهاتف', value: item.customer.phone),
          _InfoRow(label: 'الحساب', value: item.customer.profileStatus),
          _InfoRow(label: 'الرحلة', value: item.trip.tripId),
          _InfoRow(label: 'المسار', value: item.trip.route),
          _InfoRow(
            label: 'الموعد',
            value: '${item.trip.date} • ${item.trip.time}',
          ),
          _InfoRow(label: 'المركبة', value: item.trip.vehicle),
          _InfoRow(label: 'السائق', value: item.trip.driver),
          _InfoRow(label: 'المقعد', value: item.selectedSeat),
          _InfoRow(label: 'حالة المقعد', value: item.seatState.label),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 4,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'ملاحظات التحقق',
              hintText: 'اكتب سبب القرار أو ملاحظة للمتابعة',
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              FilledButton.icon(
                onPressed: isSaving ? null : onApprove,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text('اعتماد الدفع'),
              ),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onReject,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('رفض'),
              ),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onRequestReview,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('طلب مراجعة'),
              ),
              TextButton.icon(
                onPressed: isSaving ? null : onAddNote,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('إضافة ملاحظة'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text('الملاحظات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          if (item.notes.isEmpty)
            const Text('لا توجد ملاحظات.')
          else
            ...item.notes.map((note) => _NoteRow(note: note)),
          const SizedBox(height: AppSpacing.medium),
          Text('مسار الإجراء', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          ...item.history.map((history) => _HistoryRow(item: history)),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'غير محدد' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, size: 18),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(note)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final VerificationHistoryItem item;

  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 7, backgroundColor: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xSmall),
                Text('${item.time} • ${item.description}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _verificationStatusColor(
  BuildContext context,
  BookingVerificationStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    BookingVerificationStatus.pending => const Color(0xFFB45309),
    BookingVerificationStatus.approved => const Color(0xFF0F766E),
    BookingVerificationStatus.rejected => scheme.error,
    BookingVerificationStatus.reviewRequested => scheme.tertiary,
  };
}

IconData _statusIcon(BookingVerificationStatus status) {
  return switch (status) {
    BookingVerificationStatus.pending => Icons.hourglass_top_rounded,
    BookingVerificationStatus.approved => Icons.check_circle_outline_rounded,
    BookingVerificationStatus.rejected => Icons.cancel_outlined,
    BookingVerificationStatus.reviewRequested => Icons.upload_file_outlined,
  };
}
