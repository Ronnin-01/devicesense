import 'package:get_it/get_it.dart';

import '../../data/repositories/hardware_repository.dart';
import '../../data/repositories/hardware_repository_impl.dart';
import '../../features/battery_info/bloc/battery_info_bloc.dart';
import '../../features/device_info/bloc/device_info_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- Data layer ---------------------------------------------------

  sl.registerLazySingleton<HardwareRepository>(
    () => const HardwareRepositoryImpl(),
  );

  // --- Presentation layer --------------------------------------------
  // Factory: a *fresh* Bloc per page. Blocs hold mutable, page-scoped

  sl.registerFactory<DeviceInfoBloc>(() => DeviceInfoBloc(sl()));
  sl.registerFactory<BatteryInfoBloc>(() => BatteryInfoBloc(sl()));
}
