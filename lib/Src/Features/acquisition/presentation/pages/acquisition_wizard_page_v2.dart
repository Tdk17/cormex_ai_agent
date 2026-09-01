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
  static const _steps = <({String label, IconData icon})>[
    (label: 'Produto', icon: Icons.inventory_2_outlined),
    (label: 'Objetivo', icon: Icons.flag_outlined),
    (label: 'Canais', icon: Icons.cell_tower_rounded),
    (label: 'Público', icon: Icons.groups_2_outlined),
    (label: 'Orçamento', icon: Icons.payments_outlined),
    (label: 'Criativo', icon: Icons.auto_awesome_outlined),
    (label: 'Destino', icon: Icons.route_outlined),
    (label: 'Automação', icon: Icons.smart_toy_outlined),
    (label: 'Revisão', icon: Icons.fact_check_outlined),
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
    final step = controller.currentStep.value;
    final error = controller.errorMessage.value;
    final success = controller.successMessage.value;
    final saving = controller.isSaving.value;
    final publishing = controller.isPublishing.value;

    if (state == ScreenState.initial || state == ScreenState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == ScreenState.error && controller.campaign.value == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          FormErrorBanner(
            message: error ?? 'Não foi possível carregar a campanha.',
            correlationId: controller.correlationId.value,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/acquisition'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        _Header(
          editing: widget.campaignId != null,
          step: step,
          total: _steps.length,
          onClose: () => context.go('/acquisition'),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 1000;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (desktop)
                    SizedBox(
                      width: 220,
                      child: _StepRail(
                        steps: _steps,
                        currentStep: step,
                      ),
                    ),
                  if (desktop) const VerticalDivider(width: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 50),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (!desktop) ...<Widget>[
                                _MobileStep(
                                  icon: _steps[step].icon,
                                  label: _steps[step].label,
                                  step: step,
                                  total: _steps.length,
                                ),
                                const SizedBox(height: 18),
                              ],
                              if (error != null) ...<Widget>[
                                FormErrorBanner(
                                  message: error,
                                  correlationId: controller.correlationId.value,
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (success != null) ...<Widget>[
                                _SuccessBanner(message: success),
                                const SizedBox(height: 14),
                              ],
                              _WizardStep(
                                controller: controller,
                                step: step,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _Footer(
          step: step,
          lastStep: _steps.length - 1,
          saving: saving,
          publishing: publishing,
          onBack: controller.previousStep,
          onSave: () => controller.saveDraft(),
          onNext: () {
            controller.clearFeedback();
            controller.nextStep();
          },
          onPublish: _publish,
        ),
      ],
    );
  }

  Future<void> _publish() async {
    controller.clearFeedback();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.rocket_launch_outlined, size: 34),
        title: const Text('Publicar campanha?'),
        content: const Text(
          'O CormeX solicitará a publicação nos canais selecionados. O investimento em mídia continua sendo cobrado pelo provedor de anúncios.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Autorizar publicação'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.publish();
    if (!mounted || !ok) return;
    final campaignId = controller.campaign.value?.id;
    context.go(campaignId == null ? '/acquisition' : '/acquisition/$campaignId');
  }
}

class _WizardStep extends SignalWidget {
  const _WizardStep({required this.controller, required this.step});

  final AcquisitionWizardController controller;
  final int step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
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
  }
}

class _ProductStep extends SignalWidget {
  const _ProductStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'O que você quer anunciar?',
      subtitle: 'Cadastre o produto e envie a imagem ou o vídeo que será usado na campanha.',
      children: <Widget>[
        _Field(
          label: 'Nome da campanha',
          initialValue: controller.name.value,
          hint: 'Ex.: Campanha Setembro',
          onChanged: (value) => controller.name.value = value,
        ),
        _Field(
          label: 'Produto ou serviço',
          initialValue: controller.productName.value,
          hint: 'Ex.: CormeX AI Agent',
          onChanged: (value) => controller.productName.value = value,
        ),
        _Field(
          label: 'Descrição comercial',
          initialValue: controller.productDescription.value,
          minLines: 3,
          maxLines: 5,
          onChanged: (value) => controller.productDescription.value = value,
        ),
        _Field(
          label: 'Oferta ou diferencial',
          initialValue: controller.offer.value,
          onChanged: (value) => controller.offer.value = value,
        ),
        _Field(
          label: 'Página do produto (opcional)',
          initialValue: controller.productUrl.value,
          hint: 'https://...',
          keyboardType: TextInputType.url,
          onChanged: (value) => controller.productUrl.value = value,
        ),
        _MediaPicker(controller: controller),
      ],
    );
  }
}

