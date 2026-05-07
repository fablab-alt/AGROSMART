import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget d'image réseau avec cache et placeholder
///
/// Utilise CachedNetworkImage pour:
/// - Mise en cache automatique des images
/// - Placeholder pendant le chargement
/// - Gestion des erreurs gracieuse
/// - Réduction de la consommation de bande passante
/// - Support de l'accessibilité via semanticsLabel
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;

  /// Label sémantique pour l'accessibilité (lecteurs d'écran)
  final String? semanticsLabel;

  /// Exclure des outils d'accessibilité (pour images décoratives)
  final bool excludeFromSemantics;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    // Si pas d'URL, afficher le placeholder d'erreur
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );

    // Appliquer le borderRadius si spécifié
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    // Ajouter la sémantique pour l'accessibilité
    if (!excludeFromSemantics && semanticsLabel != null) {
      image = Semantics(label: semanticsLabel, image: true, child: image);
    } else if (excludeFromSemantics) {
      image = ExcludeSemantics(child: image);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Image non disponible',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'avatar avec cache
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final initials = _getInitials();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.green[100],
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.green[800],
        ),
      ),
    );
  }

  String _getInitials() {
    if (fallbackText == null || fallbackText!.isEmpty) {
      return '?';
    }
    final parts = fallbackText!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fallbackText![0].toUpperCase();
  }
}

/// Widget d'image produit pour marketplace
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final String? productName;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.height = 180,
    this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      errorWidget: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[100]!, Colors.green[200]!],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.green[600],
            ),
            if (productName != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  productName!,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget d'image équipement
class EquipmentImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final String? equipmentName;

  const EquipmentImage({
    super.key,
    this.imageUrl,
    this.height = 160,
    this.equipmentName,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      errorWidget: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture_outlined, size: 48, color: Colors.blue[600]),
            if (equipmentName != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  equipmentName!,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
