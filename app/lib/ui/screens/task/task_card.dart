import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_edit_notifier.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final String projectId;

  const TaskCard({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _titleController.text = widget.task.title;
      _descController.text = widget.task.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = (
      taskId: widget.task.taskId,
      projectId: widget.projectId,
    );
    final editState = ref.watch(taskEditNotifierProvider(params));
    final notifier = ref.read(taskEditNotifierProvider(params).notifier);

    return Container(
      margin: EdgeInsets.only(
        left: widget.task.isSubtask ? 32.0 : 0,
        bottom: 6,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: widget.task.isEpic ? AppTheme.bgCard : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: _isEditing ? AppTheme.borderActive : AppTheme.borderSubtle,
          width: _isEditing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status toggle
              GestureDetector(
                onTap: () {
                  final nextStatus = _nextStatus(widget.task.status);
                  notifier.updateStatus(nextStatus);
                  notifier.save();
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Icon(
                    AppTheme.statusIcon(widget.task.status),
                    size: widget.task.isEpic ? 22 : 18,
                    color: AppTheme.statusColor(widget.task.status),
                  ),
                ),
              ),

              // Title
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: widget.task.isEpic ? 15 : 13,
                          fontWeight: widget.task.isEpic
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => notifier.updateTitle(v),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: widget.task.isEpic ? 15 : 13,
                            fontWeight: widget.task.isEpic
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.task.isDone
                                ? AppTheme.textTertiary
                                : AppTheme.textPrimary,
                            decoration: widget.task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
              ),

              // Priority badge
              _PriorityBadge(
                priority: widget.task.priority,
                onChanged: _isEditing
                    ? (p) {
                        notifier.updatePriority(p);
                      }
                    : null,
              ),

              // Lock toggle
              GestureDetector(
                onTap: () {
                  notifier.toggleLock();
                  notifier.save();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    widget.task.lockedFromRecalib
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    size: 16,
                    color: widget.task.lockedFromRecalib
                        ? AppTheme.warning
                        : AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),

          // Description (edit mode)
          if (_isEditing) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Add description...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
              onChanged: (v) => notifier.updateDescription(v),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _titleController.text = widget.task.title;
                    _descController.text = widget.task.description;
                  },
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: editState.isSaving
                      ? null
                      : () async {
                          await notifier.save();
                          if (mounted) setState(() => _isEditing = false);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: editState.isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ] else if (widget.task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: GestureDetector(
                onTap: () => setState(() => _isEditing = true),
                child: Text(
                  widget.task.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          // Error display
          if (editState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Save failed — changes rolled back',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _nextStatus(String current) {
    switch (current) {
      case 'todo':
        return 'in_progress';
      case 'in_progress':
        return 'done';
      case 'done':
        return 'todo';
      default:
        return 'todo';
    }
  }
}

/// Priority badge with optional selector
class _PriorityBadge extends StatelessWidget {
  final String priority;
  final Function(String)? onChanged;

  const _PriorityBadge({required this.priority, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null
          ? () {
              final priorities = ['low', 'medium', 'high'];
              final currentIndex = priorities.indexOf(priority);
              final nextIndex = (currentIndex + 1) % priorities.length;
              onChanged!(priorities[nextIndex]);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.priorityColor(priority).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          priority[0].toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.priorityColor(priority),
          ),
        ),
      ),
    );
  }
}
