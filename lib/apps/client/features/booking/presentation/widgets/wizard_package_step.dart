import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/package_option_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/package_step_footer.dart';
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

  void _select(PackagePlan plan) {
    context.read<BookingWizardCubit>().selectPackage(
      plan,
      _startDate ?? _nextWorkday(DateTime.now()),
    );
  }

  /// The plan we badge as best value: the first multi-ride plan, which is the
  /// cheapest real commitment rather than the biggest one we can upsell.
  int _featuredIndex(List<PackagePlan> plans) {
    final index = plans.indexWhere((plan) => plan.rideCount > 2);
    return index < 0 ? -1 : index;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesCubit, PackagesState>(
      builder: (context, packagesState) {
        if (packagesState is PackagesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (packagesState is PackagesError) {
          return PackageFaresError(
            message: packagesState.message,
            onRetry: context.read<PackagesCubit>().load,
          );
        }
        final plans = (packagesState as PackagesLoaded).filteredPackages;
        final featured = _featuredIndex(plans);

        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    BookingStepIntro(
                      icon: Icons.local_offer_rounded,
                      title: 'Choose your fare',
                      subtitle:
                          'Prices are for ${session.pickupStop?.name ?? 'your pickup'}'
                          ' → ${session.dropoffStop?.name ?? 'your stop'}.',
                      trailing: BookingCountPill(
                        label: '${plans.length} options',
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < plans.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PackageOptionCard(
                          plan: plans[i],
                          price: session.resolvedPackagePrice(plans[i]),
                          singleRideFare: session.tripPrice,
                          isFeatured: i == featured,
                          isSelected:
                              session.selectedPackage?.id == plans[i].id,
                          onTap: () => _select(plans[i]),
                        ),
                      ),
                    if (session.selectedPackage != null) ...[
                      const SizedBox(height: 6),
                      PackageStartDateField(date: _startDate, onTap: _pickDate),
                    ],
                  ],
                ),
              ),
              BookingBottomAction(
                summary: session.selectedPackage == null
                    ? null
                    : PackageStepSummary(session: session),
                child: ClientButton(
                  label: 'Review booking',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: session.packageValid ? widget.onNext : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
