import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/fleet_drivers/presentation/widgets/fleet_driver_details_view.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';

/// The driver file opens inside the fleet module's page scroll view, so every
/// box in it is measured against an *unbounded* height. A card that asked to
/// fill that height (a `Spacer`) threw during layout and left its subtree with
/// no size — which surfaced to the operator as "Cannot hit test a render box
/// with no size" the moment they clicked a driver card.
///
/// The widths below are the ones that reproduced it: the split-pane detail
/// column, and the desktop two-column layout whose document pane is narrower
/// than the grid breakpoint.

const _document = FleetDocument(
  id: 'doc-1',
  type: FleetDocumentType.driverLicense,
  ownerId: 'd-1',
  ownerName: 'سائق تجريبي',
  referenceNumber: 'REF-1',
  expiryDate: '2027-01-01',
  status: FleetDocumentStatus.valid,
  fileUrl: 'https://example.com/license.pdf',
);

const _driver = FleetDriver(
  id: 'd-1',
  employeeCode: 'EMP-1',
  fullName: 'سائق تجريبي',
  phone: '01000000000',
  emergencyPhone: '',
  address: '',
  nationalId: '',
  profileImageUrl: '',
  licenseNumber: '',
  licenseExpiryDate: '',
  hireDate: '',
  notes: '',
  status: FleetDriverStatus.active,
  documents: [_document],
);

const _workspace = FleetWorkspace(
  drivers: [_driver],
  vehicles: [],
  assignments: [],
  documents: [_document],
);

void main() {
  for (final paneWidth in const [600.0, 900.0, 1100.0, 1400.0]) {
    testWidgets('the driver file lays out at ${paneWidth.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var wentBack = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: DashboardAppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              // The fleet module renders every tab inside one page scroll view.
              body: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: paneWidth,
                      child: FleetDriverDetailsView(
                        driver: _driver,
                        workspace: _workspace,
                        onBack: () => wentBack = true,
                        onEdit: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('ملف السائق: سائق تجريبي'), findsOneWidget);
      expect(find.text('الوثائق والمستندات'), findsOneWidget);

      // The file is not just painted, it answers a click: an unsized subtree
      // would throw here instead of routing the tap.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();

      expect(wentBack, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
