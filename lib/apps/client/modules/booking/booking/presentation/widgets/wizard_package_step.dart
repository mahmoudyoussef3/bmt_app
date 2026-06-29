import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/modules/services/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/modules/services/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/modules/services/packages/presentation/cubit/packages_state.dart';

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
    var d = from.add(const Duration(days: 1));
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (d) =>
          d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesCubit, PackagesState>(
      builder: (context, pkgState) {
        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) {
            if (pkgState is PackagesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (pkgState is PackagesError) {
              return Center(child: Text(pkgState.message));
            }
            final packages = (pkgState as PackagesLoaded).filteredPackages;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    children: [
                      Text('Choose a package',
                          style: ClientTypography.headingSmall(context)),
                      const SizedBox(height: 4),
                      Text('Packages cover working days (Mon–Fri)',
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          )),
                      const SizedBox(height: 16),
                      ...packages.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PackageCard(
                              plan: p,
                              isSelected: session.selectedPackage?.name == p.name,
                              tripPrice: session.tripPrice,
                              onTap: () {
                                final date = _startDate ?? _nextWorkday(DateTime.now());
                                context.read<BookingWizardCubit>().selectPackage(p, date);
                              },
                            ),
                          )),
                      const SizedBox(height: 16),
                      _StartDatePicker(date: _startDate, onTap: _pickDate),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ClientButton(
                      label: 'Continue',
                      onPressed: session.packageValid ? widget.onNext : null,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.plan,
    required this.isSelected,
    required this.tripPrice,
    required this.onTap,
  });
  final PackagePlan plan;
  final bool isSelected;
  final double tripPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = tripPrice * plan.tripsCount * (1 - plan.discountPercent / 100);
    final borderColor = isSelected ? ClientColors.journeyPurple : ClientColors.borderFor(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ClientColors.journeyPurpleLight : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: ClientTypography.bodyMedium(context)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text('${plan.tripsCount} rides · ${plan.durationLabel}',
                      style: ClientTypography.bodySmall(context)
                          .copyWith(color: ClientColors.textSecondaryFor(context))),
                  if (plan.discountPercent > 0)
                    Text('Save ${plan.discountPercent}%',
                        style: ClientTypography.labelSmall(context)
                            .copyWith(color: ClientColors.journeyGreen)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('EGP ${total.toStringAsFixed(0)}',
                    style: ClientTypography.headingSmall(context).copyWith(
                      color: isSelected ? ClientColors.journeyPurple : ClientColors.textPrimaryFor(context),
                      fontWeight: FontWeight.w700,
                    )),
                Text('EGP ${(tripPrice * plan.tripsCount).toStringAsFixed(0)} full',
                    style: ClientTypography.labelSmall(context).copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: ClientColors.textTertiary,
                    )),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_circle_rounded, color: ClientColors.journeyPurple, size: 22),
            ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: ClientColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Package start date',
                      style: ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.textSecondaryFor(context),
                      )),
                  Text(label,
                      style: ClientTypography.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: date == null
                            ? ClientColors.textTertiary
                            : ClientColors.textPrimaryFor(context),
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ClientColors.journeySlate),
          ],
        ),
      ),
    );
  }
}
