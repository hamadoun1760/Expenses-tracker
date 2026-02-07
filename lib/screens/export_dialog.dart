import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import '../utils/currency_formatter.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  ExportType _selectedType = ExportType.all;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  Map<String, dynamic>? _exportSummary;

  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _loadExportSummary();
  }

  Future<void> _loadExportSummary() async {
    try {
      final summary = await _exportService.getExportSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _exportSummary = summary;
      });
    } catch (e) {
      // Handle error silently or show message
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _loadExportSummary();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _loadExportSummary();
    }
  }

  Future<void> _performExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.exportData(
        format: _selectedFormat,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export réussi! Le fichier a été partagé.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadExportSummary();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined, color: Color(0xFF1976D2)),
          SizedBox(width: 8),
          Text('Exporter les données'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Type Selection
            const Text(
              'Type de données',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<ExportType>(
                  title: const Text('Toutes les données'),
                  subtitle: const Text('Dépenses et revenus'),
                  value: ExportType.all,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                    _loadExportSummary();
                  },
                ),
                RadioListTile<ExportType>(
                  title: const Text('Dépenses seulement'),
                  value: ExportType.expenses,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                    _loadExportSummary();
                  },
                ),
                RadioListTile<ExportType>(
                  title: const Text('Revenus seulement'),
                  value: ExportType.income,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                    _loadExportSummary();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format Selection
            const Text(
              'Format d\'export',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ExportFormat>(
                    title: const Text('CSV'),
                    subtitle: const Text('Pour Excel'),
                    value: ExportFormat.csv,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<ExportFormat>(
                    title: const Text('PDF'),
                    subtitle: const Text('Rapport professionnel'),
                    value: ExportFormat.pdf,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Range Filter
            const Text(
              'Période (optionnel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Début', style: TextStyle(fontSize: 12)),
                          Text(
                            _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : 'Sélectionner',
                            style: TextStyle(
                              color: _startDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fin', style: TextStyle(fontSize: 12)),
                          Text(
                            _endDate != null
                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                : 'Sélectionner',
                            style: TextStyle(
                              color: _endDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: _clearDateFilters,
                  child: const Text('Effacer les filtres de date'),
                ),
              ),
            const SizedBox(height: 16),

            // Export Summary
            if (_exportSummary != null) ...[
              const Text(
                'Aperçu de l\'export',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedType == ExportType.all || _selectedType == ExportType.expenses)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dépenses:'),
                          Text(
                            '${_exportSummary!['expenses_count']} entrées • ${CurrencyFormatter.format(_exportSummary!['total_expenses'] as double)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (_selectedType == ExportType.all || _selectedType == ExportType.income)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Revenus:'),
                          Text(
                            '${_exportSummary!['incomes_count']} entrées • ${CurrencyFormatter.format(_exportSummary!['total_incomes'] as double)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    if (_selectedType == ExportType.all)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Solde net:'),
                          Text(
                            CurrencyFormatter.formatWithCurrency(_exportSummary!['net_income'] as double),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (_exportSummary!['net_income'] as double) >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : _performExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Exporter'),
        ),
      ],
    );
  }
}