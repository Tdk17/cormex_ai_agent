import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

enum CrmDirectoryType { customers, accounts }

class CrmDirectoryPage extends StatefulWidget {
  const CrmDirectoryPage({required this.type, super.key});

  final CrmDirectoryType type;

  @override
  State<CrmDirectoryPage> createState() => _CrmDirectoryPageState();
}

class _CrmDirectoryPageState extends State<CrmDirectoryPage> {
  late final HttpManager _http;
  late final AuthController _auth;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];

  bool get _isCustomers => widget.type == CrmDirectoryType.customers;
  String get _title => _isCustomers ? 'Clientes' : 'Empresas / Contas';
  String get _entityLabel => _isCustomers ? 'cliente' : 'empresa';
  String get _listEndpoint =>
      _isCustomers ? Endpoints.customersList : Endpoints.accountsList;
  String get _createEndpoint =>
      _isCustomers ? Endpoints.customersCreate : Endpoints.accountsCreate;
  String get _updateEndpoint =>
      _isCustomers ? Endpoints.customersUpdate : Endpoints.accountsUpdate;
  String? get _workspaceId => _auth.session.value?.selectedWorkspace?.id;

  @override
  void initState() {
    super.initState();
    _http = sl<HttpManager>();
    _auth = sl<AuthController>();
    unawaited(_load());
  }

  Future<void> _load() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Selecione uma empresa de trabalho antes de abrir este cadastro.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _http.cloudFunction(
      name: _listEndpoint,
      parameters: <String, dynamic>{'workspaceId': workspaceId, 'limit': 100},
    );

    if (!mounted) return;
    switch (result) {
      case ApiSuccess<Map<String, dynamic>>(:final data):
        if (_workspaceId != workspaceId) return;
        final raw = data['items'] ?? data[_isCustomers ? 'customers' : 'accounts'];
        setState(() {
          _items = _maps(raw).toList(growable: false);
          _loading = false;
        });
      case ApiFailure<Map<String, dynamic>>(:final error):
        if (_workspaceId != workspaceId) return;
        setState(() {
          _loading = false;
          _error = error.code == 'INVALID_FUNCTION'
              ? 'A API $_listEndpoint ainda precisa ser publicada no Back4App.'
              : error.userMessage;
        });
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? current]) async {
    if (_saving) return;
    final editing = current != null;
    final name = TextEditingController(text: current?['name']?.toString() ?? '');
    final email = TextEditingController(
      text: (_isCustomers ? current?['email'] : current?['website'])?.toString() ?? '',
    );
    final phone = TextEditingController(text: current?['phone']?.toString() ?? '');
    final document = TextEditingController(text: current?['document']?.toString() ?? '');
    final extra = TextEditingController(text: current?['legalName']?.toString() ?? '');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          editing
              ? 'Editar ${_isCustomers ? 'cliente' : 'empresa'}'
              : 'Cadastrar ${_isCustomers ? 'cliente' : 'empresa'}',
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  autofocus: !editing,
                  decoration: InputDecoration(
                    labelText: _isCustomers ? 'Nome *' : 'Nome fantasia *',
                  ),
                ),
                const SizedBox(height: 12),
                if (_isCustomers)
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  )
                else
                  TextField(
                    controller: extra,
                    decoration: const InputDecoration(labelText: 'Razão social'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: document,
                  decoration: InputDecoration(
                    labelText: _isCustomers ? 'CPF/CNPJ' : 'CNPJ',
                  ),
                ),
                if (!_isCustomers) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Site'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(editing ? 'Salvar' : 'Cadastrar'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      name.dispose();
      email.dispose();
      phone.dispose();
      document.dispose();
      extra.dispose();
      return;
    }

    final trimmedName = name.text.trim();
    if (trimmedName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome válido.')),
      );
      name.dispose();
      email.dispose();
      phone.dispose();
      document.dispose();
      extra.dispose();
      return;
    }

    final payload = <String, dynamic>{
      'name': trimmedName,
      'phone': phone.text.trim(),
      'document': document.text.trim(),
      if (_isCustomers) 'email': email.text.trim(),
      if (!_isCustomers) 'legalName': extra.text.trim(),
      if (!_isCustomers) 'website': email.text.trim(),
    };

    name.dispose();
    email.dispose();
    phone.dispose();
    document.dispose();
    extra.dispose();

    if (editing) {
      final id = current['id']?.toString();
      if (id == null || id.isEmpty) return;
      await _update(id, payload);
    } else {
      await _create(payload);
    }
  }

  Future<void> _create(Map<String, dynamic> entity) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _http.cloudFunction(
      name: _createEndpoint,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        _isCustomers ? 'customer' : 'account': entity,
        'clientRequestId':
            'crm_${_isCustomers ? 'customer' : 'account'}_${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    await _handleSaveResult(result, workspaceId, created: true);
  }

  Future<void> _update(String id, Map<String, dynamic> entity) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _http.cloudFunction(
      name: _updateEndpoint,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        _isCustomers ? 'customerId' : 'accountId': id,
        _isCustomers ? 'customer' : 'account': entity,
      },
    );
    await _handleSaveResult(result, workspaceId, created: false);
  }

  Future<void> _handleSaveResult(
    ApiResult<Map<String, dynamic>> result,
    String workspaceId, {
    required bool created,
  }) async {
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<Map<String, dynamic>>():
        if (_workspaceId != workspaceId) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_capitalize(_entityLabel)} ${created ? 'cadastrado' : 'atualizado'} com sucesso.',
            ),
          ),
        );
        await _load();
      case ApiFailure<Map<String, dynamic>>(:final error):
        if (_workspaceId != workspaceId) return;
        setState(() {
          _saving = false;
          _error = error.code == 'INVALID_FUNCTION'
              ? 'A API ${created ? _createEndpoint : _updateEndpoint} ainda não está publicada no Back4App.'
              : error.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(24),
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
                      Text(_title, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        _isCustomers
                            ? 'Pessoas e contatos comerciais já convertidos em clientes. Leads continuam separados.'
                            : 'Empresas atendidas pelo workspace. Uma empresa pode ter vários clientes/contatos vinculados.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _openEditor(),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(_isCustomers ? 'Novo cliente' : 'Nova empresa'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline_rounded),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_error!)),
                        TextButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          _isCustomers ? Icons.people_outline_rounded : Icons.apartment_rounded,
                          size: 48,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isCustomers ? 'Nenhum cliente cadastrado' : 'Nenhuma empresa cadastrada',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isCustomers
                              ? 'Cadastre o primeiro cliente sem precisar convertê-lo de Leads.'
                              : 'Cadastre a primeira empresa/conta atendida pelo CRM.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._items.map(_buildItem),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final name = item['name']?.toString().trim();
    final secondary = _isCustomers
        ? _firstText(item['email'], item['phone'], item['document'])
        : _firstText(item['legalName'], item['document'], item['website']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: _saving ? null : () => _openEditor(item),
        leading: CircleAvatar(
          child: Icon(_isCustomers ? Icons.person_outline : Icons.apartment_outlined),
        ),
        title: Text(name == null || name.isEmpty ? 'Sem nome' : name),
        subtitle: secondary == null ? null : Text(secondary),
        trailing: const Icon(Icons.edit_outlined),
      ),
    );
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }

  static String? _firstText(dynamic a, dynamic b, dynamic c) {
    for (final value in <dynamic>[a, b, c]) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
