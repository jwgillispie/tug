// lib/widgets/analytics/export_dialog.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:tug/services/analytics_service.dart';
import 'package:tug/services/service_locator.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/subscription/premium_feature.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final AnalyticsService _analyticsService = ServiceLocator.analyticsService;
  
  String _selectedFormat = 'pdf';
  int _daysBack = 90;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useCustomDateRange = false;
  bool _includeCharts = true;
  
  final Set<String> _selectedDataTypes = {'all'};
  final List<String> _availableDataTypes = [
    'all',
    'activities', 
    'streaks', 
    'trends', 
    'insights', 
    'breakdown'
  ];
  
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportStatus = '';

  @override
  Widget build(BuildContext context) {
    return PremiumFeature(
      title: 'Analytics Export',
      description: 'Export your analytics data as CSV or PDF reports with charts and insights',
      icon: Icons.file_download,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.file_download,
              color: TugColors.primaryPurple,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Export Analytics Data'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format selection
              const Text(
                'Export Format',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'csv',
                    label: Text('CSV'),
                    icon: Icon(Icons.table_chart),
                  ),
                  ButtonSegment<String>(
                    value: 'pdf',
                    label: Text('PDF'),
                    icon: Icon(Icons.picture_as_pdf),
                  ),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedFormat = newSelection.first;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Date range selection
              const Text(
                'Time Period',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              SwitchListTile(
                title: const Text('Custom Date Range'),
                subtitle: _useCustomDateRange 
                    ? Text(_startDate != null && _endDate != null
                        ? '${_startDate!.toLocal().toString().split(' ')[0]} - ${_endDate!.toLocal().toString().split(' ')[0]}'
                        : 'Select dates')
                    : Text('Last $_daysBack days'),
                value: _useCustomDateRange,
                onChanged: (value) {
                  setState(() {
                    _useCustomDateRange = value;
                    if (!value) {
                      _startDate = null;
                      _endDate = null;
                    }
                  });
                },
                activeColor: TugColors.primaryPurple,
              ),
              
              if (_useCustomDateRange) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectStartDate(),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate != null
                            ? _startDate!.toLocal().toString().split(' ')[0]
                            : 'Start Date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectEndDate(),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate != null
                            ? _endDate!.toLocal().toString().split(' ')[0]
                            : 'End Date'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _daysBack,
                  decoration: const InputDecoration(
                    labelText: 'Number of Days',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                    DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                    DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                    DropdownMenuItem(value: 180, child: Text('Last 180 days')),
                    DropdownMenuItem(value: 365, child: Text('Last year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _daysBack = value;
                      });
                    }
                  },
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Data types selection
              const Text(
                'Data to Include',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: _availableDataTypes.map((dataType) {
                  final isSelected = _selectedDataTypes.contains(dataType);
                  final isAllSelected = _selectedDataTypes.contains('all');
                  
                  return FilterChip(
                    label: Text(_getDataTypeLabel(dataType)),
                    selected: isSelected,
                    onSelected: dataType == 'all' ? null : !isAllSelected ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDataTypes.add(dataType);
                        } else {
                          _selectedDataTypes.remove(dataType);
                        }
                      });
                    } : null,
                    backgroundColor: isAllSelected && dataType != 'all'
                        ? Colors.grey.shade300
                        : null,
                  );
                }).toList(),
              ),
              
              if (_selectedFormat == 'pdf') ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Include Charts'),
                  subtitle: const Text('Add visualizations to PDF report'),
                  value: _includeCharts,
                  onChanged: (value) {
                    setState(() {
                      _includeCharts = value;
                    });
                  },
                  activeColor: TugColors.primaryPurple,
                ),
              ],
              
              // Progress indicator
              if (_isExporting) ...[
                const SizedBox(height: 20),
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _exportProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(TugColors.primaryPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(_exportStatus),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportData,
            icon: _isExporting 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exporting...' : 'Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TugColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getDataTypeLabel(String dataType) {
    switch (dataType) {
      case 'all':
        return 'All Data';
      case 'activities':
        return 'Activities';
      case 'streaks':
        return 'Streaks';
      case 'trends':
        return 'Trends';
      case 'insights':
        return 'Insights';
      case 'breakdown':
        return 'Value Breakdown';
      default:
        return dataType.toUpperCase();
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        // Ensure end date is after start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = date.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _exportData() async {
    if (!_analyticsService.hasPremiumAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium subscription required for data export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStatus = 'Preparing export...';
    });

    try {
      final dataTypes = _selectedDataTypes.contains('all') 
          ? ['all'] 
          : _selectedDataTypes.toList();

      if (_selectedFormat == 'csv') {
        await _exportCSV(dataTypes);
      } else {
        await _exportPDF(dataTypes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0.0;
          _exportStatus = '';
        });
      }
    }
  }

  Future<void> _exportCSV(List<String> dataTypes) async {
    setState(() {
      _exportStatus = 'Generating CSV files...';
      _exportProgress = 0.3;
    });

    final csvFiles = await _analyticsService.exportToCSV(
      daysBack: _daysBack,
      dataTypes: dataTypes,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (csvFiles == null) {
      throw Exception('Failed to generate CSV files');
    }

    setState(() {
      _exportStatus = 'Saving files...';
      _exportProgress = 0.7;
    });

    // Save CSV files to local storage
    final List<String> savedFiles = [];
    
    for (final entry in csvFiles.entries) {
      final fileName = '${entry.key}_analytics.csv';
      final filePath = await _saveToFile(entry.value, fileName);
      if (filePath != null) {
        savedFiles.add(filePath);
      }
    }

    setState(() {
      _exportStatus = 'Export complete';
      _exportProgress = 1.0;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exported ${savedFiles.length} CSV files to Downloads'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // Could open file manager or show file locations
              _showFileLocations(savedFiles);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportPDF(List<String> dataTypes) async {
    setState(() {
      _exportStatus = 'Generating PDF report...';
      _exportProgress = 0.3;
    });

    final pdfData = await _analyticsService.exportToPDF(
      daysBack: _daysBack,
      dataTypes: dataTypes,
      startDate: _startDate,
      endDate: _endDate,
      includeCharts: _includeCharts,
    );

    if (pdfData == null) {
      throw Exception('Failed to generate PDF report');
    }

    setState(() {
      _exportStatus = 'Saving PDF...';
      _exportProgress = 0.7;
    });

    // Decode base64 PDF data
    final pdfBytes = base64Decode(pdfData['pdf_base64']);
    final fileName = pdfData['filename'] ?? 'tug_analytics_report.pdf';
    
    final filePath = await _saveBytesToFile(pdfBytes, fileName);

    setState(() {
      _exportStatus = 'Export complete';
      _exportProgress = 1.0;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully exported PDF report'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (filePath != null) {
                _showFileLocations([filePath]);
              }
            },
          ),
        ),
      );
    }
  }

  Future<String?> _saveToFile(String content, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      return file.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  Future<String?> _saveBytesToFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  void _showFileLocations(List<String> filePaths) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Files Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your files have been saved to:'),
            const SizedBox(height: 16),
            ...filePaths.map((path) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                path,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}