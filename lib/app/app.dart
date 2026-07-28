import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class DeviceSenseApp extends StatelessWidget {
  const DeviceSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DeviceSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
