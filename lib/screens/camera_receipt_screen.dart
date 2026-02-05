import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ocr_service.dart';
import 'add_edit_expense_screen.dart';

class CameraReceiptScreen extends StatefulWidget {
  const CameraReceiptScreen({super.key});

  @override
  State<CameraReceiptScreen> createState() => _CameraReceiptScreenState();
}

class _CameraReceiptScreenState extends State<CameraReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  OCRResult? _ocrResult;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un reçu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 16),
            _buildImagePickerSection(),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 16),
            ],
            if (_isProcessing) _buildProcessingIndicator(),
            if (_ocrResult != null) ...[
              _buildOCRResultCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
            if (_errorMessage != null) _buildErrorCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Prenez une photo claire du reçu\n'
              '2. Assurez-vous que le texte est lisible\n'
              '3. Évitez les reflets et les ombres\n'
              '4. Le reçu doit être entièrement visible',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Prendre une photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Depuis la galerie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image sélectionnée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processImage,
                icon: const Icon(Icons.text_fields),
                label: const Text('Analyser le reçu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyse en cours...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Reconnaissance du texte et extraction des informations',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRResultCard() {
    if (_ocrResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations extraites',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Magasin',
              _ocrResult!.merchant ?? 'Non détecté',
              Icons.store,
            ),
            _buildInfoRow(
              'Date',
              '${_ocrResult!.date.day}/${_ocrResult!.date.month}/${_ocrResult!.date.year}',
              Icons.calendar_today,
            ),
            _buildInfoRow(
              'Montant total',
              _ocrResult!.totalAmount != null 
                  ? '${_ocrResult!.totalAmount!.toStringAsFixed(0)} FCFA'
                  : 'Non détecté',
              Icons.euro,
            ),
            _buildInfoRow(
              'Catégorie',
              _getCategoryDisplayName(_ocrResult!.category),
              Icons.category,
            ),
            if (_ocrResult!.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Articles détectés (${_ocrResult!.items.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._ocrResult!.items.take(5).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.amount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
              if (_ocrResult!.items.length > 5)
                Text(
                  '... et ${_ocrResult!.items.length - 5} autres articles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetProcess,
            icon: const Icon(Icons.refresh),
            label: const Text('Recommencer'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _createExpenseFromOCR,
            icon: const Icon(Icons.add),
            label: const Text('Créer la dépense'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Erreur',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
      _ocrResult = null;
    });

    // Request camera permission if needed
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Permission d\'accès à la caméra refusée';
        });
        return;
      }
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection de l\'image: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await OCRService.extractTextFromImage(_selectedImage!.path);
      setState(() {
        _ocrResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'analyse: $e';
        _isProcessing = false;
      });
    }
  }

  void _resetProcess() {
    setState(() {
      _selectedImage = null;
      _ocrResult = null;
      _errorMessage = null;
      _isProcessing = false;
    });
  }

  void _createExpenseFromOCR() {
    if (_ocrResult == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(
          initialData: {
            'title': _ocrResult!.merchant ?? 'Dépense depuis reçu',
            'amount': _ocrResult!.totalAmount ?? 0.0,
            'category': _ocrResult!.category,
            'date': _ocrResult!.date,
            'receiptImagePath': _selectedImage?.path,
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  String _getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case 'food':
        return 'Alimentation';
      case 'transportation':
        return 'Transport';
      case 'shopping':
        return 'Achats';
      case 'entertainment':
        return 'Loisirs';
      case 'health':
        return 'Santé';
      case 'education':
        return 'Éducation';
      case 'other':
        return 'Autres';
      default:
        return categoryKey;
    }
  }
}