class _MediaPicker extends SignalWidget {
  const _MediaPicker({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final urls = controller.mediaUrls;
    final uploading = controller.isUploadingMedia.value;
    final progress = controller.mediaUploadProgress.value;
    final label = controller.mediaUploadLabel.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'JPG, PNG, WEBP, GIF, MP4, MOV ou WEBM. Até 10 MB por arquivo.',
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
                onPressed: uploading ? null : () => _pick(context),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Selecionar'),
              ),
            ],
          ),
          if (uploading) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              label == null ? 'Enviando mídia...' : 'Enviando $label...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress > 0 ? progress : null),
          ],
          const SizedBox(height: 14),
          if (urls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhuma mídia adicionada',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Escolha uma imagem ou vídeo do seu dispositivo.',
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
              (url) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _MediaTile(
                  url: url,
                  onRemove: uploading ? null : () => controller.removeMedia(url),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
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
    if (files.isEmpty) return;

    for (final file in files) {
      try {
        final contentType = _contentType(_extension(file.name));
        if (contentType == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Formato não suportado: ${file.name}')),
            );
          }
          return;
        }
        final bytes = await file.readAsBytes();
        final ok = await controller.uploadMedia(
          fileName: file.name,
          bytes: bytes,
          contentType: contentType,
        );
        if (!ok) return;
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível ler ${file.name}.')),
          );
        }
        return;
      }
    }
  }

  static String? _extension(String name) {
    final index = name.lastIndexOf('.');
    if (index < 0 || index == name.length - 1) return null;
    return name.substring(index + 1).toLowerCase();
  }

  static String? _contentType(String? extension) => switch (extension) {
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

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.url, this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final image = _looksLikeImage(url);
    final name = Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'Mídia da campanha';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
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
                        child: Icon(Icons.image_outlined),
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
                  name,
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
            onPressed: onRemove,
            tooltip: 'Remover',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  static bool _looksLikeImage(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

class _ObjectiveStep extends SignalWidget {
  const _ObjectiveStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    const options = <({String value, String label, IconData icon})>[
      (value: 'leads', label: 'Gerar leads', icon: Icons.person_add_alt_1_outlined),
      (value: 'messages', label: 'Receber mensagens', icon: Icons.forum_outlined),
      (value: 'conversions', label: 'Gerar conversões', icon: Icons.trending_up_rounded),
      (value: 'traffic', label: 'Gerar tráfego', icon: Icons.open_in_new_rounded),
      (value: 'awareness', label: 'Divulgar oferta', icon: Icons.campaign_outlined),
    ];
    return _Section(
      title: 'Qual resultado você quer gerar?',
      subtitle: 'Escolha o objetivo principal da campanha.',
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options
              .map(
                (item) => _ChoiceCard(
                  selected: controller.objective.value == item.value,
                  icon: item.icon,
                  title: item.label,
                  onTap: () => controller.objective.value = item.value,
                ),
              )
              .toList(growable: false),
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
    final google = controller.channels.value.contains('google');
    final meta = controller.channels.value.contains('meta');
    return _Section(
      title: 'Onde a campanha será publicada?',
      subtitle: 'Você pode escolher Google Ads, Meta Ads ou os dois.',
      children: <Widget>[
        _ChannelCard(
          selected: google,
          icon: Icons.ads_click_rounded,
          title: 'Google Ads',
          description: 'Pesquisa, display e formatos suportados pela conta conectada.',
          onTap: () => controller.toggleChannel('google'),
        ),
        _ChannelCard(
          selected: meta,
          icon: Icons.campaign_outlined,
          title: 'Meta Ads',
          description: 'Facebook e Instagram pela conta de anúncios conectada.',
          onTap: () => controller.toggleChannel('meta'),
        ),
        const _Note(
          icon: Icons.lock_outline_rounded,
          text: 'Para publicar no Google Ads, primeiro conecte sua conta em Integrações usando o login oficial do Google.',
        ),
      ],
    );
  }
}

class _AudienceStep extends SignalWidget {
  const _AudienceStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Defina o público',
      subtitle: 'Informe região, idade e interesses da audiência.',
      children: <Widget>[
        _Field(
          label: 'Localizações',
          initialValue: controller.locationsText.value,
          hint: 'Ex.: Santa Catarina\nBlumenau, SC',
          minLines: 3,
          maxLines: 5,
          onChanged: (value) => controller.locationsText.value = value,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _Field(
                label: 'Idade mínima',
                initialValue: controller.ageMin.value.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) => controller.ageMin.value = int.tryParse(value) ?? 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'Idade máxima',
                initialValue: controller.ageMax.value.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) => controller.ageMax.value = int.tryParse(value) ?? 65,
              ),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.broadAudience.value,
          onChanged: (value) => controller.broadAudience.value = value,
          title: const Text('Permitir público amplo'),
          subtitle: const Text('O provedor pode otimizar a entrega dentro dos limites informados.'),
        ),
        _Field(
          label: 'Interesses e sinais',
          initialValue: controller.interestsText.value,
          hint: 'Um interesse por linha',
          minLines: 3,
          maxLines: 6,
          onChanged: (value) => controller.interestsText.value = value,
        ),
      ],
    );
  }
}

