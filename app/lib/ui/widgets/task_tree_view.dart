import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../screens/task/task_card.dart';

/// Renders a hierarchical task tree from a flat list of tasks.
/// Reconstructs hierarchy using parentId and level fields.
/// Epics (level 1) are collapsible; subtasks (level 2) are indented.
class TaskTreeView extends StatefulWidget {
  final List<TaskModel> tasks;
  final String projectId;

  const TaskTreeView({
    super.key,
    required this.tasks,
    required this.projectId,
  });

  @override
  State<TaskTreeView> createState() => _TaskTreeViewState();
}

class _TaskTreeViewState extends State<TaskTreeView> {
  final Set<String> _collapsedEpics = {};

  @override
  Widget build(BuildContext context) {
    // Separate epics and subtasks
    final epics =
        widget.tasks.where((t) => t.isEpic).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: epics.length,
      itemBuilder: (context, index) {
        final epic = epics[index];
        final isCollapsed = _collapsedEpics.contains(epic.taskId);
        final subtasks = widget.tasks
            .where((t) => t.parentId == epic.taskId && t.isSubtask)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Epic header with collapse toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isCollapsed) {
                    _collapsedEpics.remove(epic.taskId);
                  } else {
                    _collapsedEpics.add(epic.taskId);
                  }
                });
              },
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TaskCard(
                      task: epic,
                      projectId: widget.projectId,
                    ),
                  ),
                ],
              ),
            ),

            // Subtasks (collapsed or visible)
            if (!isCollapsed)
              ...subtasks.map((subtask) => Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: TaskCard(
                      task: subtask,
                      projectId: widget.projectId,
                    ),
                  )),

            // Divider between epics
            if (index < epics.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  color: AppTheme.borderSubtle,
                  height: 1,
                ),
              ),
          ],
        );
      },
    );
  }
}
