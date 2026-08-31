import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';
import '../models/office_license_view.dart';

/// «تواصل مع إدارة المنصة», made into something the owner can actually press.
///
/// There is no checkout in this release — a plan change has proration
/// implications that need a real billing engine — and the console holds no
/// contact detail for the platform, so inventing a phone number here would be
/// worse than the sentence it replaces. What it *can* do is compose the request:
/// the office, the plan it is on, the state that plan is in, and the meters it
/// is pressing against, ready to copy into whichever channel the owner already
/// uses with their account manager.
Future<void> showOfficeUpgradeRequest(
  BuildContext context, {
  required LicenseSummary license,
  required String officeName,
  List<ResolvedFeature> pressuredMeters = const [],
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UpgradeRequestDialog(
      body: composeUpgradeRequest(
        license: license,
        officeName: officeName,
        pressuredMeters: pressuredMeters,
      ),
    ),
  );
}

/// The message itself. Pure, so a test can read it without a widget tree.
String composeUpgradeRequest({
  required LicenseSummary license,
  required String officeName,
  List<ResolvedFeature> pressuredMeters = const [],
}) {
  final cycle = licenseCycleLabel(license.billingCycle);
  final lines = <String>[
    'طلب تعديل اشتراك',
    if (officeName.trim().isNotEmpty) 'المكتب: ${officeName.trim()}',
    'الباقة الحالية: '
        '${license.planNameAr.trim().isEmpty ? 'بدون باقة' : license.planNameAr.trim()}'
        ' — ${license.statusLabelAr}',
    if (license.price != null)
      'القيمة: ${licensingMoney(license.price, license.currency)}'
          '${cycle.isEmpty ? '' : ' ($cycle)'}',
    if (license.periodEnd != null)
      'نهاية الفترة الحالية: ${licensingDate(license.periodEnd)}',
    for (final meter in pressuredMeters)
      'حد تحت الضغط: ${meter.nameAr} — ${meter.used ?? 0} / ${meter.limit}'
          '${meter.unitAr.isEmpty ? '' : ' ${meter.unitAr}'}',
    'المطلوب: (اكتب هنا الباقة أو الحد المطلوب)',
  ];
  return lines.join('\n');
}

class _UpgradeRequestDialog extends StatelessWidget {
  const _UpgradeRequestDialog({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('طلب من إدارة المنصة'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ترقية الباقة أو رفع أي حد يتم من إدارة المنصة، ولا يتم ذاتيًا '
                'في هذا الإصدار. هذا نص الطلب جاهزًا ببيانات اشتراكك — انسخه '
                'وأرسله لمسؤول حسابك.',
                style: text.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: DashboardColors.well(context),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: DashboardColors.border(context)),
                ),
                child: SelectableText(
                  body,
                  style: text.bodySmall?.copyWith(height: 1.9),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            await Clipboard.setData(ClipboardData(text: body));
            navigator.pop();
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('تم نسخ نص الطلب.')));
          },
          icon: const Icon(DashboardIcons.document, size: 18),
          label: const Text('نسخ الطلب'),
        ),
      ],
    );
  }
}
