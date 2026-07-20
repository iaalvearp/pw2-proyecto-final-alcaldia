import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/procurement_process.dart';
import 'info_chip.dart';

class ProcessCard extends StatelessWidget {
  const ProcessCard({
    required this.process,
    required this.onViewDetails,
    super.key,
  });

  final ProcurementProcess process;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final amount = process.amount ?? process.budget;
    final amountText = amount == null
        ? null
        : 'USD ${NumberFormat('#,##0.00', 'es_EC').format(amount)}';
    final location = process.locality ?? process.region;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (process.title != null &&
                process.title!.trim().isNotEmpty &&
                process.title!.trim() != process.displayTitle) ...[
              Text(
                process.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              process.displayTitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (process.year != null)
                  InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: process.year.toString(),
                    emphasized: true,
                  ),
                if (process.internalType != null)
                  InfoChip(
                    icon: Icons.category_outlined,
                    label: process.internalType!,
                  ),
                if (location != null)
                  InfoChip(icon: Icons.location_on_outlined, label: location),
              ],
            ),
            if (amountText != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      amountText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (process.buyerName != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      process.buyerName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Ver detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
