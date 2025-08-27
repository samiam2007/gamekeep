import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_cache_service.dart';

class CachedGameImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedGameImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CachedGameImage> createState() => _CachedGameImageState();
}

class _CachedGameImageState extends State<CachedGameImage> {
  String? _cachedImagePath;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl.isNotEmpty && !kIsWeb) {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(CachedGameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _cachedImagePath = null;
      _hasError = false;
      if (widget.imageUrl.isNotEmpty && !kIsWeb) {
        _loadImage();
      }
    }
  }

  Future<void> _loadImage() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final cachedPath = await ImageCacheService.instance.getCachedImagePath(widget.imageUrl);
      
      if (mounted) {
        setState(() {
          _cachedImagePath = cachedPath;
          _isLoading = false;
          _hasError = cachedPath == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildImage() {
    if (widget.imageUrl.isEmpty) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    // Use CachedNetworkImage for web platform
    if (kIsWeb) {
      final image = CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => widget.placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => widget.errorWidget ?? _buildDefaultError(),
      );

      if (widget.borderRadius != null) {
        return ClipRRect(
          borderRadius: widget.borderRadius!,
          child: image,
        );
      }

      return image;
    }

    // Use file-based caching for mobile platforms
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    if (_isLoading || _cachedImagePath == null) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    final image = Image.file(
      File(_cachedImagePath!),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? _buildDefaultError();
      },
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.casino,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }
}