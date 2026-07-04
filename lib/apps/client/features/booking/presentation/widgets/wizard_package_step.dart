import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_state.dart';

class WizardPackageStep extends StatefulWidget {
  const WizardPackageStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<WizardPackageStep> createState() => _WizardPackageStepState();
}

class _WizardPackageStepState extends State<WizardPackageStep> {
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    context.read<PackagesCubit>().load();
    _startDate = _nextWorkday(DateTime.now());
  }

  DateTime _nextWorkday(DateTime from) {
    var date = from.add(const Duration(days: 1));
    while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (date) =>
          date.weekday != DateTime.saturday && date.weekday != DateTime.sunday,
    );
    if (picked == null || !mounted) return;
    setState(() => _startDate = picked);
    final selected = context.read<BookingWizardCubit>().state.selectedPackage;
    if (selected != null) {
      context.read<BookingWizardCubit>().selectPackage(selected, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesCubit, PackagesState>(
      builder: (context, packagesState) {
        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) {
            if (packagesState is PackagesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (packagesState is PackagesError) {
              return _PackageError(
                message: packagesState.message,
                onRetry: context.read<PackagesCubit>().load,
              );
            }
            final packages = (packagesState as PackagesLoaded).filteredPackages;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      BookingStepIntro(
                        icon: Icons.local_offer_rounded,
                        title: 'Choose the best fare',
                        subtitle:
                            'Compare the regular total with each package price.',
                        trailing: BookingCountPill(
                          label: '${packages.length} options',
                          color: ClientColors.journeyPurple,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...packages.indexed.map((entry) {
                        final package = entry.$2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PackageCard(
                            plan: package,
                            isFeatured:
                                package.rideCount > 1 &&
                                entry.$1 == _featuredIndex(packages),
                            isSelected:
                                session.selectedPackage?.id == package.id,
                            tripPrice: session.tripPrice,
                            onTap: () {
                              final date =
                                  _startDate ?? _nextWorkday(DateTime.now());
                              context.read<BookingWizardCubit>().selectPackage(
                                package,
                                date,
                              );
                            },
                          ),
                        );
                      }),
                      if (session.selectedPackage != null) ...[
                        const SizedBox(height: 6),
                        _StartDatePicker(date: _startDate, onTap: _pickDate),
                      ],
                    ],
                  ),
                ),
                BookingBottomAction(
                  summary: session.selectedPackage == null
                      ? null
                      : _SelectedPackageSummary(session: session),
                  child: ClientButton(
                    label: 'Review booking',
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: session.packageValid ? widget.onNext : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _featuredIndex(List<PackagePlan> packages) {
    final index = packages.indexWhere((plan) => plan.rideCount > 2);
    return index < 0 ? 0 : index;
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.plan,
    required this.isFeatured,
    required this.isSelected,
    required this.tripPrice,
    required this.onTap,
  });

  final PackagePlan plan;
  final bool isFeatured;
  final bool isSelected;
  final double tripPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final regularTotal = tripPrice * plan.rideCount;
    final hasComparison = regularTotal > plan.price && regularTotal > 0;
    final savings = hasComparison ? regularTotal - plan.price : 0.0;
    final discount = hasComparison
        ? ((savings / regularTotal) * 100).round()
        : 0;
    final title = plan.nameEn.trim().isEmpty ? plan.nameAr : plan.nameEn;
    final accent = plan.rideCount == 1
        ? ClientColors.primary
        : ClientColors.journeyPurple;

    return GestureDetector(
      onTap: onTap,
      child: BookingSurfaceCard(
        selected: isSelected,
        accentColor: accent,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: const BoxDecoration(
                  color: ClientColors.journeyPurple,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ClientRadius.lg - 1),
                  ),
                ),
                child: Text(
                  'BEST VALUE',
                  textAlign: TextAlign.center,
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: Colors.white, letterSpacing: 1),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(18),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          plan.rideCount == 1
                              ? Icons.confirmation_number_outlined
                              : Icons.card_membership_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: ClientTypography.headingSmall(
                                context,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${plan.rideCount} ${plan.rideCount == 1 ? 'ride' : 'rides'}'
                              ' • valid for ${plan.durationDays} days',
                              style: ClientTypography.bodySmall(context)
                                  .copyWith(
                                    color: ClientColors.textSecondaryFor(
                                      context,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: ClientMotion.base,
                        child: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                key: const ValueKey('selected'),
                                color: accent,
                                size: 26,
                              )
                            : Icon(
                                Icons.radio_button_unchecked_rounded,
                                key: const ValueKey('empty'),
                                color: ClientColors.borderStrongFor(context),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EGP ${plan.price.toStringAsFixed(0)}',
                        style: ClientTypography.priceMedium(
                          context,
                        ).copyWith(color: accent),
                      ),
                      const SizedBox(width: 8),
                      if (hasComparison)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'EGP ${regularTotal.toStringAsFixed(0)}',
                            style: ClientTypography.bodySmall(context).copyWith(
                              color: ClientColors.textTertiaryFor(context),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (discount > 0)
                        BookingCountPill(
                          label: 'Save $discount%',
                          color: ClientColors.journeyGreen,
                        ),
                    ],
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'You keep EGP ${savings.toStringAsFixed(0)} compared with individual rides.',
                      style: ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.journeyGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartDatePicker extends StatelessWidget {
  const _StartDatePicker({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Select start date'
        : '${date!.day}/${date!.month}/${date!.year}';
    return GestureDetector(
      onTap: onTap,
      child: BookingSurfaceCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ClientColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: ClientColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package starts',
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                  Text(
                    label,
                    style: ClientTypography.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded),
          ],
        ),
      ),
    );
  }
}

class _SelectedPackageSummary extends StatelessWidget {
  const _SelectedPackageSummary({required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final plan = session.selectedPackage!;
    final name = plan.nameEn.trim().isEmpty ? plan.nameAr : plan.nameEn;
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          'EGP ${plan.price.toStringAsFixed(0)}',
          style: ClientTypography.priceSmall(
            context,
          ).copyWith(color: ClientColors.journeyPurple),
        ),
      ],
    );
  }
}

class _PackageError extends StatelessWidget {
  const _PackageError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 52,
              color: ClientColors.journeyRed,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load fares',
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(context),
            ),
            const SizedBox(height: 18),
            ClientButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
