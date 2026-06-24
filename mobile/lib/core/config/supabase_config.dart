import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url =
      'https://ypicbilajipxjgkqxuht.supabase.co';

  static const anonKey =
      'sb_publishable_CUj1PhLXnuGiGg-f_nrpKg_RENDSuRQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
}

