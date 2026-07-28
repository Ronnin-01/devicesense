import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  runApp(const DeviceSenseApp());
}
