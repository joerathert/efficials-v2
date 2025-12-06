import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../app_theme.dart';
import '../../services/bulk_import_service.dart';

class BulkImportPreflightScreen extends StatefulWidget {
  const BulkImportPreflightScreen({super.key});

  @override
  State<BulkImportPreflightScreen> createState() => _BulkImportPreflightScreenState();
}

class _BulkImportPreflightScreenState extends State<BulkImportPreflightScreen> {
  bool isLoading = true;
  Map<String, dynamic> prerequisites = {};

  final BulkImportService _bulkImportService = BulkImportService();

  @override
  void initState() {
    super.initState();
    _checkPrerequisites();
  }

  Future<void> _checkPrerequisites() async {
    setState(() => isLoading = true);

    final result = await _bulkImportService.checkPrerequisites();

    if (mounted) {
      setState(() {
        prerequisites = result;
        isLoading = false;
      });
    }
  }

  bool get canProceed => prerequisites['canProceed'] == true;
  bool get locationsReady => prerequisites['locationsReady'] == true;
  bool get officialsListsReady => prerequisites['officialsListsReady'] == true;
  bool get crewListsReady => prerequisites['crewListsReady'] == true;
  int get locationCount => prerequisites['locationCount'] ?? 0;
  int get officialsListCount => prerequisites['officialsListCount'] ?? 0;
  int get crewListCount => prerequisites['crewListCount'] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Icon(
          Icons.upload_file,
          color: AppColors.efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.efficialsYellow),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Bulk Import Setup',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.efficialsYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Let\'s prepare your data first to ensure smooth Excel generation and import.',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Status Cards
                  _buildStatusCard(
                    icon: Icons.location_on,
                    title: 'Locations',
                    count: locationCount,
                    isReady: locationsReady,
                    description: locationsReady
                        ? 'Great! You have $locationCount location${locationCount == 1 ? '' : 's'} ready.'
                        : 'You need to create at least one location before generating Excel files.',
                    actionText: 'Manage Locations',
                    onActionTap: () async {
                      await Navigator.pushNamed(context, '/locations');
                      _checkPrerequisites();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildStatusCard(
                    icon: Icons.people,
                    title: 'Officials Lists',
                    count: officialsListCount,
                    isReady: officialsListsReady,
                    isSatisfied: officialsListsReady || crewListsReady,
                    description: officialsListsReady
                        ? 'Perfect! You have $officialsListCount list${officialsListCount == 1 ? '' : 's'} of officials ready.'
                        : crewListsReady
                            ? 'Officials Lists not needed - you have crew lists ready.'
                            : 'You need either Officials Lists OR Crew Lists to proceed.',
                    actionText: 'Manage Officials',
                    onActionTap: () async {
                      await Navigator.pushNamed(context, '/lists-of-officials');
                      _checkPrerequisites();
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildStatusCard(
                    icon: Icons.groups,
                    title: 'Crew Lists',
                    count: crewListCount,
                    isReady: crewListsReady,
                    isSatisfied: officialsListsReady || crewListsReady,
                    description: crewListsReady
                        ? 'Excellent! You have $crewListCount crew${crewListCount == 1 ? '' : 's'} available for hire.'
                        : officialsListsReady
                            ? 'Crew Lists not needed - you have officials lists ready.'
                            : 'You need either Officials Lists OR Crew Lists to proceed.',
                    actionText: crewListCount == 0 ? 'Create Crew Lists' : 'Manage Crews',
                    onActionTap: () async {
                      // TODO: Navigate to crew lists when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Crew Lists management coming soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.efficialsYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.efficialsYellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.efficialsYellow,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Having this data ready will ensure your Excel file has valid options for locations and officials assignment.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Upload Existing File Option
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.file_upload,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Already Have an Excel File?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Skip the wizard if you already have a completed Excel file from a previous session.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/bulk_import_upload');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Upload Existing Excel File',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding for button
                ],
              ),
            ),
      bottomNavigationBar: Container(
        color: AppColors.efficialsBlack,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: ElevatedButton(
          onPressed: canProceed
              ? () {
                  Navigator.pushNamed(context, '/bulk_import_wizard');
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.efficialsYellow,
            foregroundColor: AppColors.efficialsBlack,
            disabledBackgroundColor: Colors.grey[700],
            disabledForegroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            canProceed ? 'Create New Excel File' : 'Complete Setup First',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required int count,
    required bool isReady,
    bool? isSatisfied,
    required String description,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    final satisfied = isSatisfied ?? isReady;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: satisfied
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: satisfied ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                satisfied ? Icons.check_circle : Icons.warning,
                color: satisfied ? Colors.green : Colors.red,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                backgroundColor: satisfied
                    ? Colors.grey.withOpacity(0.2)
                    : AppColors.efficialsYellow.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  color: satisfied ? Colors.grey : AppColors.efficialsYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