class _BudgetStep extends SignalWidget {
  const _BudgetStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    return _Section(
      title: 'Orçamento e período',
      subtitle: 'O valor de mídia será cobrado diretamente pelo provedor de anúncios.',
      children: <Widget>[
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment(value: 'daily', label: Text('Por dia')),
            ButtonSegment(value: 'total', label: Text('Total')),
          ],
          selected: <String>{controller.budgetType.value},
          showSelectedIcon: false,
          onSelectionChanged: (values) => controller.budgetType.value = values.first,
        ),
        _Field(
          label: controller.budgetType.value == 'daily'
              ? 'Orçamento diário (R\$)'
              : 'Orçamento total (R\$)',
          initialValue: controller.budgetAmount.value.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => controller.budgetAmount.value =
              double.tryParse(value.replaceAll(',', '.')) ?? 0,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () => _pickDate(
                context,
                controller.startAt.value,
                (value) => controller.startAt.value = value,
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                controller.startAt.value == null
                    ? 'Selecionar início'
                    : 'Início: ${format.format(controller.startAt.value!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDate(
                context,
                controller.endAt.value ?? controller.startAt.value,
                (value) => controller.endAt.value = value,
              ),
              icon: const Icon(Icons.event_outlined),
              label: Text(
                controller.endAt.value == null
                    ? 'Término opcional'
                    : 'Término: ${format.format(controller.endAt.value!)}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(
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

class _CreativeStep extends SignalWidget {
  const _CreativeStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Crie o anúncio',
      subtitle: 'Use a IA como sugestão e revise o texto antes de publicar.',
      trailing: OutlinedButton.icon(
        onPressed: controller.isGenerating.value ? null : controller.generateCreative,
        icon: controller.isGenerating.value
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: const Text('Gerar com IA'),
      ),
      children: <Widget>[
        _Field(
          label: 'Título',
          initialValue: controller.headline.value,
          onChanged: (value) => controller.headline.value = value,
        ),
        _Field(
          label: 'Texto principal',
          initialValue: controller.primaryText.value,
          minLines: 4,
          maxLines: 7,
          onChanged: (value) => controller.primaryText.value = value,
        ),
        _Field(
          label: 'Descrição',
          initialValue: controller.description.value,
          minLines: 2,
          maxLines: 4,
          onChanged: (value) => controller.description.value = value,
        ),
        DropdownButtonFormField<String>(
          initialValue: controller.callToAction.value,
          decoration: const InputDecoration(labelText: 'Chamada para ação'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'LEARN_MORE', child: Text('Saiba mais')),
            DropdownMenuItem(value: 'CONTACT_US', child: Text('Fale conosco')),
            DropdownMenuItem(value: 'SIGN_UP', child: Text('Cadastre-se')),
            DropdownMenuItem(value: 'SHOP_NOW', child: Text('Comprar agora')),
            DropdownMenuItem(value: 'SEND_MESSAGE', child: Text('Enviar mensagem')),
          ],
          onChanged: (value) {
            if (value != null) controller.callToAction.value = value;
          },
        ),
      ],
    );
  }
}

