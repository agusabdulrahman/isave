import 'package:flutter/material.dart';

import 'config/supabase_config.dart';
import 'view/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ISaveUpApp());
}
