import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recalibration_diff_model.dart';
import '../../../providers/recalibration_provider.dart';
import '../../../services/firestore_service.dart';

class DiffReviewScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String diffId;
  const DiffReviewScreen({super.key, required this.projectId, required this.diffId});

  @override
  ConsumerState<DiffReviewScreen> createState() => _DiffReviewScreenState();
}

class _DiffReviewScreenState extends ConsumerState<DiffReviewScreen> {
  RecalibrationDiffModel? _diff;
  final Set<int> _acceptedChanges = {};
  final Set<int> _acceptedNewTasks = {};
  bool _isLoading = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    final firestore = ref.read(firestoreServiceProvider);
    final diff = await firestore.getDiff(widget.projectId, widget.diffId);
    if (mounted) setState(() { _diff = diff; _isLoading = false; });
  }

  void _selectAll() {
    if (_diff == null) return;
    setState(() {
      _acceptedChanges.addAll(List.generate(_diff!.changes.length, (i) => i));
      _acceptedNewTasks.addAll(List.generate(_diff!.newTasks.length, (i) => i));
    });
  }

  void _deselectAll() {
    setState(() { _acceptedChanges.clear(); _acceptedNewTasks.clear(); });
  }

  Future<void> _applyChanges() async {
    if (_diff == null) return;
    setState(() => _isApplying = true);
    try {
      final changeIds = _acceptedChanges.map((i) => _diff!.changes[i].taskId).toList();
      await ref.read(recalibrationProvider.notifier).acceptDiff(
        projectId: widget.projectId,
        diffId: widget.diffId,
        acceptedChangeIds: changeIds,
      );
      if (mounted) context.go('/project/${widget.projectId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error));
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/project/${widget.projectId}')),
        title: const Text('Review Changes'),
        actions: [
          TextButton(onPressed: _deselectAll, child: const Text('Dismiss All', style: TextStyle(color: AppTheme.textTertiary))),
          TextButton(onPressed: _selectAll, child: const Text('Accept All', style: TextStyle(color: AppTheme.accent))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _diff == null
              ? const Center(child: Text('Diff not found', style: TextStyle(color: AppTheme.error)))
              : ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  children: [
                    if (_diff!.changes.isNotEmpty) ...[
                      Text('Task Changes (${_diff!.changes.length})', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...List.generate(_diff!.changes.length, (i) {
                        final c = _diff!.changes[i];
                        final selected = _acceptedChanges.contains(i);
                        return _ChangeCard(
                          change: c,
                          selected: selected,
                          onToggle: () => setState(() => selected ? _acceptedChanges.remove(i) : _acceptedChanges.add(i)),
                        ).animate().fadeIn(delay: (50 * i).ms);
                      }),
                    ],
                    if (_diff!.newTasks.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      Text('New Tasks (${_diff!.newTasks.length})', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...List.generate(_diff!.newTasks.length, (i) {
                        final t = _diff!.newTasks[i];
                        final selected = _acceptedNewTasks.contains(i);
                        return _NewTaskCard(
                          title: t.title,
                          description: t.description,
                          selected: selected,
                          onToggle: () => setState(() => selected ? _acceptedNewTasks.remove(i) : _acceptedNewTasks.add(i)),
                        ).animate().fadeIn(delay: (50 * i).ms);
                      }),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
      bottomNavigationBar: _diff != null && !_isLoading
          ? Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: const BoxDecoration(color: AppTheme.bgSurface, border: Border(top: BorderSide(color: AppTheme.borderSubtle))),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: (_acceptedChanges.isEmpty && _acceptedNewTasks.isEmpty) || _isApplying ? null : _applyChanges,
                  child: _isApplying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Apply ${_acceptedChanges.length + _acceptedNewTasks.length} Changes'),
                ),
              ),
            )
          : null,
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final DiffChange change;
  final bool selected;
  final VoidCallback onToggle;
  const _ChangeCard({required this.change, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? AppTheme.primary : AppTheme.textTertiary),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(4)),
              child: Text(change.field.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
              child: Text(change.oldValue, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 16, color: AppTheme.textTertiary)),
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
              child: Text(change.newValue, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary), maxLines: 3, overflow: TextOverflow.ellipsis))),
          ]),
          const SizedBox(height: 6),
          Text(change.reason, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary, fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }
}

class _NewTaskCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onToggle;
  const _NewTaskCard({required this.title, required this.description, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: selected ? AppTheme.success.withValues(alpha: 0.08) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: selected ? AppTheme.success : AppTheme.borderSubtle),
        ),
        child: Row(children: [
          Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? AppTheme.success : AppTheme.textTertiary),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            if (description.isNotEmpty) Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.success),
        ]),
      ),
    );
  }
}
