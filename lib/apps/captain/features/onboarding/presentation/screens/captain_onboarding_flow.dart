import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/session/captain_session_store.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../domain/entities/captain_onboarding_models.dart';
import '../../../auth/presentation/widgets/captain_auth_header.dart';
import '../../../auth/presentation/widgets/captain_auth_hero.dart';
import '../../../auth/presentation/widgets/captain_auth_reveal.dart';
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
    return BlocBuilder<CaptainOnboardingCubit, CaptainOnboardingState>(
      builder: (context, state) {
        // Only the form itself opens on the brand band. The pending, approved
        // and rejected panes are outcomes rather than an entrance, and each
        // already leads with a status mark of its own.
        final onForm = state is OnboardingForm || state is OnboardingSubmitting;
        final submitting = state is OnboardingSubmitting;

        return CaptainAuthScaffold(
          showBack: onForm,
          onBack: submitting ? null : widget.onBackToLogin,
          hero: onForm
              ? const CaptainAuthReveal(
                  child: CaptainAuthHero(
                    icon: Icons.badge_rounded,
                    badge: 'انضمام الكباتن',
                    title: 'انضم كـ كابتن',
                    subtitle:
                        'أرسل بياناتك ليراجعها فريق العمليات ويفعّل حسابك.',
                  ),
                )
              : null,
          child: switch (state) {
            OnboardingForm(
              :final error,
              :final offices,
              :final loadingOffices,
            ) =>
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
        );
      },
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
        const SizedBox(height: CaptainDesignTokens.s24),
        _SignInLink(onTap: submitting ? null : widget.onBackToLogin),
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
        const SizedBox(height: CaptainDesignTokens.s32),
        CaptainButton(label: 'تسجيل الدخول', onPressed: widget.onBackToLogin),
      ],
    );
  }
}

/// The way back to sign-in, as one sentence with the action in brand ink rather
/// than a bare [TextButton] — a captain who already has an account should be
/// able to find this without reading the form first.
class _SignInLink extends StatelessWidget {
  const _SignInLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final muted = CaptainColors.textSecondaryFor(context);
    final accent = enabled ? CaptainColors.primaryInkFor(context) : muted;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: CaptainDesignTokens.br12,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CaptainDesignTokens.s12,
              vertical: CaptainDesignTokens.s8,
            ),
            child: Text.rich(
              TextSpan(
                text: 'لديك حساب بالفعل؟ ',
                style: CaptainTypography.bodySmall(
                  context,
                ).copyWith(color: muted, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: 'تسجيل الدخول',
                    style: CaptainTypography.bodySmall(
                      context,
                    ).copyWith(color: accent, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
