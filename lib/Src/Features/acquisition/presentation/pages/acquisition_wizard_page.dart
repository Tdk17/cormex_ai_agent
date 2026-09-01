import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/controllers/acquisition_wizard_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class AcquisitionWizardPage extends SignalStatefulWidget {
  const AcquisitionWizardPage({super.key, this.campaignId});

  final String? campaignId;

  @override
  State<AcquisitionWizardPage> createState() => _AcquisitionWizardPageState();
}

class _AcquisitionWizardPageState extends State<AcquisitionWizardPage> {
  static const List<({String title, IconData icon})> _steps =
      <({String title, IconData icon})>[
        (title: 'Produto', icon: Icons.inventory_2_outlined),
        (title: 'Objetivo', icon: Icons.flag_outlined),
        (title: 'Canais', icon: Icons.cell_tower_rounded),
        (title: 'Público', icon: Icons.groups_2_outlined),
        (title: 'Orçamento', icon: Icons.payments_outlined),
        (title: 'Criativo', icon: Icons.auto_awesome_outlined),
        (title: 'Destino', icon: Icons.route_outlined),
        (title: 'Automação', icon: Icons.smart_toy_outlined),
        (title: 'Revisão', icon: Icons.fact_check_outlined),
      ];

  late final AcquisitionWizardController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<AcquisitionWizardController>();
    unawaited(controller.initialize(widget.campaignId));
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    if (state == ScreenState.loading || state == ScreenState.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state == ScreenState.error) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          FormErrorBanner(
            message:
                controller.errorMessage.value ??
                'Não foi possível carregar a campanha.',
            correlationId: controller.correlationId.value,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/acquisition'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar para a Central'),
            ),
          ),
        ],
      );
    }

    final step = controller.currentStep.value;
    return Column(
      children: <Widget>[
        _WizardHeader(
          editing: widget.campaignId != null,
          step: step,
          stepCount: _steps.length,
          onClose: () => context.go('/acquisition'),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final desktop = constraints.maxWidth >= 1020;
              return Form(
                key: ValueKey<int>(controller.formRevision.value),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            width: 238,
                            child: _StepRail(steps: _steps, currentStep: step),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: _StepScroll(child: _stepContent(step)),
                          ),
                          if (constraints.maxWidth >= 1280) ...<Widget>[
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: 310,
                              child: _LiveSummary(controller: controller),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          _MobileStepBar(
                            title: _steps[step].title,
                            icon: _steps[step].icon,
                            step: step,
                            count: _steps.length,
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _StepScroll(child: _stepContent(step)),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
        _WizardFooter(
          step: step,
          lastStep: _steps.length - 1,
          isSaving: controller.isSaving.value,
          isPublishing: controller.isPublishing.value,
          onBack: controller.previousStep,
          onSave: () => controller.saveDraft(),
          onNext: _next,
          onPublish: _publish,
        ),
      ],
    );
  }

  Widget _stepContent(int step) {
    final content = switch (step) {
      0 => _ProductStep(controller: controller),
      1 => _ObjectiveStep(controller: controller),
      2 => _ChannelsStep(controller: controller),
      3 => _AudienceStep(controller: controller),
      4 => _BudgetStep(controller: controller),
      5 => _CreativeStep(controller: controller),
      6 => _DestinationStep(controller: controller),
      7 => _AutomationStep(controller: controller),
      _ => _ReviewStep(controller: controller),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (controller.errorMessage.value != null) ...<Widget>[
          FormErrorBanner(
            message: controller.errorMessage.value!,
            correlationId: controller.correlationId.value,
          ),
          const SizedBox(height: 14),
        ],
        if (controller.successMessage.value != null) ...<Widget>[
          _WizardSuccess(message: controller.successMessage.value!),
          const SizedBox(height: 14),
        ],
        content,
      ],
    );
  }

  void _next() {
    controller.clearFeedback();
    controller.nextStep();
  }

  Future<void> _publish() async {
    controller.clearFeedback();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.rocket_launch_outlined, size: 34),
        title: const Text('Publicar campanha?'),
        content: const Text(
          'O CormeX enviará as configurações aos provedores selecionados. O investimento em mídia será cobrado diretamente pelo Google ou pela Meta.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Revisar novamente'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Autorizar publicação'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.publish();
    if (!mounted) return;
    if (!success) {
      if (controller.requiresGoogleAdsConnection.value) {
        context.go('/integrations');
      }
      return;
    }
    final id = controller.campaign.value?.id;
    context.go(id == null ? '/acquisition' : '/acquisition/$id');
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.editing,
    required this.step,
    required this.stepCount,
    required this.onClose,
  });

  final bool editing;
  final int step;
  final int stepCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  editing ? 'Editar campanha' : 'Nova campanha',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  'Etapa ${step + 1} de $stepCount • o rascunho é salvo durante o fluxo',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.steps, required this.currentStep});

  final List<({String title, IconData icon})> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
        itemCount: steps.length,
        itemBuilder: (BuildContext context, int index) {
          final selected = index == currentStep;
          final completed = index < currentStep;
          final color = selected || completed
              ? AppColors.primary
              : AppColors.textSecondary;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : steps[index].icon,
                    color: color,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[index].title,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MobileStepBar extends StatelessWidget {
  const _MobileStepBar({
    required this.title,
    required this.icon,
    required this.step,
    required this.count,
  });

  final String title;
  final IconData icon;
  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 13),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${step + 1}/$count',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: child,
        ),
      ),
    );
  }
}