class _DestinationStep extends SignalWidget {
  const _DestinationStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Destino do lead',
      subtitle: 'Defina para onde a pessoa será enviada após clicar no anúncio.',
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: controller.destinationType.value,
          decoration: const InputDecoration(labelText: 'Destino'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'whatsapp', child: Text('Conversa / WhatsApp')),
            DropdownMenuItem(value: 'landing_page', child: Text('Landing page')),
            DropdownMenuItem(value: 'form', child: Text('Formulário de lead')),
            DropdownMenuItem(value: 'product_page', child: Text('Página do produto')),
          ],
          onChanged: (value) {
            if (value != null) controller.destinationType.value = value;
          },
        ),
        if (controller.destinationType.value != 'whatsapp')
          _Field(
            label: 'URL de destino',
            initialValue: controller.destinationUrl.value,
            hint: 'https://...',
            keyboardType: TextInputType.url,
            onChanged: (value) => controller.destinationUrl.value = value,
          ),
        if (controller.destinationType.value == 'form') ...<Widget>[
          const Text('Campos do formulário', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <({String value, String label})>[
              (value: 'name', label: 'Nome'),
              (value: 'phone', label: 'Telefone'),
              (value: 'email', label: 'E-mail'),
              (value: 'region', label: 'Região'),
            ].map((item) {
              return const SizedBox.shrink();
            }).toList(),
          ),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final item in const <({String value, String label})>[
                (value: 'name', label: 'Nome'),
                (value: 'phone', label: 'Telefone'),
                (value: 'email', label: 'E-mail'),
                (value: 'region', label: 'Região'),
              ])
                FilterChip(
                  selected: controller.captureFields.value.contains(item.value),
                  label: Text(item.label),
                  onSelected: (selected) => controller.setCaptureField(item.value, selected),
                ),
            ],
          ),
          _Field(
            label: 'Texto de consentimento',
            initialValue: controller.consentText.value,
            minLines: 2,
            maxLines: 4,
            onChanged: (value) => controller.consentText.value = value,
          ),
        ],
      ],
    );
  }
}

class _AutomationStep extends SignalWidget {
  const _AutomationStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Automação comercial',
      subtitle: 'Defina o que o CormeX fará quando o lead entrar.',
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: controller.onlyRegisterLead.value,
          onChanged: (value) => controller.onlyRegisterLead.value = value,
          title: const Text('Apenas registrar o lead'),
          subtitle: const Text('Não iniciar conversa automática.'),
        ),
        if (!controller.onlyRegisterLead.value) ...<Widget>[
          _Field(
            label: 'Mensagem inicial',
            initialValue: controller.initialMessage.value,
            minLines: 3,
            maxLines: 6,
            onChanged: (value) => controller.initialMessage.value = value,
          ),
          _Field(
            label: 'Perguntas de qualificação',
            initialValue: controller.qualificationQuestionsText.value,
            hint: 'Uma pergunta por linha',
            minLines: 3,
            maxLines: 7,
            onChanged: (value) => controller.qualificationQuestionsText.value = value,
          ),
        ],
        _Field(
          label: 'Tags',
          initialValue: controller.tagsText.value,
          hint: 'Uma tag por linha',
          minLines: 2,
          maxLines: 5,
          onChanged: (value) => controller.tagsText.value = value,
        ),
      ],
    );
  }
}

