import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_state.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_documents_table.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/widgets/fleet_documents_card_list.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class FleetDocumentsScreen extends StatefulWidget {
  const FleetDocumentsScreen({super.key});

  @override
  State<FleetDocumentsScreen> createState() => _FleetDocumentsScreenState();
}

/// Longest edge the document preview may take. Beyond this a scanned licence
/// stops gaining legibility and starts costing the operator the page behind it.
const double _previewMaxSide = 800;

class _FleetDocumentsScreenState extends State<FleetDocumentsScreen> {
  int _page = 0;
  final int _pageSize = 8;
  bool _sortAscending = true;

  List<FleetDocument> _sortDocs(List<FleetDocument> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final cmp = a.expiryDate.compareTo(b.expiryDate);
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FleetDocumentsCubit, FleetDocumentsState>(
      builder: (context, state) {
        if (state is FleetDocumentsLoading) {
          return const DashboardLoading(showHeader: false, scrollable: false);
        }

        if (state is FleetDocumentsError) {
          return DashboardErrorState(
            message: state.message,
            onRetry: () => context.read<FleetDocumentsCubit>().load(),
          );
        }

        if (state is FleetDocumentsLoaded) {
          final cubit = context.read<FleetDocumentsCubit>();
          final sorted = _sortDocs(state.filteredDocuments);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(context, state, cubit),
              const SizedBox(height: AppSpacing.medium),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  if (isMobile) {
                    return FleetDocumentsCardList(
                      documents: sorted,
                      page: _page,
                      pageSize: _pageSize,
                      onPageChanged: (newPage) =>
                          setState(() => _page = newPage),
                      onDelete: _deleteDocument,
                      onView: _viewDocument,
                    );
                  } else {
                    return FleetDocumentsTable(
                      documents: sorted,
                      page: _page,
                      pageSize: _pageSize,
                      onPageChanged: (newPage) =>
                          setState(() => _page = newPage),
                      onDelete: _deleteDocument,
                      onView: _viewDocument,
                    );
                  }
                },
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _viewDocument(FleetDocument document) {
    if (document.fileUrl.isEmpty) {
      AppSnackbar.error(context, 'لا يوجد ملف مرفق بهذه الوثيقة');
      return;
    }

    final isPdf = document.fileUrl.toLowerCase().contains('.pdf');
    if (isPdf) {
      // Previewing a PDF in-app costs a rendering plugin for a document the
      // operator opens once and reads in their own viewer anyway.
      launchUrl(
        Uri.parse(document.fileUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.large),
        // Bounded by the window rather than sized to a fixed 800×800 box: a
        // licence photo opened on a 1366×768 laptop was taller than the viewport
        // and the dialog overflowed instead of shrinking.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _previewMaxSide,
            maxHeight: _previewMaxSide,
            minWidth: math.min(
              _previewMaxSide,
              MediaQuery.sizeOf(ctx).width * 0.6,
            ),
            minHeight: math.min(
              _previewMaxSide,
              MediaQuery.sizeOf(ctx).height * 0.6,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  document.fileUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total = loadingProgress.expectedTotalBytes;
                    final current = loadingProgress.cumulativeBytesLoaded;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: total != null ? current / total : null,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'جاري تحميل الوثيقة...',
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 64,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.large),
                          const Text(
                            'عذراً، لم نتمكن من عرض الملف أو أنه ليس صورة.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          FilledButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(document.fileUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('فتح في تطبيق خارجي'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.small,
                end: AppSpacing.small,
                child: IconButton.filled(
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      ctx,
                    ).colorScheme.surface.withAlpha(200),
                    foregroundColor: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDocument(FleetDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الوثيقة نهائياً'),
        content: Text(
          'سيتم حذف وثيقة "${document.type.label}" من قاعدة البيانات. لا يمكن التراجع عن هذا الإجراء.',
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

    await context.read<FleetDocumentsCubit>().deleteDocument(
      documentId: document.id,
      isDriver: _isDriverDocument(document),
    );
  }

  bool _isDriverDocument(FleetDocument document) {
    return switch (document.type) {
      FleetDocumentType.driverLicense ||
      FleetDocumentType.nationalIdFront ||
      FleetDocumentType.nationalIdBack ||
      FleetDocumentType.criminalRecord ||
      FleetDocumentType.employmentContract => true,
      FleetDocumentType.vehicleLicense ||
      FleetDocumentType.insurance ||
      FleetDocumentType.inspection ||
      FleetDocumentType.other => false,
    };
  }

  Widget _buildToolbar(
    BuildContext context,
    FleetDocumentsLoaded state,
    FleetDocumentsCubit cubit,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'البحث باسم الموظف أو رقم الرخصة أو الوثيقة...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                scheme.surfaceContainerHighest.withAlpha(90),
              ),
              onChanged: cubit.search,
              leading: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          DropdownButton<String>(
            value: state.filter,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.filter_list_rounded),
            items: const [
              DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
              DropdownMenuItem(value: 'سليم', child: Text('صالح وساري')),
              DropdownMenuItem(
                value: 'ينتهي قريباً',
                child: Text('ينتهي قريباً'),
              ),
              DropdownMenuItem(value: 'منتهي', child: Text('منتهي الصلاحية')),
            ],
            onChanged: (val) {
              if (val != null) {
                cubit.filter(val);
                setState(() => _page = 0);
              }
            },
          ),
          IconButton(
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
            tooltip: 'ترتيب حسب تاريخ الانتهاء',
          ),
        ],
      ),
    );
  }
}
