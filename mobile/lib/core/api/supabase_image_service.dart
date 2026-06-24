class SupabaseImageService {
  static String imageUrl(String path) {
    return
        'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/places/$path';
  }
}