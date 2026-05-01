import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase (replace with your project credentials)
  await Supabase.initialize(
    url: 'https://ojwarkdnccfgavorhxyq.supabase.co',
    anonKey: 'sb_publishable_jf1i1jcbVWD19VH4FWTlGA_mwFjXWD6',
    debug: false,
  );

  runApp(const ProviderScope(child: GdaVaultApp()));
}
