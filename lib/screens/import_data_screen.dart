import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/property_provider.dart';
import '../models/models.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  bool _isParsing = false;
  String? _error;
  List<Map<String, dynamic>> _previewData = [];
  Property? _selectedProperty;
  int _successCount = 0;
  int _errorCount = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<PropertyProvider>();
      if (prov.selectedProperty != null) {
        setState(() => _selectedProperty = prov.selectedProperty);
      } else if (prov.properties.isNotEmpty) {
        setState(() => _selectedProperty = prov.properties.first);
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      
      if (result != null && result.files.single.path != null) {
        await _parseFile(result.files.single.path!);
      }
    } catch (e) {
      setState(() => _error = 'Error picking file: $e');
    }
  }

  Future<void> _parseFile(String path) async {
    setState(() {
      _isParsing = true;
      _error = null;
      _previewData = [];
    });

    try {
      final file = File(path);
      final lines = await file.readAsLines();
      
      if (lines.isEmpty) {
        throw Exception('Empty file');
      }

      // Skip header line
      final dataLines = lines.skip(1).where((l) => l.trim().isNotEmpty).toList();
      
      final preview = <Map<String, dynamic>>[];
      
      for (final line in dataLines.take(20)) { // Preview first 20 rows
        final parsed = _parseLine(line);
        if (parsed != null) {
          preview.add(parsed);
        }
      }
      
      setState(() {
        _previewData = preview;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing file: $e';
        _isParsing = false;
      });
    }
  }

  Map<String, dynamic>? _parseLine(String line) {
    // Simple CSV parser - adjust based on your format
    final parts = line.split('\t'); // Tab-separated based on your data
    
    if (parts.length < 4) return null;
    
    try {
      final dateStr = parts[0].trim();
      
      // Parse "Jul 2021" format
      final months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      final dateParts = dateStr.toLowerCase().split(' ');
      if (dateParts.length != 2) return null;
      
      final month = months[dateParts[0]];
      final year = int.tryParse(dateParts[1]);
      
      if (month == null || year == null) return null;
      
      // Parse amounts - remove R and commas
      double parseAmount(String s) {
        final clean = s.replaceAll('R', '').replaceAll(',', '').trim();
        return double.tryParse(clean) ?? 0.0;
      }
      
      final water = parts.length > 2 ? parseAmount(parts[2]) : 0.0;
      final electricity = parts.length > 3 ? parseAmount(parts[3]) : 0.0;
      final interest = parts.length > 4 ? parseAmount(parts[4]) : 0.0;
      final annualLevy = parts.length > 5 ? parseAmount(parts[5]) : null;
      final notes = parts.length > 6 ? parts[6].trim() : null;
      
      return {
        'year': year,
        'month': month,
        'water': water,
        'electricity': electricity,
        'interest': interest,
        'annualLevy': annualLevy,
        'notes': notes,
        'hasData': water > 0 || electricity > 0 || interest > 0 || (annualLevy ?? 0) > 0,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _importData() async {
    if (_selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property first')),
      );
      return;
    }

    setState(() {
      _isParsing = true;
      _successCount = 0;
      _errorCount = 0;
    });

    try {
      final prov = context.read<PropertyProvider>();
      
      for (final row in _previewData) {
        try {
          final expense = MonthlyExpense(
            propertyId: _selectedProperty!.id,
            year: row['year'] as int,
            month: row['month'] as int,
            water: row['water'] as double,
            electricity: row['electricity'] as double,
            interest: row['interest'] as double,
            ratesTaxes: 0,
            annualLevy: row['annualLevy'] as double?,
            paymentReceived: 0,
            notes: row['notes'] as String?,
          );
          
          await prov.upsertExpense(expense);
          setState(() => _successCount++);
        } catch (_) {
          setState(() => _errorCount++);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $_successCount records successfully'),
            backgroundColor: _errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
        
        setState(() {
          _previewData = [];
          _isParsing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Import error: $e';
        _isParsing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import CSV Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Property',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Property>(
                      initialValue: _selectedProperty,
                      decoration: const InputDecoration(
                        labelText: 'Property',
                        border: OutlineInputBorder(),
                      ),
                      items: context.watch<PropertyProvider>().properties
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (p) => setState(() => _selectedProperty = p),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // File picker button
            ElevatedButton.icon(
              onPressed: _isParsing ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select CSV File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                        size: 20, 
                        color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Format Requirements',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'CSV should have columns: Date, Property, Water, Electricity, Interest, Annual Levy, Notes\n\n'
                    'Date format: "Jul 2021"\n'
                    'Amounts can include "R" and commas (e.g., "R1,234.56")',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_previewData.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview (${_previewData.length} of ${_previewData.length} rows)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_successCount > 0)
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16),
                      label: Text('$_successCount imported'),
                      backgroundColor: Colors.green.withAlpha(40),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _previewData.length,
                  itemBuilder: (ctx, i) {
                    final row = _previewData[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        DateFormat('MMM yyyy').format(DateTime(row['year'] as int, row['month'] as int)),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Water: R${(row['water'] as double).toStringAsFixed(2)} | Elec: R${(row['electricity'] as double).toStringAsFixed(2)} | Int: R${(row['interest'] as double).toStringAsFixed(2)}',
                      ),
                      trailing: row['hasData'] as bool? ?? false
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.remove, color: Colors.grey),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _isParsing ? null : _importData,
                icon: const Icon(Icons.download),
                label: Text(_successCount > 0 ? 'Import Remaining' : 'Import All'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            
            if (_isParsing && _previewData.isEmpty) ...[
              const SizedBox(height: 40),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Parsing file...'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
