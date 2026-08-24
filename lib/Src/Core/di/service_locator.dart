import 'package:agente_vendas_saas/Src/Core/auth/session_storage.dart';
import 'package:agente_vendas_saas/Src/Core/config/app_config.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Core/router/app_router.dart';
import 'package:agente_vendas_saas/Src/Core/storage/secure_storage_service.dart';
import 'package:agente_vendas_saas/Src/Features/auth/data/mock_auth_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/data/remote_auth_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/cadastro_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/login_controller.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/data/mock_dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/data/remote_dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/controllers/onboarding_controller.dart';
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
    () => AppConfig.useMockData
        ? MockAuthRepository(sl())
        : RemoteAuthRepository(httpManager: sl(), sessionStorage: sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => AppConfig.useMockData
        ? MockDashboardRepository()
        : RemoteDashboardRepository(sl()),
  );

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
  sl.registerLazySingleton<AppRouter>(() => AppRouter(sl()));
}
