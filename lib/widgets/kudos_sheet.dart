import 'package:flutter/material.dart';

import '../models/kudos.dart';

/// Bottom sheet that displays kudos categories for users to give specific praise
class KudosSheet extends StatelessWidget {
  const KudosSheet({
    super.key,
    required this.postId,
    this.currentKudosType,
    required this.onKudosSelected,
  });

  final String postId;
  final KudosType? currentKudosType;
  final Function(KudosType?) onKudosSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Give Kudos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share specific professional feedback',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kudos options grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: KudosType.values.length,
                itemBuilder: (context, index) {
                  final kudosType = KudosType.values[index];
                  final isSelected = currentKudosType == kudosType;

                  return _KudosOption(
                    type: kudosType,
                    isSelected: isSelected,
                    onTap: () {
                      // Toggle: if already selected, remove it; otherwise select it
                      onKudosSelected(isSelected ? null : kudosType);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),

              // Cancel option at the bottom
              if (currentKudosType != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () {
                      onKudosSelected(null);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Remove Kudos'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual kudos option button
class _KudosOption extends StatelessWidget {
  const _KudosOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final KudosType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Emoji
              Text(type.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              // Label
              Expanded(
                child: Text(
                  type.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Check mark if selected
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog showing kudos breakdown for a post
class KudosBreakdownDialog extends StatelessWidget {
  const KudosBreakdownDialog({
    super.key,
    required this.kudosByType,
    required this.totalCount,
  });

  final Map<String, int> kudosByType;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort by count descending
    final sortedEntries = kudosByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AlertDialog(
      title: Text(
        '$totalCount Kudos',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedEntries.map((entry) {
            final kudosType = KudosType.values.firstWhere(
              (e) => e.name == entry.key,
              orElse: () => KudosType.greatComposition,
            );
            final count = entry.value;
            final percentage = ((count / totalCount) * 100).round();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Emoji
                  Text(kudosType.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  // Label and bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                kudosType.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$count ($percentage%)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / totalCount,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
