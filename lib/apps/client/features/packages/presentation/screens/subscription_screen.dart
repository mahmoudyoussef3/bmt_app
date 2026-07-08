import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_state.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.hasActiveSubscription = false,
    this.bookingData,
  });

  final bool hasActiveSubscription;
  final Map<String, dynamic>? bookingData;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1; // Steps 1 to 5
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    context.read<PackagesCubit>().load();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _onBackPress() {
    final current = context.read<PackagesCubit>().state;
    final isProcessing = current is PackagesLoaded && current.isProcessing;
    if (_currentStep > 1 && !isProcessing) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _activateSubscription() {
    context.read<PackagesCubit>().subscribe();
  }

  void _onSubscriptionStateChanged(BuildContext context, PackagesState state) {
    if (state is! PackagesLoaded) return;
    final error = state.subscribeError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not activate subscription: $error')),
      );
      context.read<PackagesCubit>().clearSubscribeError();
      return;
    }
    if (state.subscribed && _currentStep != 5) {
      setState(() => _currentStep = 5);
      _successController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<PackagesCubit, PackagesState>(
      listener: _onSubscriptionStateChanged,
      builder: (context, state) {
        final isProcessing = state is PackagesLoaded && state.isProcessing;

        return Scaffold(
          backgroundColor: scheme.surfaceContainerHighest,
          appBar: AppBar(
            title: Text(
              isProcessing
                  ? AppLocalizations.of(context)!.packages_processing
                  : _getStepTitle(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            leading: IconButton(
              onPressed: _onBackPress,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<PackagesCubit>().load(),
              ),
            ],
            elevation: 0,
          ),
          body: Stack(
            children: [
              // Background glows
              Positioned(
                top: -80,
                right: -80,
                child: _BackgroundCircleGlow(
                  color: scheme.primary.withAlpha(20),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -80,
                child: _BackgroundCircleGlow(
                  color: scheme.secondary.withAlpha(15),
                ),
              ),

              Positioned.fill(child: _buildBodyForState(state, scheme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBodyForState(PackagesState state, ColorScheme scheme) {
    if (state is PackagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PackagesError) {
      return Center(child: ClientErrorCard.fullScreen(message: state.message));
    }

    final loaded = state as PackagesLoaded;
    return loaded.isProcessing
        ? _buildActivationLoader(scheme)
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStepView(loaded, scheme),
          );
  }

  String _getStepTitle(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return AppLocalizations.of(context)!.packages_commutePackages;
      case 2:
        return AppLocalizations.of(context)!.packages_packageDetails;
      case 3:
        return AppLocalizations.of(context)!.packages_configureTravel;
      case 4:
        return AppLocalizations.of(context)!.packages_reviewSummary;
      case 5:
        return AppLocalizations.of(context)!.packages_subscribed;
      default:
        return AppLocalizations.of(context)!.packages_subscribePlan;
    }
  }

  Widget _buildCurrentStepView(PackagesLoaded loaded, ColorScheme scheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Listing(loaded, scheme);
      case 2:
        return _buildStep2Details(loaded, scheme);
      case 3:
        return _buildStep3RouteSelection(loaded, scheme);
      case 4:
        return _buildStep4Summary(loaded, scheme);
      case 5:
        return _buildStep5Success(loaded, scheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: PACKAGES LISTING SCREEN ---
  Widget _buildStep1Listing(PackagesLoaded loaded, ColorScheme scheme) {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // Category Filters Tabs
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: scheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterTab(
                AppLocalizations.of(context)!.packages_all,
                loaded,
                scheme,
              ),
              _buildFilterTab(
                AppLocalizations.of(context)!.packages_weekly,
                loaded,
                scheme,
              ),
              _buildFilterTab(
                AppLocalizations.of(context)!.packages_monthly,
                loaded,
                scheme,
              ),
              _buildFilterTab(
                AppLocalizations.of(context)!.packages_quarterly,
                loaded,
                scheme,
              ),
            ],
          ),
        ),

        // Premium List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            physics: const BouncingScrollPhysics(),
            itemCount: loaded.filteredPackages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              final package = loaded.filteredPackages[idx];
              return _buildPackageCard(package, scheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(
    String label,
    PackagesLoaded loaded,
    ColorScheme scheme,
  ) {
    final isSelected = loaded.selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () => context.read<PackagesCubit>().selectFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? scheme.onPrimary
                : scheme.onSurface.withAlpha(180),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackagePlan package, ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () {
        if (widget.bookingData == null) {
          Navigator.of(context).pushNamed(BookingRoutes.popularRoutes);
        } else {
          context.read<PackagesCubit>().selectPackage(package);
          setState(() {
            _currentStep = 2;
          });
        }
      },
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [scheme.surfaceContainerHighest, scheme.surfaceContainer]
                : [scheme.surface, scheme.surfaceContainerLow.withAlpha(100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ClientRadius.xl),
          border: Border.all(
            color: isDark
                ? scheme.outline.withAlpha(40)
                : scheme.outline.withAlpha(80),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withAlpha(isDark ? 10 : 15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ClientRadius.xl),
          child: Stack(
            children: [
              // Subtle background decoration
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withAlpha(isDark ? 15 : 8),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.secondary.withAlpha(isDark ? 15 : 8),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            package.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(24),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.packages_savePercent(
                                package.discountPercent.toInt(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Details Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniDetailColumn(
                            AppLocalizations.of(context)!.packages_duration,
                            package.durationLabel,
                          ),
                          _buildMiniDetailColumn(
                            AppLocalizations.of(context)!.packages_totalTrips,
                            AppLocalizations.of(
                              context,
                            )!.packages_ridesCount(package.tripsCount),
                          ),
                          if (widget.bookingData != null)
                            _buildMiniDetailColumn(
                              AppLocalizations.of(
                                context,
                              )!.packages_totalSavings,
                              AppLocalizations.of(context)!.packages_egpAmount(
                                package.savingsAmount.toString(),
                              ),
                              isHighlight: true,
                              color: scheme.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      // Price / Discount Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.bookingData != null &&
                              widget.hasActiveSubscription) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.packages_originalPrice(
                                    package.basePrice.toString(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.packages_egpAmount(
                                        package.startingPrice.toString(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.packages_startingPrice,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ] else ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.packages_packageDiscount,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.packages_percentOff(
                                    package.discountPercent.toInt(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDetailColumn(
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? color : null,
          ),
        ),
      ],
    );
  }

  // --- STEP 2: PACKAGE DETAILS SCREEN ---
  Widget _buildStep2Details(PackagesLoaded loaded, ColorScheme scheme) {
    if (loaded.selectedPackage == null) return const SizedBox.shrink();
    final package = loaded.selectedPackage!;

    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Package Header Info
              _buildDetailHeaderCard(package, scheme),
              const SizedBox(height: 18),

              // Benefits
              Text(
                AppLocalizations.of(context)!.packages_whatIsIncluded,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildBenefitRow(
                Icons.event_seat_rounded,
                AppLocalizations.of(context)!.packages_reservedSeatGuaranteed,
                AppLocalizations.of(context)!.packages_reservedSeatDesc,
                scheme,
              ),
              _buildBenefitRow(
                Icons.schedule_rounded,
                AppLocalizations.of(context)!.packages_flexibleTiming,
                AppLocalizations.of(context)!.packages_flexibleTimingDesc,
                scheme,
              ),
              const SizedBox(height: 20),

              // Route details card
              Text(
                AppLocalizations.of(context)!.packages_routeLimits,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Column(
                  children: [
                    _buildRowDetailText(
                      AppLocalizations.of(context)!.packages_routeScope,
                      AppLocalizations.of(context)!.packages_routeScopeDesc,
                    ),
                    const SizedBox(height: 8),
                    _buildRowDetailText(
                      AppLocalizations.of(context)!.packages_includedRides,
                      AppLocalizations.of(
                        context,
                      )!.packages_singleTripsDesc(package.tripsCount),
                    ),
                    const SizedBox(height: 8),
                    _buildRowDetailText(
                      AppLocalizations.of(context)!.packages_validityPeriod,
                      AppLocalizations.of(
                        context,
                      )!.packages_consecutiveDaysDesc(package.days),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Terms Conditions
              Text(
                AppLocalizations.of(context)!.packages_termsCancellation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Text(
                  '${AppLocalizations.of(context)!.packages_termsText1}\n'
                  '${AppLocalizations.of(context)!.packages_termsText2}\n'
                  '${AppLocalizations.of(context)!.packages_termsText3(package.tripsCount)}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: scheme.onSurface.withAlpha(200),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        // Bottom sticky button
        _buildStickyCTA(
          label: 'Continue to Payment',
          onPressed: () {
            final Map<String, dynamic> combinedArgs = {};
            if (widget.bookingData != null) {
              combinedArgs.addAll(widget.bookingData!);
            }
            combinedArgs['packageId'] = package.id;
            combinedArgs['package'] = package.name;
            combinedArgs['baseFare'] = package.startingPrice.toInt();

            Navigator.of(
              context,
            ).pushNamed('/payment-checkout', arguments: combinedArgs);
          },
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildDetailHeaderCard(PackagePlan package, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha(30),
            scheme.secondary.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  package.durationLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withAlpha(200),
              height: 1.4,
            ),
          ),
          const Divider(height: 24),
          if (widget.hasActiveSubscription)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.packages_basePrice,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.packages_egpAmount(package.basePrice.toString()),
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.packages_packageDiscount,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.packages_percentOff(package.discountPercent.toInt()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.packages_subscriptionCost,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.packages_egpAmount(package.startingPrice.toString()),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.packages_packageDiscount,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.packages_percentOff(package.discountPercent.toInt()),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String title,
    String desc,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.secondary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: scheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetailText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: ROUTE & TRAVEL SELECTION SCREEN ---
  Widget _buildStep3RouteSelection(PackagesLoaded loaded, ColorScheme scheme) {
    return Column(
      key: const ValueKey('step3'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Route Selection Dropdown
              Text(
                AppLocalizations.of(context)!.packages_selectTargetRoute,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildDropdownSelector(
                value: loaded.selectedRoute,
                items: loaded.data.routes,
                onChanged: (val) {
                  if (val == null) return;
                  context.read<PackagesCubit>().selectRoute(val);
                },
                scheme: scheme,
              ),
              const SizedBox(height: 18),

              // Pickups and destinations
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.packages_pickupPoint,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdownSelector(
                          value: loaded.selectedPickup,
                          items: loaded.data.pickupPoints,
                          onChanged: (val) {
                            if (val == null) return;
                            context.read<PackagesCubit>().selectPickup(val);
                          },
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.packages_destination,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDropdownSelector(
                          value: loaded.selectedDestination,
                          items: loaded.data.destinations,
                          onChanged: (val) {
                            if (val == null) return;
                            context.read<PackagesCubit>().selectDestination(
                              val,
                            );
                          },
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Vehicle Type Selector
              Text(
                AppLocalizations.of(context)!.packages_selectVehicleCategory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(loaded.data.vehicles.length, (idx) {
                  final vehicle = loaded.data.vehicles[idx];
                  final isSelected = loaded.selectedVehicleIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          context.read<PackagesCubit>().selectVehicle(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.only(
                          right: idx == loaded.data.vehicles.length - 1 ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary.withAlpha(20)
                              : scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? scheme.primary
                                : scheme.outline.withAlpha(45),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _iconForVehicle(vehicle.iconKey),
                              color: isSelected ? scheme.primary : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vehicle.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle.extraFee > 0
                                  ? '+EGP ${vehicle.extraFee}'
                                  : 'Free',
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? scheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Seat Selection Map Picker
              const Text(
                'Choose Your Seat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to reserve seat. Reserving more seats multiplies the package.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              _buildSeatMapGrid(loaded, scheme),

              const SizedBox(height: 30),
            ],
          ),
        ),

        // Live calculation pricing breakdown panel and sticky button
        _buildStep3CTA(loaded, scheme),
      ],
    );
  }

  IconData _iconForVehicle(String iconKey) {
    switch (iconKey) {
      case 'van':
        return Icons.airport_shuttle_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'bus':
      default:
        return Icons.directions_bus_rounded;
    }
  }

  Widget _buildDropdownSelector({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme scheme,
  }) {
    final uniqueItems = _uniqueDropdownItems(items);
    final matchingValueCount = uniqueItems
        .where((item) => item == value)
        .length;
    final safeValue = matchingValueCount == 1 ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(55)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: Text(
            uniqueItems.isEmpty ? 'No options available' : 'Select option',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          items: uniqueItems.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          onChanged: uniqueItems.isEmpty ? null : onChanged,
          isExpanded: true,
          dropdownColor: scheme.surface,
        ),
      ),
    );
  }

  List<String> _uniqueDropdownItems(List<String> items) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in items) {
      final value = item.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      result.add(value);
    }
    return result;
  }

  Widget _buildSeatMapGrid(PackagesLoaded loaded, ColorScheme scheme) {
    // 5 Rows of seats. Standard 4 seats per row (2-gap-2 layout)
    final rows = 5;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          // Frontend Driver indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Front / Driver Cabin',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: scheme.outline.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Seat Grid
          Column(
            children: List.generate(rows, (rowIdx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seat Left 1
                    _buildSeatButton((rowIdx * 4) + 1, loaded, scheme),
                    // Seat Left 2
                    _buildSeatButton((rowIdx * 4) + 2, loaded, scheme),
                    // Middle Aisle Gap
                    const SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          'Aisle',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Seat Right 1
                    _buildSeatButton((rowIdx * 4) + 3, loaded, scheme),
                    // Seat Right 2
                    _buildSeatButton((rowIdx * 4) + 4, loaded, scheme),
                  ],
                ),
              );
            }),
          ),

          // Legend
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.transparent, scheme.outline, 'Available'),
              _buildLegendItem(scheme.primary, scheme.primary, 'Selected'),
              _buildLegendItem(
                scheme.outline.withAlpha(120),
                scheme.outline.withAlpha(120),
                'Occupied',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatButton(
    int seatNo,
    PackagesLoaded loaded,
    ColorScheme scheme,
  ) {
    final isOccupied = loaded.data.occupiedSeats.contains(seatNo);

    Color bgColor = Colors.transparent;
    Color borderColor = scheme.outline;
    Color textColor = scheme.onSurface;

    if (isOccupied) {
      bgColor = scheme.outline.withAlpha(80);
      borderColor = scheme.outline.withAlpha(50);
      textColor = Colors.grey.withAlpha(150);
    }

    return GestureDetector(
      onTap: null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$seatNo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color fill, Color border, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStep3CTA(PackagesLoaded loaded, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pricing Live Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seats Selected: 1',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Text(
                          'Cost: ${AppLocalizations.of(context)!.packages_egpAmount(loaded.pricing.rawSubtotal.toString())}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Savings: ${AppLocalizations.of(context)!.packages_egpAmount(loaded.pricing.totalSavings.toString())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.packages_egpAmount(loaded.pricing.finalPrice.toString()),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClientButton(
                    label: 'Continue to Summary',
                    expand: true,
                    onPressed: () {
                      setState(() {
                        _currentStep = 4;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 4: PACKAGE BOOKING SUMMARY SCREEN ---
  Widget _buildStep4Summary(PackagesLoaded loaded, ColorScheme scheme) {
    if (loaded.selectedPackage == null) return const SizedBox.shrink();
    final package = loaded.selectedPackage!;

    return Column(
      key: const ValueKey('step4'),
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Booking Review Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.packages_reviewSummary,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            package.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSummaryDetailRow(
                      'Target Route',
                      loaded.selectedRoute,
                    ),
                    _buildSummaryDetailRow(
                      'Pickup Stop',
                      loaded.selectedPickup,
                    ),
                    _buildSummaryDetailRow(
                      'Destination Stop',
                      loaded.selectedDestination,
                    ),
                    _buildSummaryDetailRow(
                      'Vehicle Category',
                      loaded.selectedVehicle.name,
                    ),
                    _buildSummaryDetailRow('Selected Seats', '1'),
                    _buildSummaryDetailRow(
                      'Trips Allocated',
                      '${package.tripsCount} Rides',
                    ),
                    _buildSummaryDetailRow(
                      'Package Validity',
                      '${package.days} Days',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Final pricing card
              Text(
                AppLocalizations.of(context)!.packages_billingDetails,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientColors.borderFor(context)),
                ),
                child: Column(
                  children: [
                    _buildPricingRow(
                      AppLocalizations.of(context)!.packages_basePrice,
                      AppLocalizations.of(context)!.packages_egpAmount(
                        loaded.pricing.rawSubtotal.toString(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPricingRow(
                      AppLocalizations.of(context)!.packages_packageDiscount,
                      '-${AppLocalizations.of(context)!.packages_egpAmount(loaded.pricing.discountValue.toString())}',
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildPricingRow(
                      AppLocalizations.of(context)!.packages_totalSavings,
                      AppLocalizations.of(context)!.packages_egpAmount(
                        loaded.pricing.totalSavings.toString(),
                      ),
                      color: scheme.secondary,
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.packages_subscriptionCost,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.packages_egpAmount(
                            loaded.pricing.finalPrice.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Terms Acceptance Checkbox
              Row(
                children: [
                  Checkbox(
                    value: loaded.agreeTerms,
                    onChanged: (val) => context
                        .read<PackagesCubit>()
                        .setAgreeTerms(val ?? false),
                    activeColor: scheme.primary,
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the recurring commuter subscription terms and conditions policy.',
                      style: TextStyle(fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),

        // Confirm Action sticky bottom panel
        _buildStickyCTA(
          label: 'Submit for Payment Review',
          onPressed: loaded.agreeTerms
              ? _activateSubscription
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please agree to the terms before submitting.',
                      ),
                    ),
                  );
                },
          scheme: scheme,
        ),
      ],
    );
  }

  Widget _buildSummaryDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- STEP 5: SUBSCRIPTION SUCCESS SCREEN ---
  Widget _buildStep5Success(PackagesLoaded loaded, ColorScheme scheme) {
    if (loaded.selectedPackage == null) return const SizedBox.shrink();
    final package = loaded.selectedPackage!;

    return SingleChildScrollView(
      key: const ValueKey('step5'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          // Animated checkmark and confetti
          Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _successController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withAlpha(45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(120, 120),
                painter: _SuccessConfettiPainter(progress: _successController),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Request Submitted',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your subscription is pending payment confirmation. It will become usable only after finance approval.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Subscription ticket receipt summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subscription Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final id = loaded.subscriptionId ?? '';
                        Clipboard.setData(ClipboardData(text: id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ID: $id')),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            loaded.subscriptionId ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildReceiptRow('Commuter Package', package.name),
                _buildReceiptRow('Duration Limit', package.durationLabel),
                _buildReceiptRow(
                  'Total Trips Scope',
                  '${package.tripsCount} Rides',
                ),
                _buildReceiptRow('Selected Seats', '1'),
                _buildReceiptRow('Travel Route', loaded.selectedRoute),
                _buildReceiptRow('Pickup Stop', loaded.selectedPickup),
                _buildReceiptRow(
                  'Destination Stop',
                  loaded.selectedDestination,
                ),
                _buildReceiptRow(
                  'Vehicle Standard',
                  loaded.selectedVehicle.name,
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'EGP ${loaded.pricing.finalPrice}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Action button back to home
          Row(
            children: [
              Expanded(
                child: ClientButton(
                  label: 'Back to Home',
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- GENERAL WIDGETS ---

  Widget _buildStickyCTA({
    required String label,
    required VoidCallback onPressed,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(55))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ClientButton(
                label: label,
                expand: true,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationLoader(ColorScheme scheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Activating Package...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirming commuter credentials and reserving seats.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DECORATIVE BACKGROUND PAINT GLOW ---
class _BackgroundCircleGlow extends StatelessWidget {
  final Color color;

  const _BackgroundCircleGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

// --- SUCCESS CONFETTI PARTICLES PAINTER ---
class _SuccessConfettiPainter extends CustomPainter {
  final Animation<double> progress;

  _SuccessConfettiPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0) return;

    final random = math.Random(123);
    final center = Offset(size.width / 2, size.height / 2);
    final count = 30;
    final maxRadius = size.width * 0.75;

    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance =
          progress.value * maxRadius * (0.35 + random.nextDouble() * 0.65);

      final offset = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      final sizeFactor = (1.0 - progress.value) * (4 + random.nextDouble() * 5);
      final color = _getConfettiColor(random.nextInt(4));

      final paint = Paint()
        ..color = color.withAlpha(
          ((1.0 - progress.value).clamp(0.0, 1.0) * 255).toInt(),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, sizeFactor, paint);
    }
  }

  Color _getConfettiColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.teal;
      case 2:
        return Colors.amber;
      default:
        return Colors.pink;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
