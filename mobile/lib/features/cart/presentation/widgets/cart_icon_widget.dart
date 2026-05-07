import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';

/// Icône de panier avec badge affichant le nombre d'articles
class CartIconWidget extends StatelessWidget {
  /// Callback quand on clique sur l'icône
  final VoidCallback onTap;

  /// Couleur de l'icône
  final Color? iconColor;

  /// Taille de l'icône
  final double iconSize;

  const CartIconWidget({
    super.key,
    required this.onTap,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) {
        // Ne rebuild que si le count change
        if (previous is CartLoaded && current is CartLoaded) {
          return previous.totalItems != current.totalItems;
        }
        return true;
      },
      builder: (context, state) {
        int itemCount = 0;

        if (state is CartLoaded) {
          itemCount = state.totalItems;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: iconColor ?? Theme.of(context).iconTheme.color,
                size: iconSize,
              ),
              onPressed: onTap,
            ),
            if (itemCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Version simplifiée pour utilisation hors BLoC (avec count passé en paramètre)
class CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final Color? iconColor;

  const CartBadge({
    super.key,
    required this.count,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
