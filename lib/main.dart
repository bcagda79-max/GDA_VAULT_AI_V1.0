import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/app.dart';
import 'package:gda_vault_ai/core/utils/sqlite_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSqlite();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: GdaVaultApp()));
}