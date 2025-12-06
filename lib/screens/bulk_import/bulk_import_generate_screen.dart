import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../app_colors.dart';
import '../../services/bulk_import_service.dart';

class BulkImportGenerateScreen extends StatefulWidget {
  const BulkImportGenerateScreen({super.key});

  @override
  State<BulkImportGenerateScreen> createState() => _BulkImportGenerateScreenState();
}

class _BulkImportGenerateScreenState extends State<BulkImportGenerateScreen> {
  late BulkImportConfig config;
  bool isGenerating = false;
  bool isGenerated = false;
  String? generatedFilePath;
  String? errorMessage;

  final BulkImportService _bulkImportService = BulkImportService();
  final List<TextEditingController> _scheduleNameControllers = [];
  final List<TextEditingController> _teamNameControllers = [];
  final List<TextEditingController> _gameCountControllers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BulkImportConfig) {
      config = args;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _scheduleNameControllers.clear();
    _teamNameControllers.clear();
    _gameCountControllers.clear();

    for (int i = 0; i < config.numberOfSchedules; i++) {
      final existingConfig =
          i < config.scheduleConfigs.length ? config.scheduleConfigs[i] : null;

      _scheduleNameControllers.add(TextEditingController(
        text: existingConfig?.scheduleName ?? 'Schedule ${i + 1}',
      ));
      _teamNameControllers.add(TextEditingController(
        text: existingConfig?.teamName ?? 'Team ${i + 1}',
      ));
      _gameCountControllers.add(TextEditingController(
        text: existingConfig?.numberOfGames.toString() ?? '4',
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _scheduleNameControllers) {
      controller.dispose();
    }
    for (final controller in _teamNameControllers) {
      controller.dispose();
    }
    for (final controller in _gameCountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateInputs() {
    for (int i = 0; i < config.numberOfSchedules; i++) {
      if (_scheduleNameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule ${i + 1} name is required')),
        );
        return false;
      }
      if (_teamNameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team ${i + 1} name is required')),
        );
        return false;
      }
      final gameCount = int.tryParse(_gameCountControllers[i].text) ?? 0;
      if (gameCount < 1 || gameCount > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule ${i + 1} must have 1-50 games')),
        );
        return false;
      }
    }
    return true;
  }

  void _updateScheduleConfigs() {
    config = BulkImportConfig(
      numberOfSchedules: config.numberOfSchedules,
      sport: config.sport,
      globalSettings: config.globalSettings,
      globalValues: config.globalValues,
      scheduleConfigs: List.generate(config.numberOfSchedules, (i) {
        return ScheduleConfig(
          scheduleName: _scheduleNameControllers[i].text.trim(),
          teamName: _teamNameControllers[i].text.trim(),
          numberOfGames: int.tryParse(_gameCountControllers[i].text) ?? 4,
        );
      }),
    );
  }

  Future<void> _generateExcel() async {
    if (!_validateInputs()) return;

    setState(() {
      isGenerating = true;
      errorMessage = null;
    });

    _updateScheduleConfigs();

    try {
      final filePath = await _bulkImportService.generateExcelTemplate(config);

      if (filePath != null) {
        setState(() {
          isGenerating = false;
          isGenerated = true;
          generatedFilePath = filePath;
        });
      } else {
        setState(() {
          isGenerating = false;
          errorMessage = 'Failed to generate Excel file';
        });
      }
    } catch (e) {
      setState(() {
        isGenerating = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _shareFile() async {
    if (generatedFilePath == null) return;

    try {
      await Share.shareXFiles(
        [XFile(generatedFilePath!)],
        text: 'Bulk Game Import Template',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Configure Schedules',
          style: TextStyle(color: AppColors.efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isGenerated ? _buildSuccessView() : _buildConfigView(),
    );
  }

  Widget _buildConfigView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the name and number of games for each schedule.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Schedule config cards
                ...List.generate(config.numberOfSchedules, (index) {
                  return _buildScheduleConfigCard(index);
                }),

                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          color: AppColors.efficialsBlack,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: ElevatedButton(
            onPressed: isGenerating ? null : _generateExcel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.efficialsYellow,
              foregroundColor: AppColors.efficialsBlack,
              disabledBackgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Generate Excel File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleConfigCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.efficialsYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Schedule ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.efficialsYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.description,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Schedule Name
          TextField(
            controller: _scheduleNameControllers[index],
            decoration: InputDecoration(
              labelText: 'Schedule Name',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'e.g., Edwardsville Varsity',
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Team Name
          TextField(
            controller: _teamNameControllers[index],
            decoration: InputDecoration(
              labelText: 'Team Name',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'e.g., Edwardsville Tigers',
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Number of Games
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gameCountControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Number of Games',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: '4',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      final current = int.tryParse(_gameCountControllers[index].text) ?? 0;
                      if (current < 50) {
                        _gameCountControllers[index].text = (current + 1).toString();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.efficialsYellow),
                  ),
                  IconButton(
                    onPressed: () {
                      final current = int.tryParse(_gameCountControllers[index].text) ?? 0;
                      if (current > 1) {
                        _gameCountControllers[index].text = (current - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Excel File Generated!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your bulk import template has been created with ${config.numberOfSchedules} schedule${config.numberOfSchedules == 1 ? '' : 's'}.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // File path info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description, color: AppColors.efficialsYellow),
                    SizedBox(width: 12),
                    Text(
                      'File Location',
                      style: TextStyle(
                        color: AppColors.efficialsYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  generatedFilePath ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.share),
              label: const Text(
                'Share Excel File',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Next steps
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Steps:',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Open the Excel file\n'
                  '2. Fill in Date and Opponent for each game\n'
                  '3. Add Link Groups for linked games\n'
                  '4. Save and return here to upload',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Done button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/bulk_import_upload',
                  arguments: config,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.efficialsYellow,
                side: const BorderSide(color: AppColors.efficialsYellow),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue to Upload',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

