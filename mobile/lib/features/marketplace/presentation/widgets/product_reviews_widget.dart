import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/product_review.dart';

class ProductReviewsWidget extends StatelessWidget {
  final List<ProductReview> reviews;
  final ReviewStats? stats;
  final VoidCallback? onAddReview;

  const ProductReviewsWidget({
    super.key,
    required this.reviews,
    this.stats,
    this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (stats != null) _buildStats(context, stats!),
        const Divider(),
        _buildReviewsList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Avis clients (${reviews.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (onAddReview != null)
            TextButton.icon(
              onPressed: onAddReview,
              icon: const Icon(Icons.rate_review),
              label: const Text('Donner un avis'),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, ReviewStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Text(
                    stats.moyenneNote.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStarRating(stats.moyenneNote),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.nombreAvis} avis',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = stats.repartitionNotes[stars] ?? 0;
                    final percentage = stats.nombreAvis > 0
                        ? (count / stats.nombreAvis * 100)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$stars'),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Aucun avis pour le moment.\nSoyez le premier à donner votre avis!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        return _buildReviewItem(context, reviews[index]);
      },
    );
  }

  Widget _buildReviewItem(BuildContext context, ProductReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(child: Text(review.userName[0].toUpperCase())),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _buildStarRating(review.note.toDouble(), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(review.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.commentaire != null) ...[
          const SizedBox(height: 12),
          Text(review.commentaire!),
        ],
        if (review.images != null && review.images!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.images![index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (index < rating) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: Colors.amber);
        }
      }),
    );
  }
}

class AddReviewDialog extends StatefulWidget {
  final String productId;
  final Function(int note, String? commentaire) onSubmit;

  const AddReviewDialog({
    super.key,
    required this.productId,
    required this.onSubmit,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Donner un avis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Votre note:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() => _selectedRating = index + 1);
                  },
                  icon: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Votre commentaire (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Partagez votre expérience...',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final comment = _commentController.text.trim();
            widget.onSubmit(_selectedRating, comment.isEmpty ? null : comment);
            Navigator.pop(context);
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
