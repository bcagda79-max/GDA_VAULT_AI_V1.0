import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/app.dart';
import 'package:gda_vault_ai/core/utils/sqlite_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSqlite();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://ojwarkdnccfgavorhxyq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qd2Fya2RuY2NmZ2F2b3JoeHlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MzAyNzksImV4cCI6MjA5MzIwNjI3OX0.vOgl-DVHmi85mB3DTfgTCQZjWuOQ7NzW0AiEOwM3r0U',
    debug: false,
  );

  runApp(const ProviderScope(child: GdaVaultApp()));
}
