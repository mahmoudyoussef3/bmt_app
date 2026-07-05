import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _imagePaths = [
    'assets/images/first_onboarding.png',
    'assets/images/second_onboarding.png',
    'assets/images/third_onboarding.png',
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _imagesPrecached = false;
  bool _isCompleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;

    _imagesPrecached = true;
    for (final path in _imagePaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_OnboardingPageData> _pages(AppLocalizations l10n) => [
    _OnboardingPageData(
      imagePath: _imagePaths[0],
      title: l10n.onboarding_page1Title,
      description: l10n.onboarding_page1Body,
      alignment: Alignment.center,
    ),
    _OnboardingPageData(
      imagePath: _imagePaths[1],
      title: l10n.onboarding_page2Title,
      description: l10n.onboarding_page2Body,
      alignment: const Alignment(0, -0.08),
    ),
    _OnboardingPageData(
      imagePath: _imagePaths[2],
      title: l10n.onboarding_page3Title,
      description: l10n.onboarding_page3Body,
      alignment: const Alignment(-0.22, -0.04),
    ),
  ];

  void _nextPage(int pageCount) {
    HapticFeedback.selectionClick();
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    HapticFeedback.lightImpact();
    setState(() => _isCompleting = true);
    await context.read<OnboardingCubit>().completeOnboarding();
    if (mounted) setState(() => _isCompleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final compact = size.height < 700;
    final horizontalPadding = size.width < 360
        ? ClientSpacing.lg
        : size.width >= 600
        ? ClientSpacing.section
        : ClientSpacing.xl;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) =>
                  _OnboardingBackground(data: pages[index]),
            ),
            const IgnorePointer(child: _PhotographyOverlay()),
            SafeArea(
              minimum: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? ClientSpacing.sm : ClientSpacing.md,
                horizontalPadding,
                compact ? ClientSpacing.md : ClientSpacing.xl,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AnimatedPageCopy(
                        key: ValueKey(_currentPage),
                        data: pages[_currentPage],
                        compact: compact,
                      ),
                      SizedBox(
                        height: compact ? ClientSpacing.md : ClientSpacing.lg,
                      ),
                      _PageDots(
                        count: pages.length,
                        currentPage: _currentPage,
                      ),
                      SizedBox(
                        height: compact ? ClientSpacing.md : ClientSpacing.xl,
                      ),
                      _BottomActions(
                        isLastPage: _currentPage == pages.length - 1,
                        isCompleting: _isCompleting,
                        onSkip: _completeOnboarding,
                        onNext: () => _nextPage(pages.length),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.alignment,
  });

  final String imagePath;
  final String title;
  final String description;
  final Alignment alignment;
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      excludeSemantics: true,
      child: Image.asset(
        data.imagePath,
        fit: BoxFit.cover,
        alignment: data.alignment,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _PhotographyOverlay extends StatelessWidget {
  const _PhotographyOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(20),
            Colors.transparent,
            Colors.black.withAlpha(10),
            Colors.black.withAlpha(128),
            Colors.black.withAlpha(235),
          ],
          stops: const [0, 0.32, 0.48, 0.68, 1],
        ),
      ),
    );
  }
}

class _AnimatedPageCopy extends StatelessWidget {
  const _AnimatedPageCopy({
    super.key,
    required this.data,
    required this.compact,
  });

  final _OnboardingPageData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360
        ? 29.0
        : width >= 600
        ? 40.0
        : 34.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: ClientTypography.displayMedium(context).copyWith(
              color: Colors.white,
              fontSize: titleSize,
              height: 1.16,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: Color(0x52000000),
                  blurRadius: 16,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? ClientSpacing.sm : ClientSpacing.md),
          Text(
            data.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: ClientTypography.bodyLarge(context).copyWith(
              color: Colors.white.withAlpha(220),
              fontSize: width < 360 ? 14.5 : 16,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentPage});

  final int count;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(count, (index) {
        final active = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: active ? 26 : 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withAlpha(90),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
          ),
        );
      }),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isLastPage,
    required this.isCompleting,
    required this.onSkip,
    required this.onNext,
  });

  final bool isLastPage;
  final bool isCompleting;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        TextButton(
          onPressed: isCompleting ? null : onSkip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withAlpha(220),
            disabledForegroundColor: Colors.white.withAlpha(110),
            minimumSize: const Size(64, 54),
            padding: const EdgeInsets.symmetric(horizontal: ClientSpacing.sm),
            textStyle: ClientTypography.labelLarge(
              context,
            ).copyWith(fontSize: 15),
          ),
          child: Text(l10n.onboarding_skip),
        ),
        const Spacer(),
        ClientButton(
          expand: false,
          label: isLastPage ? l10n.onboarding_getStarted : l10n.onboarding_next,
          isLoading: isCompleting,
          onPressed: isCompleting ? () {} : onNext,
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ],
    );
  }
}
