import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nyrna/config.dart';
import 'package:nyrna/nyrna.dart';
import 'package:nyrna/parse_args.dart';
import 'package:nyrna/screens/apps_screen.dart';
import 'package:nyrna/settings/screens/settings_screen.dart';
import 'package:nyrna/settings/settings.dart';
import 'package:nyrna/window.dart';
import 'package:provider/provider.dart';

Future<void> main(List<String> args) async {
  await parseArgs(args);
  settings = Settings();
  await settings.initialize();
  if (Config.toggle) {
    // Not yet possible to run without GUI, so we just exit after toggle.
    await Nyrna.hide();
    var activeWindow = ActiveWindow();
    await activeWindow.toggle();
    exit(0);
  } else {
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Nyrna>(create: (_) => Nyrna()),
      ],
      child: MaterialApp(
        title: 'Nyrna',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ),
        routes: {
          RunningAppsScreen.id: (context) => RunningAppsScreen(),
          SettingsScreen.id: (conext) => SettingsScreen(),
        },
        home: RunningAppsScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
