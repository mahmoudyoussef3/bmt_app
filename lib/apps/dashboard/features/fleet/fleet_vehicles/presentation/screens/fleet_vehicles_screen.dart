import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_toolbar.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/models/fleet_queue.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicles_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/utils/fleet_pending_docs_uploader.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class FleetVehiclesScreen extends StatefulWidget {
  const FleetVehiclesScreen({
    super.key,
    this.onViewStateChanged,
    this.focusRequest,
    this.onFocusResolved,
    this.queueRequest,
  });

  /// A queue this tab should open on, handed down by a KPI tile on the module
  /// header above it. A fresh [FleetVehicleQueueRequest] identifies each
  /// request even when it names the same queue twice — see the type's doc
  /// comment for why a plain enum value cannot.
  final FleetVehicleQueueRequest? queueRequest;

  final void Function(bool isList)? onViewStateChanged;

  /// When set, the matching vehicle's detail dialog opens automatically once
  /// the list has loaded — the deep link a "Needs Attention" row uses to jump
  /// straight to the vehicle it flagged.
  ///
  /// A fresh [FleetFocusRequest] instance identifies each request, even when
  /// the id repeats (open a vehicle, close it, tap the same "Needs Attention"
  /// row again) — see the type's doc comment for why a plain `String?` id
  /// can't do this.
  final FleetFocusRequest? focusRequest;

  /// Called once this screen has either opened [focusRequest]'s dialog or
  /// given up (vehicle not found, or the list failed to load), so the parent
  /// can dismiss whatever "opening..." feedback it showed on the tap that
  /// created the request.
  final VoidCallback? onFocusResolved;

  @override
  State<FleetVehiclesScreen> createState() => _FleetVehiclesScreenState();
}

class _FleetVehiclesScreenState extends State<FleetVehiclesScreen> {
  int _page = 0;
  final int _pageSize = 12;
  FleetVehicleSort _sort = FleetVehicleSort.code;
  bool _sortAscending = true;

  /// The queue strip's selection — what a bus is *doing*.
  FleetVehicleQueue _queue = FleetVehicleQueue.all;

  /// The filter fold's selection — what state its record is in. A separate
  /// axis on purpose: the two can legitimately disagree.
  FleetVehicleStatus? _recordStatus;

  String? _pendingFocusId;

  @override
  void initState() {
    super.initState();
    _pendingFocusId = widget.focusRequest?.id;
    _applyQueueRequest(widget.queueRequest);
  }

