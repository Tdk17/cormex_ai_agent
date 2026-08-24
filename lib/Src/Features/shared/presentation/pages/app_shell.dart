import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/app_brand.dart';
import 'package:agente_vendas_saas/Src/Shared/models/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class AppShell extends SignalWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('/dashboard', 'Visão geral', Icons.dashboard_outlined),
    _NavItem('/leads', 'Leads', Icons.groups_2_outlined),
    _NavItem('/pipeline', 'Pipeline', Icons.view_kanban_outlined),
    _NavItem('/conversations', 'Conversas', Icons.forum_outlined),
    _NavItem('/agent', 'Agente de IA', Icons.auto_awesome_outlined),
    _NavItem('/knowledge', 'Conhecimento', Icons.menu_book_outlined),
    _NavItem('/followups', 'Follow-ups', Icons.schedule_send_outlined),
    _NavItem('/team', 'Equipe', Icons.group_outlined),
    _NavItem('/integrations', 'Integrações', Icons.hub_outlined),
    _NavItem('/billing', 'Plano e uso', Icons.credit_card_outlined),
    _NavItem('/settings', 'Configurações', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final authController = sl<AuthController>();
    final session = authController.session.value;
    final workspace = session?.selectedWorkspace;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final desktop = constraints.maxWidth >= 960;
        if (desktop) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                Container(
                  width: 262,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
                          child: Align(alignment: Alignment.centerLeft, child: AppBrand()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _WorkspaceSelector(
                            name: workspace?.name ?? 'Workspace',
                            onSelected: authController.selectWorkspace,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: _items
                                .map(
                                  (_NavItem item) => _SidebarItem(
                                    item: item,
                                    selected: currentPath == item.path ||
                                        currentPath.startsWith('${item.path}/'),
                                    onTap: () => context.go(item.path),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        _UserFooter(
                          name: session?.user.name ?? 'Usuário',
                          email: session?.user.email ?? '',
                          onLogout: authController.signOut,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: SafeArea(left: false, child: child)),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 4,
            title: Text(
              workspace?.name ?? 'Agente de Vendas',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  child: Text(_initials(session?.user.name ?? 'U')),
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
                    child: Align(alignment: Alignment.centerLeft, child: AppBrand()),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: _items
                          .map(
                            (_NavItem item) => ListTile(
                              selected: currentPath == item.path ||
                                  currentPath.startsWith('${item.path}/'),
                              selectedColor: AppColors.primary,
                              selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                              leading: Icon(item.icon),
                              title: Text(item.label),
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go(item.path);
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  _UserFooter(
                    name: session?.user.name ?? 'Usuário',
                    email: session?.user.email ?? '',
                    onLogout: authController.signOut,
                  ),
                ],
              ),
            ),
          ),
          body: child,
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        minTileHeight: 45,
        selected: selected,
        selectedColor: AppColors.primary,
        textColor: AppColors.textSecondary,
        iconColor: AppColors.textSecondary,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        leading: Icon(item.icon, size: 21),
        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: onTap,
      ),
    );
  }
}

class _WorkspaceSelector extends StatelessWidget {
  const _WorkspaceSelector({required this.name, required this.onSelected});

  final String name;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<WorkspaceModel> workspaces =
        sl<AuthController>().session.value?.workspaces ?? const <WorkspaceModel>[];
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => workspaces
          .map(
            (workspace) => PopupMenuItem<String>(
              value: workspace.id,
              child: Text(workspace.name),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.apartment_rounded, size: 19, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.name, required this.email, required this.onLogout});

  final String name;
  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Text(AppShell._initials(name), style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
