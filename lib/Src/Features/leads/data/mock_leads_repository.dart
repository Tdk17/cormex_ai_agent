import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_result.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class MockLeadsRepository implements LeadsRepository {
  final List<LeadModel> _items = <LeadModel>[];
  final Set<String> _seededWorkspaces = <String>{};
  int _sequence = 1000;

  @override
  Future<LeadPage> list({
    required String workspaceId,
    required LeadFilters filters,
    String? cursor,
    int limit = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _ensureSeed(workspaceId);

    final search = filters.search.trim().toLowerCase();
    final filtered = _items.where((LeadModel lead) {
      if (lead.workspaceId != workspaceId) return false;
      final haystack = <String?>[
        lead.name,
        lead.email,
        lead.phone,
        lead.company,
        ...lead.tags,
      ].whereType<String>().join(' ').toLowerCase();
      return (search.isEmpty || haystack.contains(search)) &&
          (filters.status == null || lead.status == filters.status) &&
          (filters.source == null || lead.source == filters.source) &&
          (filters.tag == null || lead.tags.contains(filters.tag));
    }).toList(growable: false)
      ..sort((LeadModel a, LeadModel b) => b.updatedAt.compareTo(a.updatedAt));

    final start = (int.tryParse(cursor ?? '') ?? 0).clamp(0, filtered.length).toInt();
    final end = (start + limit).clamp(0, filtered.length).toInt();
    return LeadPage(
      items: filtered.sublist(start, end),
      nextCursor: end < filtered.length ? end.toString() : null,
      correlationId: 'mock-leads-list',
    );
  }

  @override
  Future<LeadModel> get({
    required String workspaceId,
    required String leadId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _ensureSeed(workspaceId);
    return _find(workspaceId, leadId);
  }

  @override
  Future<LeadModel> create({
    required String workspaceId,
    required LeadInput input,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _ensureSeed(workspaceId);
    return _createNow(workspaceId, input);
  }

  @override
  Future<LeadModel> update({
    required String workspaceId,
    required String leadId,
    required LeadInput input,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final current = _find(workspaceId, leadId);
    final updated = LeadModel(
      id: current.id,
      workspaceId: current.workspaceId,
      name: input.name.trim(),
      phone: input.phone,
      email: input.email,
      company: input.company,
      source: input.source,
      status: input.status,
      tags: input.tags,
      ownerId: input.ownerId,
      score: input.score,
      lastContactAt: current.lastContactAt,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _items[_items.indexWhere((LeadModel lead) => lead.id == leadId)] = updated;
    return updated;
  }

  @override
  Future<LeadImportResult> import({
    required String workspaceId,
    required List<Map<String, dynamic>> rows,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _ensureSeed(workspaceId);
    for (final row in rows) {
      _createNow(workspaceId, LeadInput.fromJson(row));
    }
    return LeadImportResult(
      total: rows.length,
      accepted: rows.length,
      rejected: 0,
      jobId: 'mock-import-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  LeadModel _createNow(String workspaceId, LeadInput input) {
    final now = DateTime.now();
    final lead = LeadModel(
      id: 'lead_${_sequence++}',
      workspaceId: workspaceId,
      name: input.name.trim(),
      phone: input.phone,
      email: input.email,
      company: input.company,
      source: input.source,
      status: input.status,
      tags: input.tags,
      ownerId: input.ownerId,
      score: input.score,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(lead);
    return lead;
  }

  LeadModel _find(String workspaceId, String leadId) {
    final index = _items.indexWhere(
      (LeadModel lead) => lead.workspaceId == workspaceId && lead.id == leadId,
    );
    if (index < 0) {
      throw const ApiException(code: 'NOT_FOUND', message: 'Lead não encontrado.');
    }
    return _items[index];
  }

  void _ensureSeed(String workspaceId) {
    if (!_seededWorkspaces.add(workspaceId)) return;
    const names = <String>[
      'Marina Souza',
      'Rafael Lima',
      'Camila Martins',
      'Bruno Rocha',
      'Fernanda Alves',
      'Lucas Mendes',
      'Patrícia Gomes',
      'Thiago Ribeiro',
      'Juliana Costa',
      'André Carvalho',
      'Bianca Nunes',
      'Gustavo Freitas',
      'Larissa Duarte',
      'Diego Moreira',
      'Natália Barros',
      'Felipe Monteiro',
      'Isabela Castro',
      'Vinícius Araújo',
      'Renata Teixeira',
      'Eduardo Pires',
      'Aline Cardoso',
      'Marcelo Cunha',
      'Priscila Ramos',
      'Henrique Moura',
      'Sabrina Correia',
      'Caio Fernandes',
      'Débora Vieira',
      'Leandro Melo',
      'Vanessa Farias',
      'Rodrigo Rezende',
      'Mônica Peixoto',
      'João Viana',
    ];
    const statuses = <String>['new', 'contacted', 'qualified', 'proposal', 'won', 'lost'];
    const sources = <String>['website', 'whatsapp', 'instagram', 'referral', 'campaign', 'manual'];
    const companies = <String>['Vértice', 'Nexo', 'Aurora', 'Orbita', 'Lumina', 'Atlas'];

    final now = DateTime.now();
    for (var index = 0; index < names.length; index++) {
      final firstName = names[index].split(' ').first.toLowerCase();
      _items.add(
        LeadModel(
          id: 'lead_${_sequence++}',
          workspaceId: workspaceId,
          name: names[index],
          phone: '+55 11 9${(81000000 + index * 791).toString()}',
          email: '$firstName${index + 1}@exemplo.com',
          company: '${companies[index % companies.length]} ${index % 3 == 0 ? 'Tech' : 'Soluções'}',
          source: sources[index % sources.length],
          status: statuses[index % statuses.length],
          tags: index % 4 == 0
              ? const <String>['prioridade', 'inbound']
              : index % 3 == 0
                  ? const <String>['enterprise']
                  : const <String>['inbound'],
          score: 34 + (index * 7) % 66,
          lastContactAt: index % 5 == 0 ? null : now.subtract(Duration(hours: index * 5)),
          createdAt: now.subtract(Duration(days: 2 + index)),
          updatedAt: now.subtract(Duration(hours: index * 3)),
        ),
      );
    }
  }
}
