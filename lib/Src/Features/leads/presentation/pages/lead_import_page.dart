import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_preview.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_labels.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_import_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class LeadImportPage extends SignalStatefulWidget {
  const LeadImportPage({super.key});

  @override
  State<LeadImportPage> createState() => _LeadImportPageState();
}

class _LeadImportPageState extends State<LeadImportPage> {
  late final LeadImportController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<LeadImportController>();
  }

  @override
  Widget build(BuildContext context) {
    final preview = controller.preview.value;
    final result = controller.result.value;
    final importing = controller.state.value == ScreenState.loading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Voltar para leads',
              onPressed: () => context.go('/leads'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Importar leads', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Envie uma base CSV, revise os dados e importe apenas as linhas válidas.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: <Widget>[
                const _FormatGuide(),
                const SizedBox(height: 16),
                _FileSelector(
                  fileName: controller.fileName.value,
                  onSelect: importing ? null : controller.pickCsv,
                ),
                if (controller.errorMessage.value != null) ...<Widget>[
                  const SizedBox(height: 14),
                  FormErrorBanner(
                    message: controller.errorMessage.value!,
                    correlationId: controller.correlationId.value,
                  ),
                ],
                if (preview != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _PreviewCard(preview: preview),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final button = SizedBox(
                            width: constraints.maxWidth < 520 ? double.infinity : 240,
                            child: PrimaryLoadingButton(
                              label: 'Importar ${preview.validCount} leads',
                              isLoading: importing,
                              onPressed: preview.validCount == 0 ? null : _import,
                              icon: Icons.cloud_upload_outlined,
                            ),
                          );
                          return Wrap(
                            spacing: 18,
                            runSpacing: 14,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 450,
                                child: Text(
                                  preview.invalidCount == 0
                                      ? 'Todas as linhas estão prontas para importação.'
                                      : '${preview.invalidCount} linha(s) inválida(s) serão ignoradas.',
                                  style: TextStyle(
                                    color: preview.invalidCount == 0
                                        ? AppColors.primary
                                        : AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              button,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
                if (result != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _ImportSuccess(
                    accepted: result.accepted,
                    rejected: result.rejected,
                    onFinish: () => context.go('/leads'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _import() async {
    final success = await controller.importValidRows();
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importação concluída com sucesso.')),
    );
  }
}

class _FormatGuide extends StatelessWidget {
  const _FormatGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.blue),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Formato esperado', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text(
                    'Use um arquivo .csv com cabeçalho. Colunas aceitas: nome, telefone, e-mail, empresa, origem, status, tags e score. Nome e telefone ou e-mail são obrigatórios.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  const _FileSelector({required this.fileName, required this.onSelect});

  final String? fileName;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onSelect,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: <Widget>[
              const Icon(Icons.upload_file_rounded, size: 45, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                fileName ?? 'Selecione seu arquivo CSV',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                fileName == null ? 'Clique para procurar no dispositivo' : 'Clique para trocar o arquivo',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final LeadImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final visibleRows = preview.rows.take(8).toList(growable: false);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text('Pré-visualização', style: Theme.of(context).textTheme.titleLarge),
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 17, color: AppColors.primary),
                  label: Text('${preview.validCount} válidas'),
                ),
                if (preview.invalidCount > 0)
                  Chip(
                    avatar: const Icon(Icons.error_outline, size: 17, color: AppColors.danger),
                    label: Text('${preview.invalidCount} inválidas'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Linha')),
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Contato')),
                DataColumn(label: Text('Empresa')),
                DataColumn(label: Text('Origem')),
                DataColumn(label: Text('Validação')),
              ],
              rows: visibleRows.map((LeadImportPreviewRow row) {
                return DataRow(
                  color: row.isValid
                      ? null
                      : WidgetStatePropertyAll<Color>(
                          AppColors.danger.withValues(alpha: 0.04),
                        ),
                  cells: <DataCell>[
                    DataCell(Text(row.line.toString())),
                    DataCell(SizedBox(width: 150, child: Text(row.input.name))),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(row.input.email ?? row.input.phone ?? '—'),
                      ),
                    ),
                    DataCell(Text(row.input.company ?? '—')),
                    DataCell(Text(LeadLabels.source(row.input.source))),
                    DataCell(
                      Row(
                        children: <Widget>[
                          Icon(
                            row.isValid ? Icons.check_circle_outline : Icons.error_outline,
                            size: 17,
                            color: row.isValid ? AppColors.primary : AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 180,
                            child: Text(
                              row.isValid ? 'Pronta' : row.errors.join(' • '),
                              style: TextStyle(
                                color: row.isValid ? AppColors.primary : AppColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(growable: false),
            ),
          ),
          if (preview.rows.length > visibleRows.length)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Exibindo ${visibleRows.length} de ${preview.rows.length} linhas.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportSuccess extends StatelessWidget {
  const _ImportSuccess({
    required this.accepted,
    required this.rejected,
    required this.onFinish,
  });

  final int accepted;
  final int rejected;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: <Widget>[
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE6F7F0),
              foregroundColor: AppColors.primary,
              child: Icon(Icons.check_rounded, size: 32),
            ),
            const SizedBox(height: 14),
            Text('Importação concluída', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '$accepted lead(s) importado(s)${rejected > 0 ? ' e $rejected rejeitado(s)' : ''}.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.groups_2_outlined),
              label: const Text('Ver leads'),
            ),
          ],
        ),
      ),
    );
  }
}
