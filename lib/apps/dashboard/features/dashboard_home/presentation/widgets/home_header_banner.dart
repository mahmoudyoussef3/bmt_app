import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// Who is signed in, which office they manage, and — quietly, not as the
/// headline — whether that office is currently visible to passengers.
///
/// Reads entirely off [OfficeContext], which the shell already resolves at
/// sign-in: no query of its own. Deliberately does not repeat the bell icon
/// or a profile menu — the shell's top bar already renders both, and this is
/// the screen body, not another copy of the chrome around it.
class HomeHeaderBanner extends StatelessWidget {
  const HomeHeaderBanner({super.key, required this.office, this.onRefresh});

  final OfficeContext office;
  final VoidCallback? onRefresh;

  static const _navy = Color(0xFF0F2747);

  @override
  Widget build(BuildContext context) {
    final name = office.officeName.trim().isEmpty
        ? 'مكتبك'
        : office.officeName.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _Identity(office: office, name: name);
          final trailing = _Trailing(office: office, onRefresh: onRefresh);
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.medium),
                trailing,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.medium),
              trailing,
            ],
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.office, required this.name});

  final OfficeContext office;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _OfficeLogo(logoUrl: office.logoUrl, name: name),
        const SizedBox(width: AppSpacing.medium),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مرحباً، ${office.displayName} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfficeLogo extends StatelessWidget {
  const _OfficeLogo({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim() ?? '';
    final initial = name.characters.isEmpty ? '؟' : name.characters.first;
    final fallback = Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.office, this.onRefresh});

  final OfficeContext office;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatArabicDate(DateTime.now()),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: AppSpacing.small),
              _RefreshButton(onRefresh: onRefresh!),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        _MarketplaceMiniBadge(listingStatus: office.listingStatus),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'تحديث البيانات',
      child: Material(
        color: Colors.white.withAlpha(28),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onRefresh,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceMiniBadge extends StatelessWidget {
  const _MarketplaceMiniBadge({required this.listingStatus});

  final String listingStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (listingStatus) {
      'listed' => (
        'المكتب معروض في السوق',
        const Color(0xFF22A06B),
        Icons.storefront_rounded,
      ),
      'draft' => (
        'المكتب قيد التجهيز',
        const Color(0xFFF5A623),
        Icons.hourglass_top_rounded,
      ),
      _ => (
        'المكتب غير معروض في السوق',
        Colors.white54,
        Icons.visibility_off_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const _arabicWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _easternArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _toArabicDigits(String input) {
  return input.split('').map((ch) {
    final digit = int.tryParse(ch);
    return digit == null ? ch : _easternArabicDigits[digit];
  }).join();
}

String _formatArabicDate(DateTime date) {
  final weekday = _arabicWeekdays[date.weekday - 1];
  final month = _arabicMonths[date.month - 1];
  return '$weekday، ${_toArabicDigits('${date.day}')} $month ${_toArabicDigits('${date.year}')}';
}
