import sys

file_path = "D:\\development\\tripromio\\lib\\presentation\\screens\\trips\\edit_trip_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Imports
if "package:image_picker/image_picker.dart" not in content:
    content = content.replace(
        "import 'package:google_fonts/google_fonts.dart';",
        "import 'package:google_fonts/google_fonts.dart';\nimport 'dart:io';\nimport 'package:image_picker/image_picker.dart';"
    )

# 2. State variables
variables = """  bool _submitting = false;
  bool _initialized = false;

  String? _selectedImagePath;
  bool _removeImage = false;
  final _imagePicker = ImagePicker();"""
content = content.replace("  bool _submitting = false;\n  bool _initialized = false;", variables)

# 3. Image methods
methods = """  Future<void> _pickImage(ImageSource source) async {
    if (!_fullEdit) return;
    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImagePath = picked.path;
          _removeImage = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _onRemoveImage() {
    if (!_fullEdit) return;
    setState(() {
      _selectedImagePath = null;
      _removeImage = true;
    });
  }

  void _showTripTypePicker() {"""
content = content.replace("  void _showTripTypePicker() {", methods)

# 4. _submit check
old_check = """      if (newTitle == null &&
          newDesc == null &&
          newDest == null &&
          newStartDate == null &&
          newEndDate == null &&
          newTripType == null &&
          newMaxMembers == null &&
          newBudgetMin == null &&
          newBudgetMax == null &&
          newInterestIds == null) {"""
new_check = """      if (newTitle == null &&
          newDesc == null &&
          newDest == null &&
          newStartDate == null &&
          newEndDate == null &&
          newTripType == null &&
          newMaxMembers == null &&
          newBudgetMin == null &&
          newBudgetMax == null &&
          newInterestIds == null &&
          _selectedImagePath == null &&
          !_removeImage) {"""
content = content.replace(old_check, new_check)

# 5. updateTrip args
old_update = """        final updated = await _tripService.updateTrip(
          _trip!.id,
          title: newTitle,
          destination: newDest,
          startDate: newStartDate,
          endDate: newEndDate,
          tripType: newTripType,
          maxMembers: newMaxMembers,
          description: newDesc,
          budgetMin: newBudgetMin,
          budgetMax: newBudgetMax,
          interestIds: newInterestIds,
        );"""
new_update = """        final updated = await _tripService.updateTrip(
          _trip!.id,
          title: newTitle,
          destination: newDest,
          startDate: newStartDate,
          endDate: newEndDate,
          tripType: newTripType,
          maxMembers: newMaxMembers,
          description: newDesc,
          budgetMin: newBudgetMin,
          budgetMax: newBudgetMax,
          interestIds: newInterestIds,
          imagePath: _selectedImagePath,
          removeImage: _removeImage ? true : null,
        );"""
content = content.replace(old_update, new_update)

# 6. UI Banner
old_ui = """                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Title"""
new_ui = """                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner Image
                    if (_fullEdit) ...[
                      if (_selectedImagePath == null && (_trip?.imageUrl == null || _removeImage))
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                              border: Border.all(color: AppColors.borderLight, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: AppColors.primary),
                                const SizedBox(height: AppConstants.spacingSm),
                                Text(
                                  'Add Trip Banner',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Stack(
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                                image: DecorationImage(
                                  image: _selectedImagePath != null
                                      ? FileImage(File(_selectedImagePath!)) as ImageProvider
                                      : NetworkImage(_trip!.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickImage(ImageSource.gallery),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Change Banner',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _onRemoveImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 16, color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                  // Title"""
content = content.replace(old_ui, new_ui)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("done")
