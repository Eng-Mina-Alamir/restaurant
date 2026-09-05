import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/spacing.dart';

/// Utilities for progressive image loading, caching and WebP optimization.
class AppImageUtils {
  AppImageUtils._();

  /// Automatically appends resizing and compression parameters to URLs (e.g. Unsplash)
  /// if not already present, ensuring thumbnails load in tens of kilobytes instead of megabytes.
  static String optimizeImageUrl(String url, {int width = 400, int quality = 80}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Unsplash optimization
    if (trimmed.contains('images.unsplash.com')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        if (!queryParams.containsKey('w')) {
          queryParams['w'] = width.toString();
        }
        if (!queryParams.containsKey('q')) {
          queryParams['q'] = quality.toString();
        }
        if (!queryParams.containsKey('auto')) {
          queryParams['auto'] = 'format';
        }
        return uri.replace(queryParameters: queryParams).toString();
      }
    }

    return trimmed;
  }

  /// Builds a cached network image with progressive fade-in, smooth shimmer
  /// placeholder, error fallback, and disk + memory caching.
  static Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    final targetWidth = width != null ? (width * 2).toInt() : 400;
    final targetHeight = height != null ? (height * 2).toInt() : 400;
    final optimizedUrl = optimizeImageUrl(imageUrl, width: targetWidth);

    final imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? targetWidth,
      memCacheHeight: memCacheHeight ?? targetHeight,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 600,
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  /// Placeholder banner container with gradient background.
  static Widget buildGradientBanner({
    required String title,
    String? subtitle,
    IconData? icon,
    double height = 140,
    List<Color>? gradientColors,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          colors:
              gradientColors ??
              [Colors.deepOrange.shade600, Colors.amber.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? Colors.deepOrange).withValues(
              alpha: 0.3,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