class _ProductStep extends SignalWidget {
  const _ProductStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      title: 'O que você quer anunciar?',
      subtitle:
          'Use os dados reais do seu produto ou serviço. Você poderá revisar tudo antes de publicar.',
      children: <Widget>[
        _TextField(
          label: 'Nome da campanha',
          initialValue: controller.name.value,
          hint: 'Ex.: Lançamento Consultoria Setembro',
          onChanged: (String value) => controller.name.value = value,
        ),
        _TextField(
          label: 'Produto ou serviço',
          initialValue: controller.productName.value,
          hint: 'Ex.: CormeX AI Agent',
          onChanged: (String value) => controller.productName.value = value,
        ),
        _TextField(
          label: 'Descrição comercial',
          initialValue: controller.productDescription.value,
          minLines: 3,
          maxLines: 5,
          onChanged: (String value) =>
              controller.productDescription.value = value,
        ),
        _TextField(
          label: 'Oferta ou diferencial',
          initialValue: controller.offer.value,
          hint: 'Ex.: Demonstração gratuita por 7 dias',
          onChanged: (String value) => controller.offer.value = value,
        ),
        _TextField(
          label: 'Página do produto',
          initialValue: controller.productUrl.value,
          hint: 'https://...',
          keyboardType: TextInputType.url,
          onChanged: (String value) => controller.productUrl.value = value,
        ),
        _CampaignMediaPicker(controller: controller),
      ],
    );
  }
}

class _CampaignMediaPicker extends SignalWidget {
  const _CampaignMediaPicker({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final urls = controller.mediaUrls;
    final uploading = controller.isUploadingMedia.value;
    final progress = controller.mediaUploadProgress.value;
    final uploadLabel = controller.mediaUploadLabel.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Imagem ou vídeo do anúncio',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Envie JPG, PNG, WEBP, GIF, MP4, MOV ou WEBM. Máximo de 10 MB por arquivo.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: uploading ? null : () => _pickMedia(context),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Selecionar arquivo'),
              ),
            ],
          ),
          if (uploading) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              uploadLabel == null
                  ? 'Enviando mídia...'
                  : 'Enviando $uploadLabel...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(value: progress <= 0 ? null : progress),
          ],
          const SizedBox(height: 14),
          if (urls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.textSecondary,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhuma mídia adicionada',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Escolha uma imagem ou um vídeo do seu dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...urls.map(
              (String url) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _CampaignMediaTile(
                  url: url,
                  onRemove: uploading
                      ? null
                      : () => controller.removeMedia(url),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickMedia(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
          'mp4',
          'mov',
          'webm',
        ],
      );

      // No file_picker 12, se cancelar retorna uma lista vazia.
      if (files.isEmpty) return;

      for (final PlatformFile file in files) {
        final bytes = await file.readAsBytes();

        final extension = _extensionFromFileName(file.name);
        final contentType = _contentTypeFor(extension);

        if (contentType == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Formato não suportado: ${file.name}')),
            );
          }
          return;
        }

        final success = await controller.uploadMedia(
          fileName: file.name,
          bytes: bytes,
          contentType: contentType,
        );

        if (!success) return;
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar a mídia: $error')),
      );
    }
  }

  static String? _extensionFromFileName(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1 || index == fileName.length - 1) {
      return null;
    }

    return fileName.substring(index + 1).toLowerCase();
  }

  static String? _contentTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => null,
    };
  }
}

