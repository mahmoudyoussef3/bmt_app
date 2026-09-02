import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_toolbar.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/models/fleet_queue.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/widgets/fleet_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_drivers_card_list.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/utils/fleet_pending_docs_uploader.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/overview/presentation/cubit/fleet_overview_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/async_state_view.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class FleetDriversScreen extends StatefulWidget {
  final ValueChanged<bool>? onViewStateChanged;

  /// When set, the matching driver's detail dialog opens automatically once
  /// the list has loaded — the deep link a "Needs Attention" row uses to jump
  /// straight to the driver it flagged.
  ///
  /// A fresh [FleetFocusRequest] instance identifies each request, even when
  /// the id repeats (open a driver, close it, tap the same "Needs Attention"
  /// row again) — see the type's doc comment for why a plain `String?` id
  /// can't do this.
  final FleetFocusRequest? focusRequest;

  /// Called once this screen has either opened [focusRequest]'s dialog or
  /// given up (driver not found, or the list failed to load), so the parent
  /// can dismiss whatever "opening..." feedback it showed on the tap that
  /// created the request.
  final VoidCallback? onFocusResolved;

  const FleetDriversScreen({
    super.key,
    this.onViewStateChanged,
    this.focusRequest,
    this.onFocusResolved,
    this.queueRequest,
  });

  /// A queue this tab should open on, handed down by a KPI tile on the module
  /// header above it. A fresh [FleetDriverQueueRequest] identifies each request
  /// even when it names the same queue twice — see the type's doc comment for
  /// why a plain enum value cannot.
  final FleetDriverQueueRequest? queueRequest;

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  int _page = 0;
  final int _pageSize = 12;
  FleetDriverSort _sort = FleetDriverSort.name;
  bool _sortAscending = true;

  /// The queue strip's selection — whether this driver can be put on a bus.
  FleetDriverQueue _queue = FleetDriverQueue.all;

  /// The filter fold's selection — what state their file is in. A separate
  /// axis on purpose.
  FleetDriverStatus? _recordStatus;

  String? _pendingFocusId;

  @override
  void initState() {
    super.initState();
    _pendingFocusId = widget.focusRequest?.id;
    _applyQueueRequest(widget.queueRequest);
  }

  @override
  void didUpdateWidget(covariant FleetDriversScreen oldWidget) {
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
  void _applyQueueRequest(FleetDriverQueueRequest? request) {
    if (request == null) return;
    _queue = request.queue ?? FleetDriverQueue.all;
    _recordStatus = request.recordStatus;
    _page = 0;
  }

  List<FleetDriver> _sortDrivers(List<FleetDriver> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = switch (_sort) {
        FleetDriverSort.licenseExpiry => a.licenseExpiry.compareTo(
          b.licenseExpiry,
        ),
        FleetDriverSort.name => a.name.compareTo(b.name),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  List<FleetDriver> _applyOperationsFilter(
    List<FleetDriver> drivers,
    FleetWorkspace workspace,
  ) {
    return drivers
        .where(
          (driver) =>
              _queue.matches(driver, workspace) &&
              (_recordStatus == null || driver.status == _recordStatus),
        )
        .toList();
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

  /// Sets the ordering, flipping the direction when handed the key already in
  /// force — which is what tapping a sorted column header means.
  void _applySort(FleetDriverSort field) {
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

  void _openDriver(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
    FleetDriver driver,
    FleetDriversCubit cubit,
    bool isDesktop,
  ) {
    final docsCubit = context.read<FleetDocumentsCubit>();

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => BlocProvider.value(
          value: docsCubit,
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
                driver,
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
        builder: (context) => BlocProvider.value(
          value: docsCubit,
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
                      driver,
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

    return BlocBuilder<FleetDriversCubit, FleetDriversState>(
      builder: (context, state) {
        final status = switch (state) {
          FleetDriversLoading() => AsyncViewStatus.loading,
          FleetDriversError() => AsyncViewStatus.error,
          FleetDriversLoaded() => AsyncViewStatus.data,
        };

        if (state is FleetDriversError && _pendingFocusId != null) {
          // The tab this focus request jumped to failed to load — nothing to
          // open. Give up on the request rather than leaving the parent's
          // "opening..." indicator stuck forever.
          _pendingFocusId = null;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => widget.onFocusResolved?.call(),
          );
        }

        return AsyncStateView(
          status: status,
          loadingPlaceholder: const DashboardLoading(scrollable: false),
          errorMessage: state is FleetDriversError
              ? state.message
              : 'تعذّر تحميل بيانات السائقين',
          onRetry: () => context.read<FleetDriversCubit>().load(),
          child: state is FleetDriversLoaded
              ? _buildLoaded(context, state, workspace)
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
  ) {
    final cubit = context.read<FleetDriversCubit>();

    final sorted = _sortDrivers(
      _applyOperationsFilter(state.filteredDrivers, workspace),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppLayout.breakpointTablet;

        final focusId = _pendingFocusId;
        if (focusId != null) {
          final target = state.drivers.where((d) => d.id == focusId);
          _pendingFocusId = null;
          if (target.isNotEmpty) {
            final driver = target.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onFocusResolved?.call();
              if (!mounted) return;
              _openDriver(context, state, workspace, driver, cubit, isDesktop);
            });
          } else {
            // Loaded, but the flagged driver isn't in this list (deleted,
            // archived, ...) — stop waiting instead of leaving the parent's
            // "opening..." indicator stuck forever.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onFocusResolved?.call(),
            );
          }
        }

        final toolbar = FleetDriversToolbar(
          drivers: state.drivers,
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
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('أرشفة السائقين'),
                      content: Text(
                        'هل أنت متأكد من أرشفة ${state.selectedIds.length} من السائقين المحددين؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('تأكيد الأرشفة'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await cubit.bulkArchiveDrivers();
                    if (context.mounted) {
                      await context.read<FleetOverviewCubit>().loadWorkspace();
                    }
                  }
                },
        );

        final browsing = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            const SizedBox(height: AppSpacing.medium),
            // The primary action lives on the results header, not in a lone
            // right-aligned button above the list and not in the page header:
            // «إضافة سائق» needs this tab's cubit and its documents cubit,
            // which only exist below the module header.
            DashboardResultsHeader(
              icon: DashboardIcons.captains,
              title: 'قائمة السائقين',
              subtitle: _rangeLabel(sorted.length),
              actions: [
                FilledButton.icon(
                  onPressed: () => _showDriverForm(
                    context,
                    cubit,
                    workspace,
                    null,
                    context.read<FleetDocumentsCubit>(),
                  ),
                  icon: const Icon(DashboardIcons.add),
                  label: const Text('إضافة سائق'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _buildListBody(context, state, sorted, workspace, cubit, isDesktop),
          ],
        );

        return constraints.maxHeight.isFinite
            ? SingleChildScrollView(child: browsing)
            : browsing;
      },
    );
  }

  /// Reactive to [cubit] rather than a one-time snapshot of [state]: a
  /// `showDialog` builder only runs once, so without this, saving an edit
  /// from the nested form dialog (which reloads [cubit] in the background)
  /// left the still-open details dialog showing the pre-edit driver until it
  /// was closed and reopened — or the whole screen refreshed.
  Widget _detailsView(
    BuildContext context,
    FleetDriversLoaded state,
    FleetWorkspace workspace,
    FleetDriver driver,
    FleetDriversCubit cubit,
    FleetDocumentsCubit docsCubit, {
    required VoidCallback onBack,
    ScrollController? scrollController,
  }) {
    return BlocBuilder<FleetDriversCubit, FleetDriversState>(
      bloc: cubit,
      builder: (context, liveState) {
        final drivers = liveState is FleetDriversLoaded
            ? liveState.drivers
            : state.drivers;
        final updatedDriver = drivers.firstWhere(
          (d) => d.id == driver.id,
          orElse: () => driver,
        );
        return FleetDriverDetailsView(
          driver: updatedDriver,
          workspace: workspace,
          onBack: onBack,
          onEdit: () => _showDriverForm(
            context,
            cubit,
            workspace,
            updatedDriver,
            docsCubit,
          ),
          scrollController: scrollController,
        );
      },
    );
  }

  Widget _buildListBody(
    BuildContext context,
    FleetDriversLoaded state,
    List<FleetDriver> sorted,
    FleetWorkspace workspace,
    FleetDriversCubit cubit,
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
              FleetDriversCardList(
                drivers: sorted,
                workspace: workspace,
                onViewDetails: (d) =>
                    _openDriver(context, state, workspace, d, cubit, isDesktop),
                onEdit: (d) => _showDriverForm(
                  context,
                  cubit,
                  workspace,
                  d,
                  context.read<FleetDocumentsCubit>(),
                ),
                onDelete: _confirmDeleteDriver,
                page: _page,
                pageSize: _pageSize,
                onPageChanged: (newPage) => setState(() => _page = newPage),
              ),
            ],
          );
        }
        return FleetDriversTable(
          drivers: sorted,
          workspace: workspace,
          onView: (d) =>
              _openDriver(context, state, workspace, d, cubit, isDesktop),
          onEdit: (d) => _showDriverForm(
            context,
            cubit,
            workspace,
            d,
            context.read<FleetDocumentsCubit>(),
          ),
          selectedIds: state.selectedIds,
          selectedId: null,
          page: _page,
          pageSize: _pageSize,
          onPageChanged: (newPage) => setState(() => _page = newPage),
          sort: _sort,
          sortAscending: _sortAscending,
          onSort: _applySort,
        );
      },
    );
  }

  void _showDriverForm(
    BuildContext context,
    FleetDriversCubit cubit,
    FleetWorkspace workspace,
    FleetDriver? driver,
    FleetDocumentsCubit docsCubit,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return FleetDriverFormView(
          driver: driver,
          workspace: workspace,
          onBack: () => Navigator.pop(dialogContext),
          onSave: (savedDriver, pendingDocs) async {
            final overviewCubit = context.read<FleetOverviewCubit>();
            final isEdit = savedDriver.id.isNotEmpty;
            try {
              final saved = await cubit.saveDriver(savedDriver);

              final failed = await FleetPendingDocsUploader.upload(
                docsCubit,
                ownerId: saved.id,
                isDriver: true,
                docs: pendingDocs,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);

              if (context.mounted) {
                if (failed.isEmpty) {
                  AppSnackbar.success(
                    context,
                    isEdit
                        ? 'تم حفظ تعديلات السائق بنجاح'
                        : 'تمت إضافة السائق بنجاح',
                  );
                } else {
                  AppSnackbar.warning(
                    context,
                    'تم حفظ السائق، لكن تعذّر رفع: ${failed.join('، ')}',
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

  Future<void> _confirmDeleteDriver(FleetDriver driver) async {
    final driversCubit = context.read<FleetDriversCubit>();
    final overviewCubit = context.read<FleetOverviewCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السائق نهائياً'),
        content: Text(
          'سيتم حذف السائق "${driver.name}" من قاعدة البيانات مع وثائقه وتعييناته. لا يمكن التراجع عن هذا الإجراء.',
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
    final error = await driversCubit.deleteDriver(driver.id);
    if (!mounted) return;
    if (error == null) {
      AppSnackbar.success(context, 'تم حذف السائق "${driver.name}"');
      await overviewCubit.loadWorkspace();
    } else {
      AppSnackbar.error(context, error);
    }
  }
}
