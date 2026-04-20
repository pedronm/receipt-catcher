import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../providers/receipt_provider.dart';

/// Shows the details of a receipt.  When [isNew] is `true` the user can
/// edit the fields before submitting them to Google Sheets.
class ReceiptDetailScreen extends StatefulWidget {
  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
    this.isNew = false,
  });

  final Receipt receipt;
  final bool isNew;

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  late Receipt _receipt;

  final _storeCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _subtotalCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _date;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
    _syncControllers();
  }

  void _syncControllers() {
    _storeCtrl.text = _receipt.storeName;
    _totalCtrl.text = _receipt.total.toStringAsFixed(2);
    _subtotalCtrl.text = _receipt.subtotal.toStringAsFixed(2);
    _taxCtrl.text = _receipt.tax.toStringAsFixed(2);
    _categoryCtrl.text = _receipt.category ?? '';
    _notesCtrl.text = _receipt.notes ?? '';
    _date = _receipt.date;
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _totalCtrl.dispose();
    _subtotalCtrl.dispose();
    _taxCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.isNew;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Review Receipt' : 'Receipt Details'),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.status == ProviderStatus.loading;

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Receipt ID (read-only) ──────────────────────────────
                    _InfoRow(
                      label: 'Receipt ID',
                      value: _receipt.id,
                      monospace: true,
                    ),
                    const SizedBox(height: 16),

                    // ── Store name ─────────────────────────────────────────
                    _buildField(
                      label: 'Store',
                      controller: _storeCtrl,
                      readOnly: !isNew,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Date ───────────────────────────────────────────────
                    _DateField(
                      date: _date,
                      readOnly: !isNew,
                      onChanged: (d) => setState(() => _date = d),
                    ),
                    const SizedBox(height: 12),

                    // ── Amounts ────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Subtotal',
                            controller: _subtotalCtrl,
                            readOnly: !isNew,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildField(
                            label: 'Tax',
                            controller: _taxCtrl,
                            readOnly: !isNew,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Total',
                      controller: _totalCtrl,
                      readOnly: !isNew,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Category ───────────────────────────────────────────
                    _buildField(
                      label: 'Category',
                      controller: _categoryCtrl,
                      readOnly: !isNew,
                    ),
                    const SizedBox(height: 12),

                    // ── Notes ──────────────────────────────────────────────
                    _buildField(
                      label: 'Notes',
                      controller: _notesCtrl,
                      readOnly: !isNew,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ── Items table ────────────────────────────────────────
                    if (_receipt.items.isNotEmpty) ...[
                      Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _ItemsTable(items: _receipt.items),
                      const SizedBox(height: 20),
                    ],

                    // ── Action buttons ─────────────────────────────────────
                    if (isNew)
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Submit to Google Sheets'),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updated = _receipt.copyWith(
      storeName: _storeCtrl.text.trim(),
      date: _date ?? DateTime.now(),
      subtotal: double.tryParse(_subtotalCtrl.text) ?? _receipt.subtotal,
      tax: double.tryParse(_taxCtrl.text) ?? _receipt.tax,
      total: double.tryParse(_totalCtrl.text) ?? _receipt.total,
      category: _categoryCtrl.text.trim().isEmpty
          ? null
          : _categoryCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    // Check auth before submitting
    final provider = context.read<ReceiptProvider>();
    if (!provider.isSignedIn) {
      final signedIn = await provider.signIn();
      if (!mounted) return;
      if (!signedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in required to sync to Sheets.')),
        );
        return;
      }
    }

    final ok = await provider.submitReceipt(updated);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt saved to Google Sheets ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.readOnly,
    required this.onChanged,
  });

  final DateTime? date;
  final bool readOnly;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = date != null
        ? DateFormat.yMMMd().format(date!)
        : 'Select date';

    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (!readOnly) const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});
  final List<ReceiptItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            children: const [
              _TH('Item'),
              _TH('Qty'),
              _TH('Price'),
            ],
          ),
          ...items.map(
            (item) => TableRow(
              children: [
                _TD(item.description),
                _TD('${item.quantity}'),
                _TD(item.totalPrice.toStringAsFixed(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  const _TD(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
