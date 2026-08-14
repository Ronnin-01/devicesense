import 'package:devicesense/data/repositories/nfc/nfc_reader_repository_impl.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/bluetooth/bluetooth_repository.dart';
import '../../data/repositories/bluetooth/bluetooth_repository_impl.dart';
import '../../data/repositories/hardware/hardware_repository.dart';
import '../../data/repositories/hardware/hardware_repository_impl.dart';
import '../../data/repositories/nfc/nfc_reader_repository.dart';
import '../../data/repositories/sensors/sensors_repository.dart';
import '../../data/repositories/sensors/sensors_repository_impl.dart';
import '../../data/repositories/wifi/wifi_capabilities_repository.dart';
import '../../data/repositories/wifi/wifi_capabilities_repository_impl.dart';
import '../../data/repositories/wifi/wifi_info_repository.dart';
import '../../data/repositories/wifi/wifi_info_repository_impl.dart';
import '../../data/repositories/wifi/wifi_scan_repository.dart';
import '../../features/battery_info/bloc/battery_info_bloc.dart';
import '../../features/bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../../features/bluetooth_info/bloc/bluetooth_info_bloc.dart';
import '../../features/device_info/bloc/device_info_bloc.dart';
import '../../features/nfc/bloc/nfc_capabilities_bloc/nfc_capabilities_bloc.dart';
import '../../features/nfc/bloc/nfc_reader_bloc/nfc_reader_bloc.dart';
import '../../features/permissions/bloc/permission_bloc.dart';
import '../../features/sensors/bloc/sensors_bloc.dart';
import '../../features/wifi/bloc/capabilities/wifi_capabilities_bloc.dart';
import '../../features/wifi/bloc/info/wifi_info_bloc.dart';
import '../../features/wifi/bloc/scan/wifi_scan_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- Data layer ---------------------------------------------------

  sl.registerLazySingleton<HardwareRepository>(
    () => const HardwareRepositoryImpl(),
  );

  sl.registerFactory<BluetoothRepository>(() => BluetoothRepositoryImpl());

  // Wi-Fi — repositories
  sl.registerLazySingleton<WifiCapabilitiesRepository>(
    () => const WifiCapabilitiesRepositoryImpl(),
  );
  sl.registerLazySingleton<WifiInfoRepository>(
    () => const WifiInfoRepositoryImpl(),
  );
  // WifiScanRepository is a factory (not singleton) — it holds mutable
  // stream state and must be fresh per page open, same as BluetoothRepository.
  sl.registerFactory<WifiScanRepository>(() => WifiScanRepository());

  // NFC — repositories
  sl.registerLazySingleton<NfcReaderRepository>(
    () => NfcReaderRepositoryImpl(),
  );

  // Sensors repository
  sl.registerFactory<SensorsRepository>(() => SensorsRepositoryImpl());

  // --- Presentation layer --------------------------------------------
  // Factory: a *fresh* Bloc per page. Blocs hold mutable, page-scoped

  sl.registerFactory<DeviceInfoBloc>(() => DeviceInfoBloc(sl()));
  sl.registerFactory<BatteryInfoBloc>(() => BatteryInfoBloc(sl()));
  sl.registerFactory<BluetoothInfoBloc>(() => BluetoothInfoBloc(sl()));
  sl.registerFactory<PermissionBloc>(() => PermissionBloc(sl()));
  sl.registerFactory<BluetoothDiscoveryBloc>(
    () => BluetoothDiscoveryBloc(repository: sl<BluetoothRepository>()),
  );

  // Wi-Fi — blocs (all factories — fresh instance per page)
  sl.registerFactory<WifiCapabilitiesBloc>(() => WifiCapabilitiesBloc(sl()));
  sl.registerFactory<WifiInfoBloc>(() => WifiInfoBloc(sl()));
  sl.registerFactory<WifiScanBloc>(() => WifiScanBloc(repository: sl()));

  sl.registerFactory(() => NfcCapabilitiesBloc(sl<NfcReaderRepository>()));
  sl.registerFactory(
    () => NfcReaderBloc(repository: sl<NfcReaderRepository>()),
  );
  // Sensors — bloc
  sl.registerFactory<SensorsBloc>(
    () => SensorsBloc(repository: sl<SensorsRepository>()),
  );
}
