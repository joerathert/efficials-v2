import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../app_colors.dart';
import '../../services/bulk_import_service.dart';

class BulkImportUploadScreen extends StatefulWidget {
  const BulkImportUploadScreen({super.key});

  @override
  State<BulkImportUploadScreen> createState() => _BulkImportUploadScreenState();
}

class _BulkImportUploadScreenState extends State<BulkImportUploadScreen> {
  String? selectedFilePath;
  String? selectedFileName;
  bool isParsing = false;
  bool isParsed = false;
  List<ParsedGame> parsedGames = [];
  List<String> parseErrors = [];
  BulkImportConfig? config;

  final BulkImportService _bulkImportService = BulkImportService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BulkImportConfig) {
      config = args;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFilePath = result.files.first.path;
          selectedFileName = result.files.first.name;
          isParsed = false;
          parsedGames.clear();
          parseErrors.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _parseFile() async {
    if (selectedFilePath == null) return;

    setState(() {
      isParsing = true;
      parseErrors.clear();
    });

    try {
      // If we don't have a config from the wizard, create a minimal one
      if (config == null) {
        // Get user sport from the service
        config = BulkImportConfig(
          numberOfSchedules: 1,
          sport: 'Unknown',
          globalSettings: {},
          globalValues: {},
          scheduleConfigs: [],
        );
      }

      final games = await _bulkImportService.parseExcelFile(selectedFilePath!, config!);

      // Collect all validation errors
      final errors = <String>[];
      for (final game in games) {
        if (!game.isValid) {
          for (final error in game.errors) {
            errors.add('${game.sheetName} Row ${game.rowNumber}: $error');
          }
        }
      }

      setState(() {
        isParsing = false;
        isParsed = true;
        parsedGames = games;
        parseErrors = errors;
      });
    } catch (e) {
      setState(() {
        isParsing = false;
        parseErrors = ['Error parsing file: $e'];
      });
    }
  }

  void _goToPreview() {
    Navigator.pushNamed(
      context,
      '/bulk_import_preview',
      arguments: {
        'config': config,
        'parsedGames': parsedGames,
      },
    );
  }

  bool get hasValidGames => parsedGames.any((g) => g.isValid);
  int get validGameCount => parsedGames.where((g) => g.isValid).length;
  int get invalidGameCount => parsedGames.where((g) => !g.isValid).length;
  bool get hasErrors => parseErrors.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Upload Excel File',
          style: TextStyle(color: AppColors.efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Your Excel File',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your completed bulk import Excel file.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 30),

            // File picker card
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedFilePath != null
                        ? AppColors.efficialsYellow.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      selectedFilePath != null ? Icons.description : Icons.cloud_upload,
                      color: selectedFilePath != null
                          ? AppColors.efficialsYellow
                          : Colors.grey,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedFilePath != null
                          ? selectedFileName ?? 'File selected'
                          : 'Tap to select Excel file',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedFilePath != null ? Colors.white : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '.xlsx or .xls files only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (selectedFilePath != null && !isParsed) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isParsing ? null : _parseFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.efficialsYellow,
                    foregroundColor: AppColors.efficialsBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isParsing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Validate File',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],

            // Parsing results
            if (isParsed) ...[
              const SizedBox(height: 30),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: hasErrors
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasErrors
                        ? Colors.red.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasErrors ? Icons.warning : Icons.check_circle,
                          color: hasErrors ? Colors.red : Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasErrors ? 'Validation Errors Found' : 'Validation Passed!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: hasErrors ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _buildStatChip(
                          'Total Games',
                          parsedGames.length.toString(),
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          'Valid',
                          validGameCount.toString(),
                          Colors.green,
                        ),
                        const SizedBox(width: 12),
                        if (invalidGameCount > 0)
                          _buildStatChip(
                            'Invalid',
                            invalidGameCount.toString(),
                            Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Error list
              if (hasErrors) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            '${parseErrors.length} Error${parseErrors.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: parseErrors.map((error) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    Expanded(
                                      child: Text(
                                        error,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fail-all notice
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All errors must be fixed before importing. Please correct the Excel file and re-upload.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Game preview (first few games)
              if (parsedGames.isNotEmpty && !hasErrors) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview (First 5 Games)',
                        style: TextStyle(
                          color: AppColors.efficialsYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...parsedGames.take(5).map((game) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'vs ${game.opponent ?? 'Unknown'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${game.date != null ? '${game.date!.month}/${game.date!.day}/${game.date!.year}' : 'No date'} • ${game.scheduleName}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (game.linkGroup != null && game.linkGroup!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Link ${game.linkGroup}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (parsedGames.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${parsedGames.length - 5} more games',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: isParsed && !hasErrors
          ? Container(
              color: AppColors.efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: _goToPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.efficialsYellow,
                  foregroundColor: AppColors.efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Preview & Import',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : isParsed && hasErrors
              ? Container(
                  color: AppColors.efficialsBlack,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Select Different File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