class _CampaignMediaTile extends StatelessWidget {
  const _CampaignMediaTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final fileName = _fileName(url);
    final image = _isImage(url);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 62,
              height: 62,
              child: image
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.background,
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 31,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  image ? 'Imagem adicionada' : 'Vídeo adicionado',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover mídia',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  static String _fileName(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    } on FormatException {
      // Mantém fallback abaixo.
    }
    return 'Mídia da campanha';
  }

  static bool _isImage(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}

class _ObjectiveStep extends StatelessWidget {
  const _ObjectiveStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    const options =
        <({String value, String title, String description, IconData icon})>[
          (
            value: 'leads',
            title: 'Gerar leads',
            description: 'Capturar interessados para o CRM.',
            icon: Icons.person_add_alt_1_outlined,
          ),
          (
            value: 'messages',
            title: 'Receber mensagens',
            description: 'Iniciar conversas pelo canal escolhido.',
            icon: Icons.forum_outlined,
          ),
          (
            value: 'conversions',
            title: 'Gerar conversões',
            description: 'Otimizar para uma ação mensurável.',
            icon: Icons.check_circle_outline_rounded,
          ),
          (
            value: 'traffic',
            title: 'Direcionar tráfego',
            description: 'Levar pessoas para uma página.',
            icon: Icons.open_in_new_rounded,
          ),
          (
            value: 'awareness',
            title: 'Divulgar oferta',
            description: 'Aumentar alcance e reconhecimento.',
            icon: Icons.campaign_outlined,
          ),
        ];
    return _StepSection(
      title: 'Qual resultado você quer gerar?',
      subtitle:
          'A escolha orienta a configuração inicial, mas não remove seu controle sobre público e orçamento.',
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final width = constraints.maxWidth >= 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _SelectCard(
                        selected: controller.objective.value == item.value,
                        icon: item.icon,
                        title: item.title,
                        description: item.description,
                        onTap: () => controller.objective.value = item.value,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _ChannelsStep extends SignalWidget {
  const _ChannelsStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final googleSelected = controller.channels.value.contains('google');
    final metaSelected = controller.channels.value.contains('meta');
    return _StepSection(
      title: 'Onde a campanha será publicada?',
      subtitle:
          'Selecione Google Ads, Meta Ads ou os dois. Toque no card para marcar ou desmarcar.',
      children: <Widget>[
        _SelectCard(
          selected: googleSelected,
          icon: Icons.ads_click_rounded,
          title: 'Google Ads',
          description:
              'Pesquisa, display e formatos suportados pelo contrato da conta.',
          trailing: Icon(
            googleSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: googleSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          onTap: () => controller.toggleChannel('google'),
        ),
        _SelectCard(
          selected: metaSelected,
          icon: Icons.campaign_outlined,
          title: 'Meta Ads',
          description:
              'Facebook e Instagram conforme a conta de anúncios selecionada.',
          trailing: Icon(
            metaSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: metaSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          onTap: () => controller.toggleChannel('meta'),
        ),
        const _InfoNote(
          icon: Icons.lock_outline_rounded,
          text:
              'O login ocorre na página oficial do provedor. O CormeX nunca solicita sua senha do Google, Facebook ou Instagram.',
        ),
      ],
    );
  }
}

class _AudienceStep extends StatelessWidget {
  const _AudienceStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      title: 'Quem deve ver esta campanha?',
      subtitle:
          'Comece com uma região e uma faixa coerentes. Públicos muito restritos podem limitar a entrega.',
      children: <Widget>[
        _TextField(
          label: 'Localizações',
          initialValue: controller.locationsText.value,
          hint: 'Ex.: Santa Catarina\nBlumenau, SC',
          minLines: 3,
          maxLines: 5,
          onChanged: (String value) => controller.locationsText.value = value,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _TextField(
                label: 'Idade mínima',
                initialValue: controller.ageMin.value.toString(),
                keyboardType: TextInputType.number,
                onChanged: (String value) =>
                    controller.ageMin.value = int.tryParse(value) ?? 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TextField(
                label: 'Idade máxima',
                initialValue: controller.ageMax.value.toString(),
                keyboardType: TextInputType.number,
                onChanged: (String value) =>
                    controller.ageMax.value = int.tryParse(value) ?? 65,
              ),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          value: controller.broadAudience.value,
          onChanged: (bool value) => controller.broadAudience.value = value,
          contentPadding: EdgeInsets.zero,
          title: const Text('Permitir público amplo'),
          subtitle: const Text(
            'O provedor pode expandir a entrega dentro dos limites definidos.',
          ),
        ),
        _TextField(
          label: 'Interesses e sinais',
          initialValue: controller.interestsText.value,
          hint: 'Um interesse por linha',
          minLines: 3,
          maxLines: 6,
          onChanged: (String value) => controller.interestsText.value = value,
        ),
      ],
    );
  }
}

class _BudgetStep extends StatelessWidget {
  const _BudgetStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    return _StepSection(
      title: 'Quanto e por quanto tempo?',
      subtitle:
          'Este valor é investimento em mídia e será cobrado diretamente pela plataforma de anúncios.',
      children: <Widget>[
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'daily', label: Text('Por dia')),
            ButtonSegment<String>(value: 'total', label: Text('Total')),
          ],
          selected: <String>{controller.budgetType.value},
          showSelectedIcon: false,
          onSelectionChanged: (Set<String> values) =>
              controller.budgetType.value = values.first,
        ),
        _TextField(
          label: controller.budgetType.value == 'daily'
              ? 'Orçamento diário (R\$)'
              : 'Orçamento total (R\$)',
          initialValue: controller.budgetAmount.value.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (String value) => controller.budgetAmount.value =
              double.tryParse(value.replaceAll(',', '.')) ?? 0,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _DateButton(
              label: 'Início',
              value: controller.startAt.value == null
                  ? 'Selecionar data'
                  : date.format(controller.startAt.value!),
              onTap: () => _pickDate(
                context,
                controller.startAt.value,
                (DateTime value) => controller.startAt.value = value,
              ),
            ),
            _DateButton(
              label: 'Término opcional',
              value: controller.endAt.value == null
                  ? 'Execução contínua'
                  : date.format(controller.endAt.value!),
              onTap: () => _pickDate(
                context,
                controller.endAt.value ?? controller.startAt.value,
                (DateTime value) => controller.endAt.value = value,
              ),
              onClear: controller.endAt.value == null
                  ? null
                  : () => controller.endAt.value = null,
            ),
          ],
        ),
        const _InfoNote(
          icon: Icons.credit_card_outlined,
          text:
              'A assinatura do CormeX e o gasto de anúncios são cobranças separadas. O CormeX não movimenta seu saldo sem autorização.',
        ),
      ],
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime> onSelected,
  ) async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (value != null) onSelected(value);
  }
}

