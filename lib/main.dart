import 'package:flutter/material.dart';

import 'app/app.dart';
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const DeviceSenseApp());
}
