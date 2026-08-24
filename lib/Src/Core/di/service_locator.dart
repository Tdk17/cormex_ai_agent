import 'package:agente_vendas_saas/Src/Core/auth/session_storage.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Core/router/app_router.dart';
import 'package:agente_vendas_saas/Src/Core/storage/secure_storage_service.dart';
import 'package:agente_vendas_saas/Src/Features/auth/data/remote_auth_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/cadastro_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/login_controller.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/data/remote_dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/data/csv_lead_parser.dart';
import 'package:agente_vendas_saas/Src/Features/leads/data/remote_leads_repository.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_detail_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_form_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_import_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/leads_controller.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/data/remote_pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/opportunity_detail_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/opportunity_form_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  if (sl.isRegistered<AuthController>()) return;

  sl.registerLazySingleton<SecureStorageService>(
    () => FlutterSecureStorageService(),
  );
  sl.registerLazySingleton<SessionStorage>(() => SessionStorage(sl()));
  sl.registerLazySingleton<HttpManager>(() => HttpManager(sessionStorage: sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => RemoteAuthRepository(httpManager: sl(), sessionStorage: sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => RemoteDashboardRepository(sl()),
  );
  sl.registerLazySingleton<LeadsRepository>(
    () => RemoteLeadsRepository(sl()),
  );
  sl.registerLazySingleton<PipelineRepository>(
    () => RemotePipelineRepository(sl()),
  );
  sl.registerLazySingleton<CsvLeadParser>(() => CsvLeadParser());

  sl.registerLazySingleton<AuthController>(() => AuthController(sl()));
  sl.registerLazySingleton<LoginController>(() => LoginController(sl()));
  sl.registerLazySingleton<CadastroController>(() => CadastroController(sl()));
  sl.registerLazySingleton<ForgotPasswordController>(
    () => ForgotPasswordController(sl()),
  );
  sl.registerLazySingleton<OnboardingController>(() => OnboardingController(sl()));
  sl.registerLazySingleton<DashboardController>(
    () => DashboardController(sl(), sl()),
  );
  sl.registerLazySingleton<LeadsController>(() => LeadsController(sl(), sl()));
  sl.registerFactory<LeadDetailController>(
    () => LeadDetailController(sl(), sl()),
  );
  sl.registerFactory<LeadFormController>(
    () => LeadFormController(sl(), sl(), sl()),
  );
  sl.registerFactory<LeadImportController>(
    () => LeadImportController(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<PipelineController>(
    () => PipelineController(sl(), sl()),
  );
  sl.registerFactory<OpportunityDetailController>(
    () => OpportunityDetailController(sl(), sl(), sl()),
  );
  sl.registerFactory<OpportunityFormController>(
    () => OpportunityFormController(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton<AppRouter>(() => AppRouter(sl()));
}