class _CreativeStep extends StatelessWidget {
  const _CreativeStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      title: 'Construa o anúncio',
      subtitle:
          'Peça uma sugestão à IA ou escreva manualmente. A versão gerada nunca é publicada sem sua revisão.',
      trailing: OutlinedButton.icon(
        onPressed: controller.isGenerating.value
            ? null
            : () => controller.generateCreative(),
        icon: controller.isGenerating.value
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: const Text('Gerar com IA'),
      ),
      children: <Widget>[
        _TextField(
          label: 'Título',
          initialValue: controller.headline.value,
          maxLength: 90,
          onChanged: (String value) => controller.headline.value = value,
        ),
        _TextField(
          label: 'Texto principal',
          initialValue: controller.primaryText.value,
          minLines: 4,
          maxLines: 7,
          maxLength: 1250,
          onChanged: (String value) => controller.primaryText.value = value,
        ),
        _TextField(
          label: 'Descrição',
          initialValue: controller.description.value,
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          onChanged: (String value) => controller.description.value = value,
        ),
        DropdownButtonFormField<String>(
          initialValue: controller.callToAction.value,
          decoration: const InputDecoration(labelText: 'Chamada para ação'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'LEARN_MORE',
              child: Text('Saiba mais'),
            ),
            DropdownMenuItem<String>(
              value: 'CONTACT_US',
              child: Text('Fale conosco'),
            ),
            DropdownMenuItem<String>(
              value: 'SIGN_UP',
              child: Text('Cadastre-se'),
            ),
            DropdownMenuItem<String>(
              value: 'SHOP_NOW',
              child: Text('Comprar agora'),
            ),
            DropdownMenuItem<String>(
              value: 'SEND_MESSAGE',
              child: Text('Enviar mensagem'),
            ),
          ],
          onChanged: (String? value) {
            if (value != null) controller.callToAction.value = value;
          },
        ),
        if (controller.aiRationale.value case final rationale?)
          _InfoNote(icon: Icons.psychology_outlined, text: rationale),
        if (controller.aiWarnings.value.isNotEmpty)
          _InfoNote(
            icon: Icons.warning_amber_rounded,
            text: controller.aiWarnings.value.join('\n'),
            warning: true,
          ),
      ],
    );
  }
}

