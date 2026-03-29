import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({super.key, required this.receipt, this.onTap});

  final Receipt receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().format(receipt.date);
    final totalStr =
        '${receipt.currency} ${receipt.total.toStringAsFixed(2)}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _StatusIcon(status: receipt.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.storeName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (receipt.category != null) ...[
                      const SizedBox(height: 4),
                      _CategoryChip(label: receipt.category!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalStr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      ReceiptStatus.synced => (Icons.cloud_done_rounded, Colors.green),
      ReceiptStatus.error => (Icons.cloud_off_rounded, Colors.red),
      ReceiptStatus.pending => (Icons.cloud_upload_rounded, Colors.grey),
    };
    return Icon(icon, color: color, size: 22);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
