import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/data/csv_lead_parser.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_preview.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_result.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/leads_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signals/signals.dart';

class LeadImportController {
  LeadImportController(
    this._parser,
    this._repository,
    this._authController,
    this._leadsController,
  );

  final CsvLeadParser _parser;
  final LeadsRepository _repository;
  final AuthController _authController;
  final LeadsController _leadsController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<String?> fileName = signal<String?>(null);
  final Signal<LeadImportPreview?> preview = signal<LeadImportPreview?>(null);
  final Signal<LeadImportResult?> result = signal<LeadImportResult?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> pickCsv() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final parsed = _parser.parse(bytes);
      batch(() {
        fileName.value = file.name;
        preview.value = parsed;
        result.value = null;
        errorMessage.value = null;
        state.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível ler o arquivo CSV.';
        state.value = ScreenState.error;
      });
    }
  }

  Future<bool> importValidRows() async {
    final workspaceId = _authController.session.value?.selectedWorkspace?.id;
    final currentPreview = preview.value;
    if (workspaceId == null || currentPreview == null) return false;
    if (currentPreview.validCount == 0) {
      errorMessage.value = 'Corrija o CSV: nenhuma linha válida para importar.';
      return false;
    }

    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final importResult = await _repository.import(
        workspaceId: workspaceId,
        rows: currentPreview.validPayload,
      );
      batch(() {
        result.value = importResult;
        state.value = ScreenState.success;
      });
      await _leadsController.load(force: true);
      return true;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível importar os leads.';
        state.value = ScreenState.error;
      });
    }
    return false;
  }
}
