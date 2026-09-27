import sys

file_path = "D:\\development\\tripromio\\lib\\presentation\\screens\\trips\\edit_trip_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Try a more robust replacement for the UI
old_ui_start = "                  crossAxisAlignment: CrossAxisAlignment.stretch,\n                children: [\n                  // Title"

new_ui_start = """                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

if old_ui_start in content:
    content = content.replace(old_ui_start, new_ui_start)
    print("Replaced UI successfully")
else:
    print("Failed to find old UI start. Checking with regex.")
    import re
    if re.search(r'crossAxisAlignment:\s+CrossAxisAlignment.stretch,\s+children:\s+\[\s+// Title', content):
        content = re.sub(
            r'(crossAxisAlignment:\s+CrossAxisAlignment.stretch,\s+children:\s+\[)', 
            r'\1' + "\n" + "\n".join(new_ui_start.split("\n")[2:-1]), 
            content
        )
        print("Replaced UI with regex successfully")
    else:
        print("Regex also failed to find.")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
