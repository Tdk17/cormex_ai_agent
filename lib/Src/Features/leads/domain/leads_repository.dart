import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_result.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_page.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

abstract interface class LeadsRepository {
  Future<LeadPage> list({
    required String workspaceId,
    required LeadFilters filters,
    String? cursor,
    int limit = 20,
  });

  Future<LeadModel> get({
    required String workspaceId,
    required String leadId,
  });

  Future<LeadModel> create({
    required String workspaceId,
    required LeadInput input,
  });

  Future<LeadModel> update({
    required String workspaceId,
    required String leadId,
    required LeadInput input,
  });

  Future<LeadImportResult> import({
    required String workspaceId,
    required List<Map<String, dynamic>> rows,
  });
}
