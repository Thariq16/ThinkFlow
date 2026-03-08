import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_plan_provider.dart';
import '../../services/stripe_service.dart';

/// PlanGate widget — wraps any Pro-only UI element.
/// Reads userPlanProvider and shows upgrade prompt when Free tier limits are exceeded.
/// This is a UI gate only — not a security control. Cloud Functions enforce limits.
class PlanGate extends ConsumerWidget {
  final String feature; // 'voice_input' | 'kb_upload' | 'create_project'
  final Widget child;

  const PlanGate({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userPlanProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return child; // Not loaded yet, show child
        if (user.hasProAccess) return child; // Pro/Team — no gate

        // Free tier — check limits
        final isBlocked = _isBlocked(user.plan, feature,
            voiceInputs: user.voiceInputsThisMonth,
            projectCount: user.projectCount);

        if (!isBlocked) return child;

        // Show gated version
        return GestureDetector(
          onTap: () => _showUpgradeDialog(context),
          child: Stack(
            children: [
              Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Pro',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  bool _isBlocked(String plan, String feature,
      {int voiceInputs = 0, int projectCount = 0}) {
    if (plan != 'free') return false;
    switch (feature) {
      case 'voice_input':
        return voiceInputs >= 5;
      case 'kb_upload':
        return true; // Free plan has no KB uploads
      case 'create_project':
        return projectCount >= 3;
      default:
        return false;
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_upgradeMessage(feature),
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            const Text('Pro Plan — \$12/month',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.primary)),
            const SizedBox(height: 4),
            const Text('• Unlimited projects\n• Unlimited voice inputs\n• KB uploads up to 50MB',
                style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later',
                style: TextStyle(color: AppTheme.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await StripeService().openCheckout(
                  plan: 'pro',
                  successUrl: '${Uri.base.origin}/settings?upgraded=true',
                  cancelUrl: '${Uri.base.origin}/settings',
                );
              } catch (_) {}
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  String _upgradeMessage(String feature) {
    switch (feature) {
      case 'voice_input':
        return 'You\'ve reached your free plan limit of 5 voice inputs this month.';
      case 'kb_upload':
        return 'Knowledge Base uploads are available on the Pro plan.';
      case 'create_project':
        return 'You\'ve reached your free plan limit of 3 projects.';
      default:
        return 'This feature requires a Pro plan.';
    }
  }
}
