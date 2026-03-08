import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../models/project_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/user_plan_provider.dart';
import '../../widgets/voice_record_button.dart';
import '../../widgets/plan_gate.dart';
import '../../widgets/responsive_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final userAsync = ref.watch(userPlanProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.displayName ?? 'PM',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ],
                          ),
                        ),
                        // Settings & avatar
                        Row(
                          children: [
                            userAsync.when(
                              data: (u) {
                                if (u == null) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: u.hasProAccess
                                        ? AppTheme.primary.withValues(alpha: 0.15)
                                        : AppTheme.bgElevated,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                    border: Border.all(
                                      color: u.hasProAccess
                                          ? AppTheme.primary
                                          : AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    u.plan.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: u.hasProAccess
                                          ? AppTheme.primary
                                          : AppTheme.textTertiary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded),
                              color: AppTheme.textSecondary,
                              onPressed: () => context.go('/settings'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    // ─── Voice Record CTA ────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A1F5E), Color(0xFF1A1A2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mic_rounded,
                            size: 36,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'Start with your voice',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Speak your thoughts, get organized tasks',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textTertiary),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          PlanGate(
                            feature: 'voice_input',
                            child: const VoiceRecordButton(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // ─── Section Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingSm),
                child: Row(
                  children: [
                    Text(
                      'Your Projects',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    projectsAsync.when(
                      data: (projects) => Text(
                        '${projects.length} project${projects.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Project List ────────────────────────────────────
            projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _ProjectCard(project: projects[index])
                            .animate()
                            .fadeIn(
                                delay: (100 * index).ms, duration: 400.ms)
                            .slideX(begin: 0.05);
                      },
                      childCount: projects.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Error loading projects: $e',
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingLg),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 48,
            color: AppTheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Record a voice note above to create your first project.\nThinkFlow will organize your thoughts into tasks automatically.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Individual project card widget
class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final progress = project.completionProgress;

    return GestureDetector(
      onTap: () => context.go('/project/${project.projectId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: project.status == 'active'
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: project.status == 'active'
                          ? AppTheme.success
                          : AppTheme.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                project.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                // Task count
                Icon(Icons.checklist_rounded,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${project.completedCount}/${project.taskCount} tasks',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                // Updated time
                Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  project.updatedAt.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const Spacer(),
                // Progress indicator
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.bgElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  progress.asPercent,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
