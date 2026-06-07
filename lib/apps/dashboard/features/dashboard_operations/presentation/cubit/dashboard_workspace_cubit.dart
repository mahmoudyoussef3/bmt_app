import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_workspace.dart';
import '../../domain/usecases/get_dashboard_workspace_usecase.dart';
import 'dashboard_workspace_state.dart';

class DashboardWorkspaceCubit extends Cubit<DashboardWorkspaceState> {
  final GetDashboardWorkspaceUseCase _getWorkspace;

  DashboardWorkspaceCubit(this._getWorkspace)
    : super(const DashboardWorkspaceLoading());

  Future<void> load(String workspaceId) async {
    emit(const DashboardWorkspaceLoading());
    try {
      final workspace = await _getWorkspace(workspaceId);
      if (workspace.rows.isEmpty && workspace.metrics.isEmpty) {
        emit(const DashboardWorkspaceEmpty());
        return;
      }
      emit(DashboardWorkspaceLoaded(workspace));
    } catch (error) {
      emit(DashboardWorkspaceError(error.toString()));
    }
  }

  void createRow(List<String> cells) {
    final current = state;
    if (current is! DashboardWorkspaceLoaded) return;

    final row = DashboardWorkspaceRow(
      cells: cells,
      status: 'attention',
      details: 'عنصر جديد تمت إضافته محلياً ضمن بيانات تجريبية.',
      timeline: const ['تم إنشاء العنصر من نموذج تجريبي.'],
    );
    emit(
      DashboardWorkspaceLoaded(
        current.workspace.copyWith(rows: [row, ...current.workspace.rows]),
      ),
    );
  }

  void updateRow(DashboardWorkspaceRow original, List<String> cells) {
    final current = state;
    if (current is! DashboardWorkspaceLoaded) return;

    final rows = current.workspace.rows
        .map(
          (row) => identical(row, original) ? row.copyWith(cells: cells) : row,
        )
        .toList();
    emit(DashboardWorkspaceLoaded(current.workspace.copyWith(rows: rows)));
  }

  void deleteRow(DashboardWorkspaceRow target) {
    final current = state;
    if (current is! DashboardWorkspaceLoaded) return;

    final rows = current.workspace.rows
        .where((row) => !identical(row, target))
        .toList();
    emit(DashboardWorkspaceLoaded(current.workspace.copyWith(rows: rows)));
  }

  void updateStatus(DashboardWorkspaceRow target, String statusLabel) {
    final current = state;
    if (current is! DashboardWorkspaceLoaded) return;

    final status =
        statusLabel.contains('مكتمل') ||
            statusLabel.contains('مؤكد') ||
            statusLabel.contains('نشط') ||
            statusLabel.contains('جاهز') ||
            statusLabel.contains('مقبول')
        ? 'done'
        : 'attention';
    final rows = current.workspace.rows.map((row) {
      if (!identical(row, target)) return row;
      final cells = [...row.cells];
      if (cells.isNotEmpty) {
        cells[cells.length - 1] = statusLabel;
      }
      return row.copyWith(
        cells: cells,
        status: status,
        timeline: ['تم تحديث الحالة إلى $statusLabel.', ...row.timeline],
      );
    }).toList();
    emit(DashboardWorkspaceLoaded(current.workspace.copyWith(rows: rows)));
  }
}