  @override
  void didUpdateWidget(covariant FleetVehiclesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusRequest != null &&
        widget.focusRequest != oldWidget.focusRequest) {
      _pendingFocusId = widget.focusRequest!.id;
    }
    if (widget.queueRequest != null &&
        widget.queueRequest != oldWidget.queueRequest) {
      _applyQueueRequest(widget.queueRequest);
    }
  }

  /// Opens the queue a KPI tile asked for. Called from [initState] as well as
  /// [didUpdateWidget], because a tile tapped while the *other* tab was active
  /// builds this one for the first time with the request already in hand.
  void _applyQueueRequest(FleetVehicleQueueRequest? request) {
    if (request == null) return;
    _queue = request.queue ?? FleetVehicleQueue.all;
    _recordStatus = request.recordStatus;
    _page = 0;
  }

  List<FleetVehicle> _sortVehicles(List<FleetVehicle> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = switch (_sort) {
        FleetVehicleSort.seats => a.seatsCount.compareTo(b.seatsCount),
        FleetVehicleSort.modelYear => a.modelYear.compareTo(b.modelYear),
        FleetVehicleSort.status => a.status.label.compareTo(b.status.label),
        FleetVehicleSort.code => a.vehicleNumber.compareTo(b.vehicleNumber),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<FleetVehicle> _applyOperationsFilter(
    List<FleetVehicle> vehicles,
    FleetWorkspace workspace,
  ) {
    return vehicles
        .where(
          (vehicle) =>
              _queue.matches(vehicle, workspace) &&
              (_recordStatus == null || vehicle.status == _recordStatus),
        )
        .toList();
  }

  /// Sets the ordering, flipping the direction when handed the key already in
  /// force — which is what tapping a sorted column header means.
  void _applySort(FleetVehicleSort field) {
    setState(() {
      if (_sort == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sort = field;
        _sortAscending = true;
      }
      _page = 0;
    });
  }

  void _openVehicle(
    BuildContext context,
    FleetVehiclesLoaded state,
    FleetWorkspace workspace,
    FleetVehicle vehicle,
    FleetVehiclesCubit cubit,
    bool isDesktop,
  ) {
    final docsCubit = context.read<FleetDocumentsCubit>();
    final overviewCubit = context.read<FleetOverviewCubit>();

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: docsCubit),
            BlocProvider.value(value: overviewCubit),
          ],
          child: Dialog(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            child: SizedBox(
              width: 800,
              height: 800,
              child: _detailsView(
                context,
                state,
                workspace,
                vehicle,
                cubit,
                docsCubit,
                onBack: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: docsCubit),
            BlocProvider.value(value: overviewCubit),
          ],
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            builder: (context, controller) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.medium,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: _detailsView(
                      context,
                      state,
                      workspace,
                      vehicle,
                      cubit,
                      docsCubit,
                      onBack: () => Navigator.pop(context),
                      scrollController: controller,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = context.watch<FleetOverviewCubit>().state;
    if (overviewState is! FleetOverviewLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final workspace = overviewState.workspace;

    return BlocBuilder<FleetVehiclesCubit, FleetVehiclesState>(
      builder: (context, state) {
        if (state is FleetVehiclesLoading) {
          return const DashboardLoading(scrollable: false);
        }

        if (state is FleetVehiclesError) {
          if (_pendingFocusId != null) {
            // The tab this focus request jumped to failed to load — nothing
            // to open. Give up on the request rather than leaving the
            // parent's "opening..." indicator stuck forever.
            _pendingFocusId = null;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onFocusResolved?.call(),
            );
          }
          return DashboardErrorState(
            title: 'تعذّر تحميل المركبات',
            message: state.message,
            onRetry: () => context.read<FleetVehiclesCubit>().load(),
          );
        }

        if (state is FleetVehiclesLoaded) {
          final cubit = context.read<FleetVehiclesCubit>();
          final sorted = _sortVehicles(
            _applyOperationsFilter(state.filteredVehicles, workspace),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 980;

              final focusId = _pendingFocusId;
              if (focusId != null) {
                final target = state.vehicles.where((v) => v.id == focusId);
                _pendingFocusId = null;
                if (target.isNotEmpty) {
                  final vehicle = target.first;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onFocusResolved?.call();
                    if (!mounted) return;
                    _openVehicle(
                      context,
                      state,
                      workspace,
                      vehicle,
                      cubit,
                      isDesktop,
                    );
                  });
                } else {
                  // Loaded, but the flagged vehicle isn't in this list
                  // (deleted, archived, ...) — stop waiting instead of
                  // leaving the parent's "opening..." indicator stuck
                  // forever.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => widget.onFocusResolved?.call(),
                  );
                }
              }

              final toolbar = FleetVehiclesToolbar(
                vehicles: state.vehicles,
                workspace: workspace,
                queue: _queue,
                recordStatus: _recordStatus,
                searchQuery: state.searchQuery,
                sort: _sort,
                sortAscending: _sortAscending,
                onQueueChanged: (queue) {
                  setState(() {
                    _queue = queue;
                    _page = 0;
                  });
                },
                onRecordStatusChanged: (status) {
                  setState(() {
                    _recordStatus = status;
                    _page = 0;
                  });
                },
                onSearch: (term) {
                  cubit.search(term);
                  setState(() => _page = 0);
                },
                onSort: _applySort,
                onClearFilters: () {
                  cubit.search('');
                  setState(() {
                    _recordStatus = null;
                    _page = 0;
                  });
                },
                selectedCount: state.selectedIds.length,
                onSuspendSelected: state.selectedIds.isEmpty
                    ? null
                    : () async {
                        final scheme = Theme.of(context).colorScheme;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('إيقاف تشغيل المركبات'),
                            content: Text(
                              'هل أنت متأكد من إيقاف ${state.selectedIds.length} من المركبات المحددة؟',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.error,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('إيقاف مؤقت'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await cubit.bulkSuspendVehicles();
                          if (context.mounted) {
                            await context
                                .read<FleetOverviewCubit>()
                                .loadWorkspace();
                          }
                        }
                      },
              );

              final browsing = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: AppSpacing.medium),
                  // The primary action lives on the results header, not in a
                  // lone right-aligned button above the list and not in the
                  // page header: «إضافة مركبة» needs this tab's cubit and its
                  // documents cubit, which only exist below the module header.
                  DashboardResultsHeader(
                    icon: DashboardIcons.fleet,
                    title: 'قائمة المركبات',
                    subtitle: _rangeLabel(sorted.length),
                    actions: [
                      FilledButton.icon(
                        onPressed: () => _showVehicleForm(
                          context,
                          cubit,
                          workspace,
                          null,
                          context.read<FleetDocumentsCubit>(),
                        ),
                        icon: const Icon(DashboardIcons.add),
                        label: const Text('إضافة مركبة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildListBody(
                    context,
                    state,
                    sorted,
                    workspace,
                    cubit,
                    isDesktop,
                  ),
                ],
              );

              return constraints.maxHeight.isFinite
                  ? SingleChildScrollView(child: browsing)
                  : browsing;
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Reactive to [cubit] rather than a one-time snapshot of [state]: a
  /// `showDialog` builder only runs once, so without this, saving an edit
  /// from the nested form dialog (which reloads [cubit] in the background)
  /// left the still-open details dialog showing the pre-edit vehicle until it
  /// was closed and reopened — or the whole screen refreshed.
  Widget _detailsView(
    BuildContext context,
    FleetVehiclesLoaded state,
    FleetWorkspace workspace,
    FleetVehicle vehicle,
    FleetVehiclesCubit cubit,
    FleetDocumentsCubit docsCubit, {
    required VoidCallback onBack,
    ScrollController? scrollController,
  }) {
    return BlocBuilder<FleetVehiclesCubit, FleetVehiclesState>(
      bloc: cubit,
      builder: (context, liveState) {
        final vehicles = liveState is FleetVehiclesLoaded
            ? liveState.vehicles
            : state.vehicles;
        final updatedVehicle = vehicles.firstWhere(
          (v) => v.id == vehicle.id,
          orElse: () => vehicle,
        );
        return FleetVehicleDetailsView(
          vehicle: updatedVehicle,
          workspace: workspace,
          onBack: onBack,
          onEdit: () => _showVehicleForm(
            context,
            cubit,
            workspace,
            updatedVehicle,
            docsCubit,
          ),
          scrollController: scrollController,
        );
      },
    );
  }

  /// "عرض ١–١٢ من ٤٥" — the same range strip every list module puts above its
  /// rows.
  String _rangeLabel(int total) {
    if (total == 0) return 'لا توجد نتائج';
    final first = _page * _pageSize + 1;
    final last = ((_page + 1) * _pageSize).clamp(0, total);
    return 'عرض ${FleetFormat.count(first)}–${FleetFormat.count(last)} '
        'من ${FleetFormat.count(total)}';
  }

  Widget _buildListBody(
    BuildContext context,
    FleetVehiclesLoaded state,
    List<FleetVehicle> sorted,
    FleetWorkspace workspace,
    FleetVehiclesCubit cubit,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards =
            !isDesktop || constraints.maxWidth < kDashboardTableBreakpoint;
        if (useCards) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FleetVehiclesCardList(
                vehicles: sorted,
                workspace: workspace,
                onViewDetails: (v) => _openVehicle(
                  context,
                  state,
                  workspace,
                  v,
                  cubit,
                  isDesktop,
                ),
                onEdit: (v) => _showVehicleForm(
                  context,
                  cubit,
                  workspace,
                  v,
                  context.read<FleetDocumentsCubit>(),
                ),
                onDelete: _confirmDeleteVehicle,
                page: _page,
                pageSize: _pageSize,
                onPageChanged: (newPage) => setState(() => _page = newPage),
              ),
            ],
          );
        }

        return FleetVehiclesTable(
          vehicles: sorted,
          workspace: workspace,
          sort: _sort,
          sortAscending: _sortAscending,
          onSort: _applySort,
          onView: (v) =>
              _openVehicle(context, state, workspace, v, cubit, isDesktop),
          onEdit: (v) => _showVehicleForm(
            context,
            cubit,
            workspace,
            v,
            context.read<FleetDocumentsCubit>(),
          ),
          selectedIds: state.selectedIds,
          page: _page,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
        );
      },
    );
  }

  void _showVehicleForm(
    BuildContext context,
    FleetVehiclesCubit cubit,
    FleetWorkspace workspace,
    FleetVehicle? vehicle,
    FleetDocumentsCubit docsCubit,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return FleetVehicleFormView(
          vehicle: vehicle,
          workspace: workspace,
          onBack: () => Navigator.pop(dialogContext),
          onUploadFile: cubit.uploadVehicleFile,
          onSave: (savedVehicle, pendingDocs) async {
            final overviewCubit = context.read<FleetOverviewCubit>();
            final isEdit = savedVehicle.id.isNotEmpty;
            try {
              final saved = await cubit.saveVehicle(savedVehicle);

              final failed = await FleetPendingDocsUploader.upload(
                docsCubit,
                ownerId: saved.id,
                isDriver: false,
                docs: pendingDocs,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);

              if (context.mounted) {
                if (failed.isEmpty) {
                  AppSnackbar.success(
                    context,
                    isEdit
                        ? 'تم حفظ تعديلات المركبة بنجاح'
                        : 'تمت إضافة المركبة بنجاح',
                  );
                } else {
                  AppSnackbar.warning(
                    context,
                    'تم حفظ المركبة، لكن تعذّر رفع: ${failed.join('، ')}',
                  );
                }
              }

              await overviewCubit.loadWorkspace();
              return null;
            } catch (error) {
              return error.toString().replaceAll('Exception: ', '');
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteVehicle(FleetVehicle vehicle) async {
    final vehiclesCubit = context.read<FleetVehiclesCubit>();
    final overviewCubit = context.read<FleetOverviewCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المركبة نهائياً'),
        content: Text(
          'سيتم حذف المركبة "${vehicle.vehicleNumber}" من قاعدة البيانات مع وثائقها '
          'وتعييناتها. لا يمكن التراجع عن هذا الإجراء.\n\n'
          'الحذف متاح فقط للمركبات التي لم تُسجَّل عليها أي رحلة. إذا كانت المركبة '
          'قد عملت من قبل، استخدم "أرشفة" بدلاً من الحذف حتى لا يفقد سجل الرحلات '
          'السابقة المركبة التي نفّذتها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await vehiclesCubit.deleteVehicle(vehicle.id);
    if (!mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف المركبة "${vehicle.vehicleNumber}"');
      await overviewCubit.loadWorkspace();
    } else {
      AppSnackbar.error(context, error);
    }
  }
}
