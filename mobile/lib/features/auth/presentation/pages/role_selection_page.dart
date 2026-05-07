import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Page de sélection du rôle lors de l'inscription
/// L'utilisateur choisit entre ACHETEUR et PRODUCTEUR
class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              final cubit = context.read<ThemeCubit>();
              cubit.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Titre
              Text(
                'Bienvenue sur AgroSmart',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Comment souhaitez-vous utiliser l\'application ?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Carte Acheteur
              _RoleCard(
                title: 'Acheteur',
                description:
                    'Je veux acheter des produits agricoles, des équipements et des intrants.',
                icon: Icons.shopping_bag_outlined,
                color: Colors.blue,
                features: const [
                  'Accès au marketplace',
                  'Commandes et livraisons',
                  'Produits favoris',
                  'Historique d\'achats',
                ],
                onTap: () {
                  context.push('/register', extra: {'role': 'ACHETEUR'});
                },
              ),

              const SizedBox(height: 20),

              // Carte Producteur
              _RoleCard(
                title: 'Producteur',
                description:
                    'Je suis agriculteur et je veux gérer mes parcelles et vendre mes produits.',
                icon: Icons.agriculture_outlined,
                color: Colors.green,
                features: const [
                  'Gestion des parcelles',
                  'Monitoring des capteurs',
                  'Diagnostic des cultures',
                  'Vente sur le marketplace',
                ],
                onTap: () {
                  context.push('/register', extra: {'role': 'PRODUCTEUR'});
                },
              ),

              const SizedBox(height: 32),

              // Lien vers connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ?',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Features
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: features
                        .take(2)
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(fontSize: 11, color: color),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            // Flèche
            Icon(Icons.arrow_forward_ios, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
