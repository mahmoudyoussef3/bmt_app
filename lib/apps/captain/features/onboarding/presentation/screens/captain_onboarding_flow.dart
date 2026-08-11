import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../domain/entities/captain_onboarding_models.dart';
import '../../../auth/presentation/widgets/captain_auth_header.dart';
import '../../../auth/presentation/widgets/captain_auth_scaffold.dart';
import '../cubit/captain_onboarding_cubit.dart';
import '../cubit/captain_onboarding_state.dart';
import '../widgets/captain_request_approved_view.dart';
import '../widgets/captain_request_form.dart';
import '../widgets/captain_request_pending_view.dart';
import '../widgets/captain_request_rejected_view.dart';

class CaptainOnboardingFlow extends StatefulWidget {
  final void Function(CaptainLocalSession session) onEnterHome;
  final VoidCallback onBackToLogin;

  const CaptainOnboardingFlow({
    super.key,
    required this.onEnterHome,
    required this.onBackToLogin,
  });

  @override
  State<CaptainOnboardingFlow> createState() => _CaptainOnboardingFlowState();
}

class _CaptainOnboardingFlowState extends State<CaptainOnboardingFlow> {
  bool _entering = false;

  CaptainOnboardingCubit get _cubit => context.read<CaptainOnboardingCubit>();

  Future<void> _continue(OnboardingApproved state) async {
    setState(() => _entering = true);
    final session = await _cubit.establishSession(state);
    if (!mounted) return;
    widget.onEnterHome(session);
  }

  Future<void> _leave() async {
    await _cubit.discard();
    widget.onBackToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return CaptainAuthScaffold(
      child: BlocBuilder<CaptainOnboardingCubit, CaptainOnboardingState>(
        builder: (context, state) => switch (state) {
          OnboardingForm(:final error, :final offices, :final loadingOffices) =>
            _form(
              submitting: false,
              error: error,
              offices: _remember(offices),
              loadingOffices: loadingOffices,
            ),
          OnboardingSubmitting() => _form(
            submitting: true,
            offices: _lastOffices,
          ),
          OnboardingPending(:final phone) => CaptainRequestPendingView(
            phone: phone,
            onRefresh: _cubit.refreshNow,
            onCancel: _leave,
          ),
          OnboardingApproved() => CaptainRequestApprovedView(
            name: state.name,
            phone: state.phone,
            entering: _entering,
            onContinue: () => _continue(state),
          ),
          OnboardingRejected(:final reason) => CaptainRequestRejectedView(
            reason: reason,
            onRetry: () async {
              await _cubit.discard();
              _cubit.init(null);
            },
            onBackToLogin: _leave,
          ),
          OnboardingAlreadyActive() => _alreadyActive(),
        },
      ),
    );
  }

  List<OnboardingOffice> _lastOffices = const [];

  List<OnboardingOffice> _remember(List<OnboardingOffice> offices) {
    if (offices.isNotEmpty) _lastOffices = offices;
    return offices.isEmpty ? _lastOffices : offices;
  }

  Widget _form({
    required bool submitting,
    String? error,
    List<OnboardingOffice> offices = const [],
    bool loadingOffices = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CaptainRequestForm(
          submitting: submitting,
          error: error,
          offices: offices,
          loadingOffices: loadingOffices,
          onSubmit: (name, phone, officeId, officeCode) => _cubit.submit(
            fullName: name,
            phone: phone,
            officeId: officeId,
            officeCode: officeCode,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: submitting ? null : widget.onBackToLogin,
          child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
        ),
      ],
    );
  }

  Widget _alreadyActive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptainAuthHeader(
          icon: Icons.verified_user_rounded,
          title: 'أنت مسجّل بالفعل',
          subtitle: 'هذا الرقم مسجّل لكابتن نشط. سجّل الدخول للوصول إلى حسابك.',
        ),
        const SizedBox(height: 28),
        CaptainButton(label: 'تسجيل الدخول', onPressed: widget.onBackToLogin),
      ],
    );
  }
}
