import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../../core/services/navigation_intent_service.dart';

/// Page de finalisation de commande (Checkout)
/// L'utilisateur doit être authentifié pour accéder à cette page
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Informations de livraison
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Mode de paiement sélectionné
  String _selectedPaymentMethod = 'mobile_money';

  // Mode de livraison sélectionné
  String _selectedDeliveryMethod = 'delivery';

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        if (cartState is! CartLoaded || cartState.items.isEmpty) {
          return _buildEmptyCartView(context);
        }

        return _buildCheckoutContent(context, cartState);
      },
    );
  }

  Widget _buildEmptyCartView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour au marketplace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, CartLoaded cartState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stepper
          _buildStepper(context, isDark),

          // Contenu selon l'étape
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildStepContent(context, isDark, cartState),
              ),
            ),
          ),

          // Footer avec total et bouton
          _buildFooter(context, isDark, cartState),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Livraison', Icons.local_shipping_outlined),
          Expanded(child: _buildStepLine(0)),
          _buildStepIndicator(1, 'Paiement', Icons.payment_outlined),
          Expanded(child: _buildStepLine(1)),
          _buildStepIndicator(2, 'Confirmation', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.green[700] : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: Colors.green[300]!, width: 3)
                : null,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.green[700] : Colors.grey[500],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;

    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? Colors.green[700] : Colors.grey[300],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    bool isDark,
    CartLoaded cartState,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildDeliveryStep(context, isDark);
      case 1:
        return _buildPaymentStep(context, isDark);
      case 2:
        return _buildConfirmationStep(context, isDark, cartState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDeliveryStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de livraison',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Options de livraison
        _buildDeliveryOption(
          'delivery',
          'Livraison à domicile',
          'Livraison sous 2-3 jours ouvrés',
          Icons.home_outlined,
          2000,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildDeliveryOption(
          'pickup',
          'Retrait en point relais',
          'Retrait gratuit sous 24h',
          Icons.store_outlined,
          0,
          isDark,
        ),

        const SizedBox(height: 24),

        if (_selectedDeliveryMethod == 'delivery') ...[
          Text(
            'Adresse de livraison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse complète',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Ville / Commune',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre ville';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
              prefixText: '+225 ',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Instructions de livraison (optionnel)',
              hintText: 'Ex: Appeler avant livraison',
              prefixIcon: Icon(Icons.note_outlined),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliveryOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    double price,
    bool isDark,
  ) {
    final isSelected = _selectedDeliveryMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeliveryMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green[700] : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Text(
              price > 0 ? '${price.toStringAsFixed(0)} FCFA' : 'Gratuit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: price > 0 ? Colors.green[700] : Colors.green[600],
              ),
            ),
            const SizedBox(width: 8),
            Radio<String>(
              value: value,
              groupValue: _selectedDeliveryMethod,
              onChanged: (v) {
                setState(() {
                  _selectedDeliveryMethod = v!;
                });
              },
              activeColor: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de paiement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildPaymentOption(
          'mobile_money',
          'Mobile Money',
          'Orange Money, MTN Money, Moov Money',
          Icons.phone_android,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'card',
          'Carte bancaire',
          'Visa, Mastercard',
          Icons.credit_card,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'cash',
          'Paiement à la livraison',
          'Payez en espèces à la réception',
          Icons.money,
          isDark,
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vos informations de paiement sont sécurisées et cryptées',
                  style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green[700] : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (v) {
                setState(() {
                  _selectedPaymentMethod = v!;
                });
              },
              activeColor: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStep(
    BuildContext context,
    bool isDark,
    CartLoaded cartState,
  ) {
    final deliveryFee = _selectedDeliveryMethod == 'delivery' ? 2000.0 : 0.0;
    final total = cartState.totalPrice + deliveryFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif de la commande',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Liste des articles
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              ...cartState.items.map((item) => _buildOrderItem(item, isDark)),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceRow('Sous-total', cartState.totalPrice, isDark),
                    const SizedBox(height: 8),
                    _buildPriceRow('Livraison', deliveryFee, isDark),
                    const Divider(height: 24),
                    _buildPriceRow('Total', total, isDark, isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Informations de livraison
        if (_selectedDeliveryMethod == 'delivery') ...[
          Text(
            'Livraison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_addressController.text}, ${_cityController.text}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: const Text('Modifier'),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Mode de paiement
        Text(
          'Paiement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _selectedPaymentMethod == 'mobile_money'
                    ? Icons.phone_android
                    : _selectedPaymentMethod == 'card'
                    ? Icons.credit_card
                    : Icons.money,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedPaymentMethod == 'mobile_money'
                      ? 'Mobile Money'
                      : _selectedPaymentMethod == 'card'
                      ? 'Carte bancaire'
                      : 'Paiement à la livraison',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                child: const Text('Modifier'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(CartItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'x${item.quantite}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${item.totalPrice.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double price,
    bool isDark, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          '${price.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? Colors.green[700]
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, CartLoaded cartState) {
    final deliveryFee = _selectedDeliveryMethod == 'delivery' ? 2000.0 : 0.0;
    final total = cartState.totalPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStep < 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total estimé'),
                  Text(
                    '${total.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retour'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        // Valider l'étape courante
                        if (_currentStep == 0 &&
                            _selectedDeliveryMethod == 'delivery') {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                        }
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        // Passer la commande
                        _submitOrder(context, cartState);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentStep < 2 ? 'Continuer' : 'Confirmer la commande',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder(BuildContext context, CartLoaded cartState) {
    // Vérifier si l'utilisateur est authentifié
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      // Demander la connexion
      _showAuthRequiredDialog(context);
      return;
    }

    // Utilisateur authentifié - procéder à la commande
    _processOrder(context, cartState);
  }

  void _showAuthRequiredDialog(BuildContext context) {
    // Sauvegarder l'intention de retourner au checkout après connexion
    NavigationIntent.setPendingRoute('/checkout');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Connexion requise'),
          ],
        ),
        content: const Text(
          'Pour finaliser votre commande, vous devez être connecté. '
          'Vos articles seront conservés dans votre panier et vous reviendrez ici après connexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/login');
            },
            child: const Text('Se connecter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/role-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  void _processOrder(BuildContext context, CartLoaded cartState) {
    // TODO: Implémenter l'envoi de la commande au backend

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Commande confirmée !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre commande a été passée avec succès. Vous recevrez une confirmation par SMS.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Vider le panier
                context.read<CartBloc>().add(ClearCart());
                // Retourner à l'accueil
                Navigator.of(context).pop();
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continuer mes achats'),
            ),
          ),
        ],
      ),
    );
  }
}
