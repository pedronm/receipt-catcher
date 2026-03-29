import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _spreadsheetCtrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReceiptProvider>();
    _spreadsheetCtrl =
        TextEditingController(text: provider.spreadsheetId);
  }

  @override
  void dispose() {
    _spreadsheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Google Account ──────────────────────────────────────────
              _Section(
                title: 'Google Account',
                child: provider.isSignedIn
                    ? Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('Signed in'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => provider.signOut(),
                            child: const Text('Sign out'),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _signIn(context, provider),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
              ),
              const SizedBox(height: 24),

              // ── Spreadsheet ─────────────────────────────────────────────
              _Section(
                title: 'Google Spreadsheet',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paste the ID from your Google Sheets URL:\n'
                      'https://docs.google.com/spreadsheets/d/<ID>/edit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _spreadsheetCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Spreadsheet ID',
                        hintText: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _saveSpreadsheetId(context, provider),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── How it works ────────────────────────────────────────────
              _Section(
                title: 'How it works',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HowItWorksStep(
                      number: '1',
                      text: 'Sign in with your Google account.',
                    ),
                    _HowItWorksStep(
                      number: '2',
                      text: 'Paste the ID of a Google Sheets spreadsheet you '
                          'own or have edit access to.',
                    ),
                    _HowItWorksStep(
                      number: '3',
                      text: 'Upload a PDF receipt. Gemini AI extracts the '
                          'details automatically.',
                    ),
                    _HowItWorksStep(
                      number: '4',
                      text: 'Review the data and submit. Each receipt gets a '
                          'unique ID that is written to both the "receipts" '
                          'and "items" tabs for cross-table reference.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signIn(BuildContext context, ReceiptProvider provider) async {
    final ok = await provider.signIn();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Signed in successfully ✓' : 'Sign-in failed.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveSpreadsheetId(
    BuildContext context,
    ReceiptProvider provider,
  ) async {
    final id = _spreadsheetCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Spreadsheet ID.')),
      );
      return;
    }
    await provider.setSpreadsheetId(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spreadsheet ID saved ✓'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
