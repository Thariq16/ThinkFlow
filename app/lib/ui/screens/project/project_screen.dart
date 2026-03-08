import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/tasks_provider.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/recalibration_provider.dart';
import '../../widgets/task_tree_view.dart';
import '../../widgets/voice_record_button.dart';
import '../../widgets/plan_gate.dart';

class ProjectScreen extends ConsumerWidget {
  final String projectId;

  const ProjectScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider(projectId));
    final projectsAsync = ref.watch(projectsProvider);
    final pendingDiffs = ref.watch(pendingDiffsProvider(projectId));

    // Find the current project from the list
    final project = projectsAsync.whenOrNull(
      data: (projects) {
        try {
          return projects.firstWhere((p) => p.projectId == projectId);
        } catch (_) {
          return null;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(project?.title ?? 'Project'),
        actions: [
          // Pending diffs badge
          pendingDiffs.when(
            data: (diffs) {
              if (diffs.isEmpty) return const SizedBox.shrink();
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.difference_rounded),
                    color: AppTheme.warning,
                    onPressed: () {
                      final diffId = diffs.first.diffId;
                      context.go('/project/$projectId/diff/$diffId');
                    },
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${diffs.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // KB button
          IconButton(
            icon: const Icon(Icons.library_books_rounded),
            color: AppTheme.textSecondary,
            tooltip: 'Knowledge Base',
            onPressed: () => context.go('/project/$projectId/kb'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Project info bar
          if (project != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingSm,
              ),
              color: AppTheme.bgSurface,
              child: Row(
                children: [
                  Icon(Icons.checklist_rounded,
                      size: 14, color: AppTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${project.completedCount}/${project.taskCount} tasks complete',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.completionProgress,
                        backgroundColor: AppTheme.bgElevated,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Task tree
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_tree_rounded,
                          size: 48,
                          color: AppTheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record a voice note to generate tasks,\nor add them manually.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return TaskTreeView(
                  tasks: tasks,
                  projectId: projectId,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading tasks: $e',
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
      // Voice Record FAB
      floatingActionButton: PlanGate(
        feature: 'voice_input',
        child: const VoiceRecordButton(),
      ),
    );
  }
}