class _ReviewStep extends SignalWidget {
  const _ReviewStep({required this.controller});

  final AcquisitionWizardController controller;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return _Section(
      title: 'Revise antes de publicar',
      subtitle: 'Confirme produto, mídia, canais e orçamento.',
      children: <Widget>[
        _ReviewCard(
          rows: <({String label, String value})>[
            (label: 'Campanha', value: _fallback(controller.name.value)),
            (label: 'Produto', value: _fallback(controller.productName.value)),
            (label: 'Canais', value: controller.channels.value.map(_channelLabel).join(' + ')),
            (label: 'Mídias', value: '${controller.mediaUrls.length} arquivo(s)'),
            (label: 'Orçamento', value: currency.format(controller.budgetAmount.value)),
            (label: 'Destino', value: controller.destinationType.value),
            (label: 'Automação', value: controller.onlyRegisterLead.value ? 'Apenas registrar lead' : 'Atendimento automático'),
          ],
        ),
        const _Note(
          icon: Icons.verified_user_outlined,
          text: 'A publicação só acontece depois da sua autorização e da validação da conta conectada no provedor.',
        ),
      ],
    );
  }

  static String _fallback(String value) => value.trim().isEmpty ? 'Não informado' : value.trim();
  static String _channelLabel(String value) => value == 'google' ? 'Google Ads' : value == 'meta' ? 'Meta Ads' : value;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.editing,
    required this.step,
    required this.total,
    required this.onClose,
  });

  final bool editing;
  final int step;
  final int total;
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
                  'Etapa ${step + 1} de $total',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.steps, required this.currentStep});

  final List<({String label, IconData icon})> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final selected = index == currentStep;
          final completed = index < currentStep;
          final color = selected || completed ? AppColors.primary : AppColors.textSecondary;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(completed ? Icons.check_rounded : steps[index].icon, color: color, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    steps[index].label,
                    style: TextStyle(color: color, fontWeight: selected ? FontWeight.w800 : FontWeight.w600),
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

class _MobileStep extends StatelessWidget {
  const _MobileStep({required this.icon, required this.label, required this.step, required this.total});

  final IconData icon;
  final String label;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        Text('${step + 1}/$total', style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, required this.children, this.trailing});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 24),
        for (final child in children) ...<Widget>[child, const SizedBox(height: 15)],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final String? hint;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: maxLines > 1),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.selected, required this.icon, required this.title, required this.onTap});

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: _ChannelCard(
        selected: selected,
        icon: icon,
        title: title,
        description: selected ? 'Selecionado' : 'Clique para selecionar',
        onTap: onTap,
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.selected, required this.icon, required this.title, required this.description, required this.onTap});

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
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
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rows});

  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: rows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 110,
                        child: Text(row.label, style: const TextStyle(color: AppColors.textSecondary)),
                      ),
                      Expanded(child: Text(row.value, style: const TextStyle(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.lastStep,
    required this.saving,
    required this.publishing,
    required this.onBack,
    required this.onSave,
    required this.onNext,
    required this.onPublish,
  });

  final int step;
  final int lastStep;
  final bool saving;
  final bool publishing;
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
      child: Row(
        children: <Widget>[
          if (step > 0)
            TextButton.icon(
              onPressed: saving || publishing ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar'),
            ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: saving || publishing ? null : () => onSave(),
            icon: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_done_outlined),
            label: const Text('Salvar rascunho'),
          ),
          const SizedBox(width: 10),
          if (step < lastStep)
            FilledButton.icon(
              onPressed: saving || publishing ? null : onNext,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continuar'),
            )
          else
            FilledButton.icon(
              onPressed: saving || publishing ? null : () => onPublish(),
              icon: publishing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_outlined),
              label: const Text('Publicar campanha'),
            ),
        ],
      ),
    );
  }
}
