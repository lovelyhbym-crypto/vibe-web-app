import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Picks an image from the specified [source] (camera or gallery).
  ///
  /// Sets [maxWidth] to 1024 and [imageQuality] to 80.
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      debugPrint('ImageService: pickImage error: $e');
      return null;
    }
  }

  /// Uploads the given [imageFile] to Supabase 'wishlist_images' bucket.
  ///
  /// Uses [readAsBytes] for Web/Mobile compatibility.
  /// Generates a random filename using [Uuid].
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Extract file extension or default to jpg
      final String fileExt = imageFile.name.split('.').last;
      final String fileName = '${const Uuid().v4()}.$fileExt';
      final String filePath = 'wishlist/$fileName';

      await _supabase.storage
          .from('wishlist_images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );

      final String imageUrl = _supabase.storage
          .from('wishlist_images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('ImageService: uploadImage error: $e');
      return null;
    }
  }
}
