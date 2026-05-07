import 'package:flutter/material.dart';
import '../../domain/entities/order.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    // UI Helpers
    final statusColor = _getStatusColor(order.statut);
    final statusIcon = _getStatusIcon(order.statut);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.date);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Commande #${order.id.substring(0, 8).toUpperCase()}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      statusIcon,
                      size: 48,
                      color: statusColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.statut,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commandé le $dateStr',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Details
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails de la commande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Produit', order.produitNom),
                    _buildDetailRow('Vendeur', order.vendeurNom),
                    _buildDetailRow('Quantité', '${order.quantite}'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${order.prixTotal} FCFA',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Delivery (Mock)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suivi de livraison',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mock steps for now, real logic would depend on detailed status history
                    _buildTimelineItem('Commande reçue', dateStr, true, true),
                    _buildTimelineItem('En préparation', '...', order.statut != 'En attente', true), // Mock logic
                    _buildTimelineItem('Livrée', '...', order.statut == 'Livrée', false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              size: 20,
            ),
            if (isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'livrée': return Icons.check_circle_outline;
      case 'annulée': return Icons.cancel_outlined;
      default: return Icons.local_shipping_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'livrée': return Colors.green;
      case 'annulée': return Colors.red;
      default: return Colors.orange;
    }
  }
}
