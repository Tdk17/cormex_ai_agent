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
    _NavItem('/acquisition', 'Central de Aquisição', Icons.rocket_launch_outlined),
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
          return _CormeXBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 270,
                        decoration: BoxDecoration(
                          color: AppColors.shellSidebar,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AppBrand(light: true),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: _WorkspaceSelector(
                                name: workspace?.name ?? 'Workspace',
                                onSelected: authController.selectWorkspace,
                                lightContent: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.shellCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CENTRAL COMERCIAL',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.46),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
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
                              lightContent: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _ContentSurface(child: child)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return _CormeXBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawerScrimColor: Colors.black.withValues(alpha: 0.56),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 4,
              title: Text(
                workspace?.name ?? 'CormeX AI Agent',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.shellCyan.withValues(alpha: 0.14),
                    foregroundColor: AppColors.shellCyan,
                    child: Text(_initials(session?.user.name ?? 'U')),
                  ),
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: Colors.transparent,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.shellStart,
                      AppColors.shellMiddle,
                      AppColors.shellEnd,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppBrand(light: true),
                        ),
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.10)),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          children: _items
                              .map(
                                (_NavItem item) => _SidebarItem(
                                  item: item,
                                  selected: currentPath == item.path ||
                                      currentPath.startsWith('${item.path}/'),
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
                        lightContent: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: _ContentSurface(child: child),
              ),
            ),
          ),
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

class _CormeXBackground extends StatelessWidget {
  const _CormeXBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.shellStart,
                  AppColors.shellMiddle,
                  AppColors.shellEnd,
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _ShellGridPainter())),
        const Positioned(
          top: -210,
          left: -170,
          child: _ShellGlow(size: 480, color: AppColors.shellCyanStrong),
        ),
        const Positioned(
          bottom: -250,
          right: -210,
          child: _ShellGlow(size: 580, color: AppColors.shellPurple),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _ContentSurface extends StatelessWidget {
  const _ContentSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: AppColors.shellCyanStrong.withValues(alpha: 0.045),
            blurRadius: 44,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: AppColors.shellSurface.withValues(alpha: 0.975),
          child: child,
        ),
      ),
    );
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
        selectedColor: Colors.white,
        textColor: Colors.white.withValues(alpha: 0.68),
        iconColor: Colors.white.withValues(alpha: 0.58),
        selectedTileColor: AppColors.shellCyanStrong.withValues(alpha: 0.11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide(color: AppColors.shellCyan.withValues(alpha: 0.18))
              : BorderSide.none,
        ),
        leading: Icon(
          item.icon,
          size: 21,
          color: selected ? AppColors.shellCyan : null,
        ),
        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: selected
            ? const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.shellCyan)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _WorkspaceSelector extends StatelessWidget {
  const _WorkspaceSelector({
    required this.name,
    required this.onSelected,
    this.lightContent = false,
  });

  final String name;
  final ValueChanged<String> onSelected;
  final bool lightContent;

  @override
  Widget build(BuildContext context) {
    final List<WorkspaceModel> workspaces =
        sl<AuthController>().session.value?.workspaces ?? const <WorkspaceModel>[];
    final foreground = lightContent ? Colors.white : AppColors.ink;
    final secondary = lightContent
        ? Colors.white.withValues(alpha: 0.56)
        : AppColors.textSecondary;

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
          color: lightContent
              ? Colors.white.withValues(alpha: 0.065)
              : AppColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: lightContent
                ? Colors.white.withValues(alpha: 0.11)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.apartment_rounded,
              size: 19,
              color: lightContent ? AppColors.shellCyan : AppColors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.unfold_more_rounded, size: 18, color: secondary),
          ],
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({
    required this.name,
    required this.email,
    required this.onLogout,
    this.lightContent = false,
  });

  final String name;
  final String email;
  final VoidCallback onLogout;
  final bool lightContent;

  @override
  Widget build(BuildContext context) {
    final foreground = lightContent ? Colors.white : AppColors.ink;
    final secondary = lightContent
        ? Colors.white.withValues(alpha: 0.50)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: lightContent
                ? Colors.white.withValues(alpha: 0.09)
                : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: lightContent
                ? AppColors.shellCyanStrong.withValues(alpha: 0.15)
                : AppColors.primary,
            foregroundColor: lightContent ? AppColors.shellCyan : Colors.white,
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
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: onLogout,
            color: secondary,
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ShellGlow extends StatelessWidget {
  const _ShellGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellGridPainter extends CustomPainter {
  const _ShellGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.032)
      ..strokeWidth = 1;

    const double space = 64;

    for (double x = 0; x <= size.width; x += space) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y <= size.height; y += space) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
