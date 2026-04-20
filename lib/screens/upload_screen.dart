import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import 'receipt_detail_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  _UploadStep _step = _UploadStep.pick;
  String? _fileName;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Receipt')),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.status == ProviderStatus.loading;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(currentStep: _step),
                const SizedBox(height: 32),
                Expanded(child: _buildBody(context, isLoading, provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isLoading,
    ReceiptProvider provider,
  ) {
    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _step == _UploadStep.process
                ? 'AI is reading your receipt…'
                : 'Please wait…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return switch (_step) {
      _UploadStep.pick => _PickStep(
          fileName: _fileName,
          errorMsg: _errorMsg,
          onPick: _pickFile,
        ),
      _UploadStep.process => const SizedBox.shrink(), // replaced by spinner
    };
  }

  Future<void> _pickFile() async {
    setState(() => _errorMsg = null);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final path = picked.path;
    if (path == null) {
      setState(() => _errorMsg = 'Could not access the selected file.');
      return;
    }

    setState(() {
      _fileName = picked.name;
      _step = _UploadStep.process;
    });

    final pdfFile = File(path);
    final receipt = await context.read<ReceiptProvider>().processReceipt(pdfFile);

    if (!mounted) return;

    if (receipt == null) {
      setState(() {
        _step = _UploadStep.pick;
        _errorMsg = context.read<ReceiptProvider>().errorMessage;
      });
      return;
    }

    // Navigate to the detail screen for review before submitting.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(
          receipt: receipt,
          isNew: true,
        ),
      ),
    );
  }
}

enum _UploadStep { pick, process }

// ── Step indicator ─────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final _UploadStep currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(
          active: true,
          done: currentStep == _UploadStep.process,
          label: '1. Select PDF',
        ),
        const Expanded(child: Divider()),
        _Dot(
          active: currentStep == _UploadStep.process,
          done: false,
          label: '2. Extract Data',
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.done, required this.label});
  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Icon(
                  Icons.circle,
                  size: 10,
                  color: active ? Colors.white : color,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

// ── Pick step content ──────────────────────────────────────────────────────

class _PickStep extends StatelessWidget {
  const _PickStep({
    this.fileName,
    this.errorMsg,
    required this.onPick,
  });

  final String? fileName;
  final String? errorMsg;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(height: 24),
        Text(
          'Select a PDF receipt from your device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (fileName != null) ...[
          const SizedBox(height: 12),
          Text(
            fileName!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (errorMsg != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMsg!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose PDF'),
        ),
      ],
    );
  }
}
