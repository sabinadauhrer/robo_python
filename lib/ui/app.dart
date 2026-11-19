import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'theme.dart';

class RoboPythonApp extends StatelessWidget {
  const RoboPythonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robo Python – Python spielerisch lernen',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MapScreen(),
    );
  }
}
