import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/onboarding_screen.dart';
import 'authentication_wrapper.dart';
import '../screens/home_dashboard_screen.dart';

/// Wrapper widget that handles onboarding logic
/// Shows onboarding screen on first launch, otherwise shows main app
class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOnboarding();
    });
  }

  Future<void> _initializeOnboarding() async {
    final onboardingProvider = context.read<OnboardingProvider>();
    await onboardingProvider.initialize();
  }

  void _onOnboardingComplete() {
    // No navigation needed here, just let the consumer rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        // Show loading while checking onboarding status
        if (onboardingProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show onboarding if not completed
        if (!onboardingProvider.hasCompletedOnboarding) {
          return OnboardingScreen(
            onComplete: _onOnboardingComplete,
          );
        }

        // Show main app with authentication
        return const AuthenticationWrapper(
          child: HomeDashboardScreen(),
        );
      },
    );
  }
}
