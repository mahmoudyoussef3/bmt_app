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
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

class WizardPackageStep extends StatefulWidget {
  const WizardPackageStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<WizardPackageStep> createState() => _WizardPackageStepState();
}

class _WizardPackageStepState extends State<WizardPackageStep> {
  @override
  void initState() {
    super.initState();
    _loadAndApplyInitialSelection();
  }

  /// Loads the catalogue, then applies the package reviewed before this
  /// search started, if any and if nothing has been chosen yet.
  Future<void> _loadAndApplyInitialSelection() async {
    final packagesCubit = context.read<PackagesCubit>();
    final wizardCubit = context.read<BookingWizardCubit>();
    await packagesCubit.load();
    if (!mounted || wizardCubit.state.selectedPackage != null) return;
    final packageId = wizardCubit.initialPackageId;
    final packagesState = packagesCubit.state;
    if (packageId == null || packagesState is! PackagesLoaded) return;
    for (final plan in packagesState.packages) {
      if (plan.id == packageId) {
        wizardCubit.selectPackage(plan);
        break;
      }
    }
  }

  void _select(PackagePlan plan) {
    context.read<BookingWizardCubit>().selectPackage(plan);
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
        // The wizard has no filter strip, so it always shows the full catalogue.
        final plans = (packagesState as PackagesLoaded).packages;
        final featured = _featuredIndex(plans);

        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) {
            final l10n = context.l10n;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      BookingStepIntro(
                        icon: Icons.local_offer_rounded,
                        title: l10n.booking_chooseYourFare,
                        subtitle: l10n.booking_pricesAreForRoute(
                          session.pickupStop?.name ??
                              l10n.booking_yourPickupFallback,
                          session.dropoffStop?.name ??
                              l10n.booking_yourStopFallback,
                        ),
                        trailing: BookingCountPill(
                          label: l10n.booking_optionsCount(plans.length),
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
                        PackageStartNote(date: session.packageStartDate),
                      ],
                    ],
                  ),
                ),
                BookingBottomAction(
                  summary: session.selectedPackage == null
                      ? null
                      : PackageStepSummary(session: session),
                  child: ClientButton(
                    label: l10n.booking_reviewBooking,
                    icon: const DirectionalIcon(Icons.arrow_forward_rounded),
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
}
