import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class ImageCacheService {
  static ImageCacheService? _instance;
  static const String _cacheDir = 'game_covers';
  static const Duration _cacheTimeout = Duration(days: 7);
  
  static ImageCacheService get instance {
    _instance ??= ImageCacheService._();
    return _instance!;
  }
  
  ImageCacheService._();
  
  /// Get cached image path or download if not cached
  /// Returns null on web platform since file caching is not supported
  Future<String?> getCachedImagePath(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    // File caching not supported on web platform
    if (kIsWeb) {
      return null;
    }
    
    try {
      final cacheKey = _generateCacheKey(imageUrl);
      final cacheFile = await _getCacheFile(cacheKey);
      
      // Check if cached file exists and is not expired
      if (await cacheFile.exists()) {
        final lastModified = await cacheFile.lastModified();
        final isExpired = DateTime.now().difference(lastModified) > _cacheTimeout;
        
        if (!isExpired) {
          return cacheFile.path;
        }
      }
      
      // Download and cache the image
      return await _downloadAndCache(imageUrl, cacheFile);
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }
  
  /// Download image and save to cache
  Future<String?> _downloadAndCache(String imageUrl, File cacheFile) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        await cacheFile.create(recursive: true);
        await cacheFile.writeAsBytes(response.bodyBytes);
        return cacheFile.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }
  
  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// Get cache file for given key
  Future<File> _getCacheFile(String cacheKey) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${directory.path}/$_cacheDir');
    
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    
    return File('${cacheDirectory.path}/$cacheKey.jpg');
  }
  
  /// Clear expired cache files
  /// No-op on web platform since file caching is not supported
  Future<void> clearExpiredCache() async {
    if (kIsWeb) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDirectory = Directory('${directory.path}/$_cacheDir');
      
      if (!await cacheDirectory.exists()) return;
      
      final files = cacheDirectory.listSync();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final lastModified = await file.lastModified();
          if (now.difference(lastModified) > _cacheTimeout) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
  
  /// Clear all cached images
  /// No-op on web platform since file caching is not supported
  Future<void> clearAllCache() async {
    if (kIsWeb) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDirectory = Directory('${directory.path}/$_cacheDir');
      
      if (await cacheDirectory.exists()) {
        await cacheDirectory.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
    }
  }
  
  /// Get cache size in bytes
  /// Returns 0 on web platform since file caching is not supported
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDirectory = Directory('${directory.path}/$_cacheDir');
      
      if (!await cacheDirectory.exists()) return 0;
      
      int totalSize = 0;
      final files = cacheDirectory.listSync(recursive: true);
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }
}