class _DestinationStep extends StatelessWidget {
  const _DestinationStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      title: 'Para onde o interessado será enviado?',
      subtitle:
          'Escolha um destino compatível com o objetivo e capture somente os dados necessários.',
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: controller.destinationType.value,
          decoration: const InputDecoration(labelText: 'Destino'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'whatsapp',
              child: Text('Conversa / WhatsApp'),
            ),
            DropdownMenuItem<String>(
              value: 'landing_page',
              child: Text('Landing page'),
            ),
            DropdownMenuItem<String>(
              value: 'form',
              child: Text('Formulário de lead'),
            ),
            DropdownMenuItem<String>(
              value: 'product_page',
              child: Text('Página do produto'),
            ),
          ],
          onChanged: (String? value) {
            if (value != null) controller.destinationType.value = value;
          },
        ),
        if (controller.destinationType.value != 'whatsapp')
          _TextField(
            label: 'URL de destino',
            initialValue: controller.destinationUrl.value,
            hint: 'https://...',
            keyboardType: TextInputType.url,
            onChanged: (String value) =>
                controller.destinationUrl.value = value,
          ),
        if (controller.destinationType.value == 'form') ...<Widget>[
          const Text(
            'Campos do formulário',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                <({String value, String label})>[
                      (value: 'name', label: 'Nome'),
                      (value: 'phone', label: 'Telefone'),
                      (value: 'email', label: 'E-mail'),
                      (value: 'region', label: 'Região'),
                      (value: 'interest', label: 'Interesse'),
                      (value: 'qualification', label: 'Qualificação'),
                    ]
                    .map(
                      (item) => FilterChip(
                        selected: controller.captureFields.value.contains(
                          item.value,
                        ),
                        label: Text(item.label),
                        onSelected: (bool selected) =>
                            controller.setCaptureField(item.value, selected),
                      ),
                    )
                    .toList(growable: false),
          ),
          _TextField(
            label: 'Texto de consentimento',
            initialValue: controller.consentText.value,
            minLines: 2,
            maxLines: 4,
            onChanged: (String value) => controller.consentText.value = value,
          ),
        ],
      ],
    );
  }
}

