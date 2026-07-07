import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_brand_app_bar.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// Trip Details' loading placeholder, mirroring the loaded layout's section
/// shapes — never a blank screen or spinner.
class TripLoadingView extends StatelessWidget {
  const TripLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: const TripBrandAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth(
              MediaQuery.sizeOf(context).width,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: const [
              ClientSkeleton(height: 150, borderRadius: 28),
              SizedBox(height: 16),
              ClientSkeleton(height: 120, borderRadius: 24),
              SizedBox(height: 16),
              ClientSkeleton(height: 150, borderRadius: 24),
              SizedBox(height: 16),
              ClientSkeleton(height: 260, borderRadius: 24),
              SizedBox(height: 16),
              ClientSkeleton(height: 160, borderRadius: 24),
            ],
          ),
        ),
      ),
    );
  }
}
