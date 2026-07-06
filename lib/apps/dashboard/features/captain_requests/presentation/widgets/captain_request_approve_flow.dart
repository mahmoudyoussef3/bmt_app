import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_form_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/presentation/utils/fleet_pending_docs_uploader.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../../domain/entities/captain_request.dart';
import '../cubit/captain_requests_cubit.dart';

/// Approval = "complete the driver data". Reuses the exact fleet driver form
/// (validation + document upload + create) pre-filled with the request's name
/// and phone, then links the new driver back to the request.
class CaptainRequestApproveFlow {
  const CaptainRequestApproveFlow._();

  static Future<void> start(
    BuildContext context,
    CaptainRequestsCubit requestsCubit,
    CaptainRequest request,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final FleetWorkspace workspace;
    try {
      workspace = await dashboardDi<GetFleetWorkspaceUseCase>()();
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'تعذر تحميل بيانات الأسطول، حاول مجدداً');
      }
      return;
    }
    if (!context.mounted) return;

    final prefilled = FleetDriver(
      id: '',
      employeeCode: '',
      fullName: request.fullName,
      phone: request.phone,
      emergencyPhone: '',
      address: '',
      nationalId: '',
      profileImageUrl: '',
      licenseNumber: '',
      licenseExpiryDate: '',
      hireDate: DateTime.now().toIso8601String().substring(0, 10),
      notes: 'طلب انضمام كابتن — تمت الموافقة من قائمة الطلبات.',
      status: FleetDriverStatus.active,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => dashboardDi<FleetDriversCubit>()),
            BlocProvider(create: (_) => dashboardDi<FleetDocumentsCubit>()),
          ],
          child: Builder(
            builder: (providerContext) => FleetDriverFormView(
              driver: prefilled,
              workspace: workspace,
              onBack: () => Navigator.pop(dialogContext),
              onSave: (driver, pendingDocs) => _save(
                providerContext,
                dialogContext,
                messenger,
                requestsCubit,
                request,
                driver,
                pendingDocs,
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<String?> _save(
    BuildContext providerContext,
    BuildContext dialogContext,
    ScaffoldMessengerState messenger,
    CaptainRequestsCubit requestsCubit,
    CaptainRequest request,
    FleetDriver driver,
    List pendingDocs,
  ) async {
    try {
      final driversCubit = providerContext.read<FleetDriversCubit>();
      final docsCubit = providerContext.read<FleetDocumentsCubit>();

      final saved = await driversCubit.saveDriver(driver);
      final failed = await FleetPendingDocsUploader.upload(
        docsCubit,
        ownerId: saved.id,
        isDriver: true,
        docs: List.castFrom(pendingDocs),
      );

      final linkError = await requestsCubit.approve(
        requestId: request.id,
        driverId: saved.id,
      );
      if (linkError != null) return linkError;

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failed.isEmpty
                ? 'تم قبول الكابتن وإنشاء ملف السائق بنجاح'
                : 'تم قبول الكابتن، لكن تعذّر رفع: ${failed.join('، ')}',
          ),
        ),
      );
      return null;
    } catch (error) {
      return error.toString().replaceAll('Exception: ', '');
    }
  }
}
