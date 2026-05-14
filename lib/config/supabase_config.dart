import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ulfnjqhusocbtndqaggm.supabase.co';
const supabaseAnonKey = 'sb_publishable_enwBwLf-yS3bXfNVl8vdaA_yqyx0GvW';

Future<void> initSupabase() {
  return Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
