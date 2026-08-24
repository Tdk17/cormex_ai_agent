import 'package:agente_vendas_saas/Src/App/theme/app_theme.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/router/app_router.dart';
import 'package:flutter/material.dart';

class SalesAgentApp extends StatelessWidget {
  const SalesAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Agente de Vendas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: sl<AppRouter>().router,
    );
  }
}
