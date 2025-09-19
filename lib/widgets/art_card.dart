import 'package:flutter/material.dart';
import '../models/art_piece.dart';

class ArtCard extends StatelessWidget {
  const ArtCard({super.key, required this.piece});
  final ArtPiece piece;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: scheme.surfaceContainerHighest,
                child: Image.asset(
                  piece.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: scheme.outline,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    piece.author,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: scheme.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                piece.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'by ${piece.author}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(piece.imagePath, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(piece.description),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
