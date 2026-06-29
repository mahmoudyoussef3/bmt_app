import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_document.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_documents/presentation/cubit/fleet_documents_state.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_documents/presentation/widgets/fleet_documents_table.dart';
import 'package:bmt_app/apps/dashboard/modules/fleet/fleet_documents/presentation/widgets/fleet_documents_card_list.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class FleetDocumentsScreen extends StatefulWidget {
  const FleetDocumentsScreen({super.key});

  @override
  State<FleetDocumentsScreen> createState() => _FleetDocumentsScreenState();
}

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
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FleetDocumentsError) {
          return Center(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  FilledButton(
                    onPressed: () => context.read<FleetDocumentsCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
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
                    );
                  } else {
                    return FleetDocumentsTable(
                      documents: sorted,
                      page: _page,
                      pageSize: _pageSize,
                      onPageChanged: (newPage) =>
                          setState(() => _page = newPage),
                      onDelete: _deleteDocument,
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
