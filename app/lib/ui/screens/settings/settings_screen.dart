import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_plan_provider.dart';
import '../../../services/stripe_service.dart';
import '../../widgets/responsive_layout.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userPlanProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Settings'),
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          // ─── Profile Section ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: authUser?.photoURL != null
                      ? NetworkImage(authUser!.photoURL!)
                      : null,
                  child: authUser?.photoURL == null
                      ? Text(
                          (authUser?.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authUser?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authUser?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Plan Section ──────────────────────────────────────
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: user.hasProAccess
                      ? const LinearGradient(
                          colors: [Color(0xFF2A1F5E), Color(0xFF1A1A2E)])
                      : null,
                  color: user.hasProAccess ? null : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: user.hasProAccess
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : AppTheme.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          user.hasProAccess
                              ? Icons.workspace_premium
                              : Icons.star_outline,
                          color: user.hasProAccess
                              ? AppTheme.warning
                              : AppTheme.textTertiary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user.plan.toUpperCase()} Plan',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    if (user.isFree) ...[
                      _planDetail('Projects', '${user.projectCount}/3'),
                      _planDetail('Voice inputs',
                          '${user.voiceInputsThisMonth}/5 this month'),
                      _planDetail('KB uploads', 'Not available'),
                      const SizedBox(height: AppTheme.spacingMd),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _upgrade(context, 'pro'),
                          child: const Text('Upgrade to Pro — \$12/month'),
                        ),
                      ),
                    ] else ...[
                      _planDetail('Projects', 'Unlimited'),
                      _planDetail('Voice inputs', 'Unlimited'),
                      _planDetail('KB uploads', 'Up to 50MB'),
                      if (user.isTeam)
                        _planDetail('Team seats', '5 seats'),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ─── Plan Options ──────────────────────────────────────
          userAsync.when(
            data: (user) {
              if (user == null || user.isTeam) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Plans',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppTheme.spacingSm),
                  if (!user.isPro)
                    _planCard(context, 'Pro', '\$12/month',
                        'Unlimited everything + KB uploads', 'pro'),
                  if (!user.isTeam)
                    _planCard(context, 'Team', '\$29/month',
                        'Everything + 5 seats + shared projects', 'team'),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // ─── Logout ────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _planDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, String name, String price,
      String desc, String planId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name — $price',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _upgrade(context, planId),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _upgrade(BuildContext context, String plan) async {
    try {
      final stripe = StripeService();
      await stripe.openCheckout(
        plan: plan,
        successUrl: '${Uri.base.origin}/settings?upgraded=true',
        cancelUrl: '${Uri.base.origin}/settings',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open checkout: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
