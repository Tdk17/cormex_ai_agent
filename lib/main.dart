import 'package:agente_vendas_saas/Src/App/app.dart';
import 'package:agente_vendas_saas/Src/Core/config/app_config.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();
  setupDependencies();
  runApp(const SalesAgentApp());
}