class _AutomationStep extends StatelessWidget {
  const _AutomationStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      title: 'O que acontece depois que o lead chegar?',
      subtitle:
          'Conecte aquisição à operação comercial sem duplicar Leads, Conversas ou Pipeline.',
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.onlyRegisterLead.value,
          onChanged: (bool value) => controller.onlyRegisterLead.value = value,
          title: const Text('Apenas registrar o lead'),
          subtitle: const Text(
            'Não iniciar conversa automática após a captura.',
          ),
        ),
        if (!controller.onlyRegisterLead.value) ...<Widget>[
          _TextField(
            label: 'Mensagem inicial',
            initialValue: controller.initialMessage.value,
            minLines: 3,
            maxLines: 6,
            onChanged: (String value) =>
                controller.initialMessage.value = value,
          ),
          _TextField(
            label: 'Perguntas de qualificação',
            initialValue: controller.qualificationQuestionsText.value,
            hint: 'Uma pergunta por linha',
            minLines: 3,
            maxLines: 7,
            onChanged: (String value) =>
                controller.qualificationQuestionsText.value = value,
          ),
        ],
        DropdownButtonFormField<String>(
          initialValue: controller.pipelineStageId.value,
          decoration: const InputDecoration(
            labelText: 'Etapa inicial do Pipeline',
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'new_lead',
              child: Text('Novo lead'),
            ),
            DropdownMenuItem<String>(
              value: 'contacted',
              child: Text('Contato feito'),
            ),
            DropdownMenuItem<String>(
              value: 'proposal',
              child: Text('Proposta enviada'),
            ),
          ],
          onChanged: (String? value) {
            if (value != null) controller.pipelineStageId.value = value;
          },
        ),
        _TextField(
          label: 'Tags e origem',
          initialValue: controller.tagsText.value,
          hint: 'Uma tag por linha',
          minLines: 2,
          maxLines: 5,
          onChanged: (String value) => controller.tagsText.value = value,
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return _StepSection(
      title: 'Revise antes de publicar',
      subtitle:
          'A publicação só será solicitada depois da sua autorização explícita.',
      children: <Widget>[
        _ReviewGroup(
          title: 'Campanha e produto',
          items: <({String label, String value})>[
            (label: 'Campanha', value: controller.name.value),
            (label: 'Produto', value: controller.productName.value),
            (label: 'Oferta', value: _fallback(controller.offer.value)),
            (
              label: 'Objetivo',
              value: _objectiveLabel(controller.objective.value),
            ),
          ],
        ),
        _ReviewGroup(
          title: 'Distribuição',
          items: <({String label, String value})>[
            (
              label: 'Canais',
              value: controller.channels.value.map(_providerLabel).join(' + '),
            ),
            (
              label: 'Região',
              value: _fallback(
                controller.locationsText.value.replaceAll('\n', ', '),
              ),
            ),
            (
              label: 'Público',
              value:
                  '${controller.ageMin.value} a ${controller.ageMax.value} anos',
            ),
            (
              label: 'Interesses',
              value: _fallback(
                controller.interestsText.value.replaceAll('\n', ', '),
              ),
            ),
          ],
        ),
        _ReviewGroup(
          title: 'Investimento',
          items: <({String label, String value})>[
            (
              label: 'Orçamento',
              value:
                  '${currency.format(controller.budgetAmount.value)} ${controller.budgetType.value == 'daily' ? 'por dia' : 'total'}',
            ),
            (
              label: 'Início',
              value: controller.startAt.value == null
                  ? 'Não informado'
                  : date.format(controller.startAt.value!),
            ),
            (
              label: 'Término',
              value: controller.endAt.value == null
                  ? 'Execução contínua'
                  : date.format(controller.endAt.value!),
            ),
            (label: 'Cobrança', value: 'Direta pelo provedor de anúncios'),
          ],
        ),
        _ReviewGroup(
          title: 'Criativo e destino',
          items: <({String label, String value})>[
            (
              label: 'Mídias',
              value: controller.mediaUrls.isEmpty
                  ? 'Nenhuma'
                  : '${controller.mediaUrls.length} arquivo(s)',
            ),
            (label: 'Título', value: _fallback(controller.headline.value)),
            (label: 'Texto', value: _fallback(controller.primaryText.value)),
            (
              label: 'Destino',
              value: _destinationLabel(controller.destinationType.value),
            ),
            (
              label: 'Automação',
              value: controller.onlyRegisterLead.value
                  ? 'Apenas registrar lead'
                  : 'Iniciar atendimento com IA',
            ),
          ],
        ),
        const _InfoNote(
          icon: Icons.verified_user_outlined,
          text:
              'Ao autorizar, o backend validará conta, permissões, forma de pagamento, criativos, orçamento e versão do rascunho antes de publicar.',
        ),
      ],
    );
  }

  static String _fallback(String value) =>
      value.trim().isEmpty ? 'Não informado' : value.trim();
  static String _providerLabel(String value) => value == 'google'
      ? 'Google Ads'
      : value == 'meta'
      ? 'Meta Ads'
      : value;
  static String _objectiveLabel(String value) => switch (value) {
    'leads' => 'Gerar leads',
    'messages' => 'Receber mensagens',
    'conversions' => 'Gerar conversões',
    'traffic' => 'Direcionar tráfego',
    'awareness' => 'Divulgar oferta',
    _ => value,
  };
  static String _destinationLabel(String value) => switch (value) {
    'whatsapp' => 'Conversa / WhatsApp',
    'landing_page' => 'Landing page',
    'form' => 'Formulário de lead',
    'product_page' => 'Página do produto',
    _ => value,
  };
}

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 24),
        ...children.expand(
          (Widget item) => <Widget>[item, const SizedBox(height: 15)],
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.helper,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final String? hint;
  final String? helper;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: OutlinedButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(value),
              ],
            ),
            if (onClear != null) ...<Widget>[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Limpar data',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.blue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({required this.title, required this.items});

  final String title;
  final List<({String label, String value})> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 112,
                      child: Text(
                        item.label,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSummary extends StatelessWidget {
  const _LiveSummary({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text(
            'Resumo ao vivo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 18),
          _SummaryLine(label: 'Campanha', value: controller.name.value),
          _SummaryLine(label: 'Produto', value: controller.productName.value),
          _SummaryLine(
            label: 'Canais',
            value: controller.channels.value.join(' + '),
          ),
          _SummaryLine(
            label: 'Orçamento',
            value: currency.format(controller.budgetAmount.value),
          ),
          _SummaryLine(label: 'Título', value: controller.headline.value),
          _SummaryLine(
            label: 'Destino',
            value: controller.destinationType.value,
          ),
          const SizedBox(height: 18),
          const _InfoNote(
            icon: Icons.auto_awesome_outlined,
            text:
                'A IA pode sugerir configurações, mas publicar e alterar investimento sempre exigem sua autorização.',
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? 'Não informado' : value.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.step,
    required this.lastStep,
    required this.isSaving,
    required this.isPublishing,
    required this.onBack,
    required this.onSave,
    required this.onNext,
    required this.onPublish,
  });

  final int step;
  final int lastStep;
  final bool isSaving;
  final bool isPublishing;
  final VoidCallback onBack;
  final Future<bool> Function() onSave;
  final VoidCallback onNext;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 620;
          final saveButton = OutlinedButton.icon(
            onPressed: isSaving || isPublishing ? null : () => onSave(),
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_outlined),
            label: Text(compact ? 'Salvar' : 'Salvar rascunho'),
          );
          final nextButton = step < lastStep
              ? FilledButton.icon(
                  onPressed: isSaving || isPublishing ? null : onNext,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continuar'),
                )
              : FilledButton.icon(
                  onPressed: isSaving || isPublishing
                      ? null
                      : () => onPublish(),
                  icon: isPublishing
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rocket_launch_outlined),
                  label: Text(compact ? 'Publicar' : 'Publicar campanha'),
                );
          if (compact) {
            return Row(
              children: <Widget>[
                if (step > 0)
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: isSaving || isPublishing ? null : onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(child: saveButton),
                const SizedBox(width: 8),
                Expanded(child: nextButton),
              ],
            );
          }
          return Row(
            children: <Widget>[
              if (step > 0)
                TextButton.icon(
                  onPressed: isSaving || isPublishing ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar'),
                ),
              const Spacer(),
              saveButton,
              const SizedBox(width: 10),
              nextButton,
            ],
          );
        },
      ),
    );
  }
}

class _WizardSuccess extends StatelessWidget {
  const _WizardSuccess({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
