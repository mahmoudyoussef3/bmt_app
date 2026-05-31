import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/di.dart' as di;
import 'domain/repositories/support_ticket_repository.dart';
import 'presentation/cubit/support_ticket_cubit.dart';
import 'presentation/pages/support_ticket_list_page.dart';

class OpsDashboardModule extends StatelessWidget {
  const OpsDashboardModule({super.key});

  @override
  Widget build(BuildContext context) {
    di.registerOpsCenterDependencies();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SupportTicketCubit(di.di<SupportTicketRepository>()),
        ),
      ],
      child: const SupportTicketListPage(),
    );
  }
}
