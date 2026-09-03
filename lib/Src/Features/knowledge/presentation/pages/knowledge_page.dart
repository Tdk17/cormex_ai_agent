import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_models.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/presentation/controllers/knowledge_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class KnowledgePage extends SignalStatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  late final KnowledgeController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<KnowledgeController>();
    if (controller.state.value == ScreenState.initial) {
      unawaited(controller.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final items = controller.sources.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Base de Conhecimento',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ensine produtos, ofertas, regras e respostas autorizadas ao seu agente.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: controller.isMutating.value ? null : _showCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar fonte'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _KnowledgeFilters(controller: controller),
        if (controller.errorMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          FormErrorBanner(
            message: controller.errorMessage.value!,
            correlationId: controller.correlationId.value,
          ),
        ],
        if (controller.successMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          _SuccessBanner(message: controller.successMessage.value!),
        ],
        const SizedBox(height: 18),
        if (state == ScreenState.loading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(64),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state == ScreenState.error && items.isEmpty)
          _RetryCard(onRetry: () => controller.load(force: true))
        else if (items.isEmpty)
          _EmptyKnowledge(onAdd: _showCreate)
        else ...<Widget>[
          if (state == ScreenState.loading)
            const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          ...items.map(
            (KnowledgeSourceModel item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _KnowledgeCard(
                source: item,
                deleting: controller.isMutating.value,
                onDelete: () => _confirmDelete(item),
              ),
            ),
          ),
          if (controller.nextCursor.value != null)
            Center(
              child: TextButton.icon(
                onPressed: controller.isLoadingMore.value
                    ? null
                    : controller.loadMore,
                icon: controller.isLoadingMore.value
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: const Text('Carregar mais'),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _showCreate() async {
    controller.clearFeedback();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _CreateKnowledgeDialog(controller: controller),
    );
  }

  Future<void> _confirmDelete(KnowledgeSourceModel source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Excluir fonte?'),
        content: Text(
          '“${source.name}” deixará de ser usada nas respostas do agente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteSource(source.id);
  }
}

class _KnowledgeFilters extends StatelessWidget {
  const _KnowledgeFilters({required this.controller});

  final KnowledgeController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: 320,
              child: TextField(
                onChanged: controller.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar fonte',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                initialValue: controller.typeFilter.value,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  isDense: true,
                ),
                items: const <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<String?>(value: 'text', child: Text('Texto')),
                  DropdownMenuItem<String?>(value: 'faq', child: Text('FAQ')),
                  DropdownMenuItem<String?>(value: 'file', child: Text('Arquivo')),
                ],
                onChanged: controller.setType,
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String?>(
                initialValue: controller.statusFilter.value,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                ),
                items: const <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<String?>(
                    value: 'processing',
                    child: Text('Processando'),
                  ),
                  DropdownMenuItem<String?>(value: 'ready', child: Text('Pronto')),
                  DropdownMenuItem<String?>(value: 'failed', child: Text('Falhou')),
                ],
                onChanged: controller.setStatus,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Atualizar',
              onPressed: () => controller.load(force: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({
    required this.source,
    required this.deleting,
    required this.onDelete,
  });

  final KnowledgeSourceModel source;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(source.createdAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_typeIcon(source.type), color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        source.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      _StatusChip(status: source.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_typeLabel(source.type)} • $date • ${source.contentCount} trecho(s)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (source.errorMessage?.trim().isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 5),
                    Text(
                      source.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Excluir fonte',
              onPressed: deleting ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateKnowledgeDialog extends StatefulWidget {
  const _CreateKnowledgeDialog({required this.controller});

  final KnowledgeController controller;

  @override
  State<_CreateKnowledgeDialog> createState() =>
      _CreateKnowledgeDialogState();
}

class _CreateKnowledgeDialogState extends State<_CreateKnowledgeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String _type = 'text';
  PlatformFile? _file;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar conhecimento'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'text', label: Text('Texto')),
                    ButtonSegment<String>(value: 'faq', label: Text('FAQ')),
                    ButtonSegment<String>(value: 'file', label: Text('Arquivo')),
                  ],
                  selected: <String>{_type},
                  showSelectedIcon: false,
                  onSelectionChanged: _submitting
                      ? null
                      : (Set<String> values) {
                          setState(() {
                            _type = values.first;
                            _error = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome da fonte'),
                  validator: (String? value) => (value?.trim().length ?? 0) < 2
                      ? 'Informe um nome.'
                      : null,
                ),
                const SizedBox(height: 12),
                if (_type == 'text')
                  TextFormField(
                    controller: _contentController,
                    minLines: 7,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo autorizado',
                      alignLabelWithHint: true,
                    ),
                    validator: (String? value) =>
                        (value?.trim().length ?? 0) < 20
                        ? 'Informe pelo menos 20 caracteres.'
                        : null,
                  )
                else if (_type == 'faq') ...<Widget>[
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(labelText: 'Pergunta'),
                    validator: (String? value) =>
                        (value?.trim().length ?? 0) < 5
                        ? 'Informe a pergunta.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _answerController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Resposta autorizada',
                      alignLabelWithHint: true,
                    ),
                    validator: (String? value) =>
                        (value?.trim().length ?? 0) < 5
                        ? 'Informe a resposta.'
                        : null,
                  ),
                ] else ...<Widget>[
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_file?.name ?? 'Selecionar PDF, DOCX, TXT ou MD'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tamanho máximo: 15 MB.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_submitting && _type == 'file') ...<Widget>[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'docx', 'txt', 'md'],
    );
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    if (file.size > KnowledgeController.maxFileBytes) {
      setState(() => _error = 'O arquivo deve ter até 15 MB.');
      return;
    }
    setState(() {
      _file = file;
      _error = null;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = file.name;
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_type == 'file' && _file == null) {
      setState(() => _error = 'Selecione um arquivo.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final success = switch (_type) {
        'faq' => await widget.controller.create(
            KnowledgeSourceInput(
              type: 'faq',
              name: _nameController.text,
              question: _questionController.text,
              answer: _answerController.text,
            ),
          ),
        'file' => await _uploadFile(),
        _ => await widget.controller.create(
            KnowledgeSourceInput(
              type: 'text',
              name: _nameController.text,
              content: _contentController.text,
            ),
          ),
      };
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() => _error = widget.controller.errorMessage.value);
      }
    } on Object {
      if (mounted) setState(() => _error = 'Não foi possível ler o arquivo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _uploadFile() async {
    final file = _file!;
    final bytes = await file.readAsBytes();
    return widget.controller.upload(
      KnowledgeFileInput(
        name: _nameController.text,
        fileName: file.name,
        mimeType: _mimeType(file.extension),
        bytes: bytes,
      ),
    );
  }

  static String _mimeType(String? extension) => switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'md' => 'text/markdown',
        _ => 'text/plain',
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ready' => AppColors.accent,
      'failed' => AppColors.danger,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'ready' => 'Pronto',
      'failed' => 'Falhou',
      _ => 'Processando',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyKnowledge extends StatelessWidget {
  const _EmptyKnowledge({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        child: Column(
          children: <Widget>[
            const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 14),
            Text('Sua base ainda está vazia', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Adicione um texto, uma FAQ ou um arquivo para contextualizar a IA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar primeira fonte'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tentar novamente'),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.accent),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

IconData _typeIcon(String type) => switch (type) {
      'faq' => Icons.quiz_outlined,
      'file' => Icons.description_outlined,
      _ => Icons.notes_rounded,
    };

String _typeLabel(String type) => switch (type) {
      'faq' => 'FAQ',
      'file' => 'Arquivo',
      _ => 'Texto',
    };
