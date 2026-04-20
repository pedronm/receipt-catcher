import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_card.dart';
import 'receipt_detail_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receipt Catcher',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.status == ProviderStatus.loading &&
              provider.receipts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.receipts.isEmpty) {
            return _EmptyState(
              onUpload: () => _openUpload(context),
            );
          }

          return Column(
            children: [
              _SummaryBar(receipts: provider.receipts),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.receipts.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (_, index) {
                    final receipt = provider.receipts[index];
                    return ReceiptCard(
                      receipt: receipt,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReceiptDetailScreen(receipt: receipt),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpload(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Receipt'),
      ),
    );
  }

  Future<void> _openUpload(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No receipts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to upload your first PDF receipt.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.receipts});
  final List<Receipt> receipts;

  @override
  Widget build(BuildContext context) {
    final total = receipts.fold<double>(0, (sum, r) => sum + r.total);
    final synced = receipts.where((r) => r.status == ReceiptStatus.synced).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Receipts', value: '${receipts.length}'),
          _Stat(label: 'Synced', value: '$synced'),
          _Stat(
            label: 'Total Spent',
            value: total.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
      ],
    );
  }
}
