import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../models/kb_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/kb_items_provider.dart';
import '../../../providers/recalibration_provider.dart';
import '../../../services/functions_service.dart';
import '../../../services/storage_service.dart';
import '../../widgets/plan_gate.dart';

class KbPanel extends ConsumerStatefulWidget {
  final String projectId;
  const KbPanel({super.key, required this.projectId});

  @override
  ConsumerState<KbPanel> createState() => _KbPanelState();
}

class _KbPanelState extends ConsumerState<KbPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kbItemsAsync = ref.watch(kbItemsProvider(widget.projectId));
    final recalibState = ref.watch(recalibrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        actions: [
          kbItemsAsync.when(
            data: (items) {
              final ready = items.where((i) => i.isReady).toList();
              if (ready.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: recalibState.isLoading
                    ? null
                    : () => _recalibrate(ready.first.kbId),
                icon: recalibState.isLoading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(recalibState.isLoading ? 'Working...' : 'Recalibrate'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          PlanGate(
            feature: 'kb_upload',
            child: _buildUploadSection(),
          ),
          Expanded(child: _buildKbList(kbItemsAsync)),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textTertiary,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.picture_as_pdf, size: 18), text: 'PDF'),
              Tab(icon: Icon(Icons.link, size: 18), text: 'URL'),
              Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Text'),
            ],
          ),
          SizedBox(
            height: 160,
            child: TabBarView(
              controller: _tabController,
              children: [_pdfTab(), _urlTab(), _textTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfTab() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _uploadPdf,
          icon: _isUploading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file),
          label: Text(_isUploading ? 'Uploading...' : 'Choose PDF'),
        ),
        const SizedBox(height: 8),
        const Text('Max 50MB', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
      ]),
    );
  }

  Widget _urlTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(children: [
        TextField(controller: _urlController,
          decoration: const InputDecoration(hintText: 'https://example.com', prefixIcon: Icon(Icons.link, size: 18))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: _isUploading ? null : _submitUrl,
            child: Text(_isUploading ? 'Processing...' : 'Add URL'))),
      ]),
    );
  }

  Widget _textTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(children: [
        Expanded(child: TextField(controller: _textController, maxLines: null, expands: true,
          decoration: const InputDecoration(hintText: 'Paste or type text...'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: _isUploading ? null : _submitText,
            child: Text(_isUploading ? 'Processing...' : 'Add Text'))),
      ]),
    );
  }

  Widget _buildKbList(AsyncValue<List<KbItemModel>> kbItemsAsync) {
    return kbItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.library_books_rounded, size: 40, color: AppTheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No KB items yet', style: TextStyle(color: AppTheme.textSecondary)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _KbTile(item: items[i]).animate().fadeIn(delay: (50 * i).ms),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt', 'md'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (!Validators.isFileSizeValid(file.bytes!.length)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large. Max 50MB.'), backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _isUploading = true);
    try {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) throw Exception('Not authenticated');
      final storagePath = await StorageService().uploadKbDocument(uid: uid, projectId: widget.projectId, fileName: file.name, fileBytes: file.bytes!, mimeType: 'application/pdf');
      await FunctionsService().ingestKbItem(projectId: widget.projectId, type: 'pdf', label: file.name, storageRef: storagePath);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitUrl() async {
    final url = _urlController.text.trim();
    if (Validators.validateUrl(url) != null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid URL'), backgroundColor: AppTheme.error)); return; }
    setState(() => _isUploading = true);
    try { await FunctionsService().ingestKbItem(projectId: widget.projectId, type: 'url', label: url, url: url); _urlController.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error)); }
    finally { if (mounted) setState(() => _isUploading = false); }
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isUploading = true);
    try { await FunctionsService().ingestKbItem(projectId: widget.projectId, type: 'text', label: 'Text — ${DateTime.now().toString().substring(0, 16)}', text: text); _textController.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error)); }
    finally { if (mounted) setState(() => _isUploading = false); }
  }

  Future<void> _recalibrate(String kbItemId) async {
    await ref.read(recalibrationProvider.notifier).recalibrate(projectId: widget.projectId, kbItemId: kbItemId);
  }
}

class _KbTile extends StatelessWidget {
  final KbItemModel item;
  const _KbTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusSm), border: Border.all(color: AppTheme.borderSubtle)),
      child: Row(children: [
        Icon(item.type == 'pdf' ? Icons.picture_as_pdf : item.type == 'url' ? Icons.link : Icons.text_snippet, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(item.label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (item.isReady ? AppTheme.success : item.hasError ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4)),
          child: Text(item.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: item.isReady ? AppTheme.success : item.hasError ? AppTheme.error : AppTheme.warning)),
        ),
      ]),
    );
  }
}
