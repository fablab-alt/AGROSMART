import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth pages
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';

// Dashboard pages
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/buyer_dashboard/presentation/pages/buyer_dashboard_page.dart';

// Feature pages
import '../../features/parcelles/presentation/pages/parcelles_page.dart';
import '../../features/parcelles/presentation/pages/parcelle_detail_page.dart';
import '../../features/parcelles/domain/entities/parcelle.dart';
import '../../features/capteurs/presentation/pages/capteurs_page.dart';
import '../../features/capteurs/presentation/pages/capteur_detail_page.dart';
import '../../features/capteurs/domain/entities/sensor.dart';
import '../../features/diagnostic/presentation/pages/diagnostic_page.dart';
import '../../features/diagnostic/presentation/pages/diagnostic_history_page.dart';
import '../../features/diagnostic/presentation/pages/diagnostic_detail_page.dart';
import '../../features/diagnostic/presentation/pages/pest_map_page.dart';
import '../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../features/marketplace/presentation/pages/add_product_page.dart';
import '../../features/formations/presentation/pages/formations_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';

// Profile & Settings
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

// Analytics & Notifications
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/recommandations/presentation/pages/recommandations_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';

// Orders & Commerce
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';

// Community & Communication
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/community/presentation/pages/community_marketplace_page.dart';
import '../../features/community/presentation/pages/create_listing_page.dart';
import '../../features/assistant/presentation/pages/agri_chatbot_page.dart';

// Additional
import '../../features/irrigation/presentation/pages/irrigation_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../shared/pages/main_shell_page.dart';

/// Configuration du routeur de l'application
class AppRouter {
  static final _navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: '/',
    routes: [
      // =====================================================
      // Shell principal (Bottom Navigation)
      // =====================================================
      GoRoute(path: '/', builder: (context, state) => const MainShellPage()),

      // =====================================================
      // Authentification
      // =====================================================
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          String role = 'ACHETEUR';
          if (state.extra is Map<String, dynamic>) {
            role = (state.extra as Map<String, dynamic>)['role'] ?? 'ACHETEUR';
          } else if (state.extra is String) {
            role = state.extra as String;
          }
          return RegisterPage(role: role);
        },
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final telephone = state.extra as String;
          return OtpPage(telephone: telephone);
        },
      ),

      // =====================================================
      // Commerce (Cart, Checkout, Favorites)
      // =====================================================
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),

      // =====================================================
      // Dashboard & Monitoring
      // =====================================================
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/buyer-dashboard',
        name: 'buyer-dashboard',
        builder: (context, state) => const BuyerDashboardPage(),
      ),
      GoRoute(
        path: '/parcelles',
        builder: (context, state) => const ParcellesPage(),
      ),
      GoRoute(
        path: '/capteurs',
        builder: (context, state) => const CapteursPage(),
      ),
      GoRoute(
        path: '/parcelle-detail',
        name: 'parcelle-detail',
        builder: (context, state) {
          final parcelle = state.extra as Parcelle;
          return ParcelleDetailPage(parcelle: parcelle);
        },
      ),
      GoRoute(
        path: '/capteur-detail',
        name: 'capteur-detail',
        builder: (context, state) {
          final capteur = state.extra as Sensor;
          return CapteurDetailPage(capteur: capteur);
        },
      ),

      // =====================================================
      // Diagnostics & Maladies
      // =====================================================
      GoRoute(
        path: '/diagnostic',
        builder: (context, state) => const DiagnosticPage(),
      ),
      GoRoute(
        path: '/diagnostic-history',
        name: 'diagnostic-history',
        builder: (context, state) => const DiagnosticHistoryPage(),
      ),
      GoRoute(
        path: '/diagnostic-detail',
        name: 'diagnostic-detail',
        builder: (context, state) {
          final diagnostic = state.extra as Map<String, dynamic>;
          return DiagnosticDetailPage(diagnostic: diagnostic);
        },
      ),
      GoRoute(
        path: '/pest-map',
        name: 'pest-map',
        builder: (context, state) => const PestMapPage(),
      ),

      // =====================================================
      // Marketplace
      // =====================================================
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplacePage(),
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) => const AddProductPage(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/order-detail',
        name: 'order-detail',
        builder: (context, state) {
          final order = state.extra as Order;
          return OrderDetailPage(order: order);
        },
      ),

      // =====================================================
      // Communication & Communauté
      // =====================================================
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesPage(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityPage(),
      ),
      GoRoute(
        path: '/community-marketplace',
        name: 'community-marketplace',
        builder: (context, state) => const CommunityMarketplacePage(),
      ),
      GoRoute(
        path: '/community-marketplace/create',
        name: 'create-listing',
        builder: (context, state) => const CreateListingPage(),
      ),
      GoRoute(
        path: '/chatbot',
        name: 'chatbot',
        builder: (context, state) => const AgriChatbotPage(),
      ),

      // =====================================================
      // Outils & Services
      // =====================================================
      GoRoute(
        path: '/formations',
        builder: (context, state) => const FormationsPage(),
      ),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherPage(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/recommandations',
        builder: (context, state) => const RecommandationsPage(),
      ),
      GoRoute(
        path: '/irrigation',
        name: 'irrigation',
        builder: (context, state) => const IrrigationPage(),
      ),

      // =====================================================
      // Profil & Paramètres
      // =====================================================
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
}
