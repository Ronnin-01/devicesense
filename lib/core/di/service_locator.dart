import 'package:get_it/get_it.dart';

import '../../data/repositories/device_info_repository.dart';
import '../../data/repositories/device_info_repository_impl.dart';
import '../../features/device_info/bloc/device_info_bloc.dart';

/// Single composition root for the app's dependency graph.
///
/// This is the *only* file that ties a concrete class to an abstraction.
/// Every other file asks [sl] for an interface and never instantiates a
/// concrete implementation itself — that's Dependency Inversion applied
/// in practice, not just named in a comment.
final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- Data layer ---------------------------------------------------
  // Lazy singleton: repositories are stateless, so one shared instance
  // for the app's lifetime is safe and avoids needless re-creation.
  sl.registerLazySingleton<DeviceInfoRepository>(
    () => const DeviceInfoRepositoryImpl(),
  );

  // --- Presentation layer --------------------------------------------
  // Factory: a *fresh* Bloc per page. Blocs hold mutable, page-scoped
  // state, so Dashboard and Device Info each get their own instance
  // instead of silently sharing one. Adding a future page (Battery,
  // Bluetooth, ...) never risks an existing page's state — Open/Closed
  // in practice.
  sl.registerFactory<DeviceInfoBloc>(() => DeviceInfoBloc(sl()));
}
