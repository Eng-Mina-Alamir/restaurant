import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../utils/logger.dart';

/// Service to handle file and image uploads to Supabase Storage buckets.
class SupabaseStorageService {
  SupabaseStorageService(this._supabase);

  final SupabaseClient _supabase;

  /// Uploads an image (bytes) to the specified [bucketName] and returns the public URL.
  Future<String?> uploadImageBytes({
    required String bucketName,
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      await _supabase.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      AppLogger.error('Failed to upload image to Supabase storage ($bucketName): $e');
      return null;
    }
  }

  /// Uploads a delivery proof photo.
  Future<String?> uploadDeliveryProof({
    required String orderId,
    required Uint8List bytes,
  }) async {
    final fileName = 'proof_${orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(
      bucketName: SupabaseConfig.deliveryProofBucket,
      path: fileName,
      bytes: bytes,
    );
  }

  /// Uploads a menu item image.
  Future<String?> uploadMenuItemImage({
    required String itemId,
    required Uint8List bytes,
  }) async {
    final fileName = 'item_${itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(
      bucketName: SupabaseConfig.menuBucket,
      path: fileName,
      bytes: bytes,
    );
  }
}
