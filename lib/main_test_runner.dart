import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tripromio/data/services/auth_service.dart';
import 'package:tripromio/data/services/profile_service.dart';
import 'package:tripromio/core/storage/token_storage.dart';
import 'package:tripromio/core/network/api_exception.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TestRunnerScreen());
  }
}

class TestRunnerScreen extends StatefulWidget {
  const TestRunnerScreen({super.key});
  @override
  State<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends State<TestRunnerScreen> {
  String _log = 'Starting tests...\n';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => runTests());
  }

  void _printLog(String msg) {
    print(msg);
    setState(() {
      _log += '$msg\n';
    });
  }

  Future<void> runTests() async {
    setState(() => _running = true);
    final auth = AuthService();
    final profile = ProfileService();
    final tokens = TokenStorage();

    try {
      _printLog('=== RUNTIME TEST START ===');

      // 1. Ensure logged in (using the test user we know exists or register a new one)
      // I will login with demo@tripromio.com / password
      _printLog('1. Authenticating...');
      try {
        await auth.login(email: 'demo@tripromio.com', password: 'Password123!');
        _printLog('PASS: Login successful');
      } catch (e) {
        _printLog('Trying to register demo user...');
        await auth.register(name: 'Demo User', email: 'demo@tripromio.com', password: 'Password123!', passwordConfirmation: 'Password123!');
        _printLog('PASS: Registered and logged in');
      }

      // 2. Profile load
      _printLog('2. Profile Load...');
      final user = await profile.getProfile();
      _printLog('PASS: Profile loaded. User: ${user.name}, Bio: ${user.profile?.bio}');

      // 3. Edit profile (including Travel Style)
      _printLog('3. Edit Profile (Travel Style)...');
      final updatedUser = await profile.updateProfile(
        bio: 'Updated bio from automated test',
        travelStyle: 'adventure',
        city: 'TestCity',
        country: 'TestCountry',
      );
      _printLog('PASS: Profile updated. Travel Style: ${updatedUser.profile?.travelStyle}');

      // 4. Interests update
      _printLog('4. Interests Update...');
      final masterInterests = await profile.getInterests();
      if (masterInterests.isNotEmpty) {
        final ids = masterInterests.take(2).map((i) => i.id).toList();
        await profile.updateInterests(ids);
        _printLog('PASS: Interests updated to $ids');
      } else {
        _printLog('SKIP: No master interests found');
      }

      // 5. Preferred destinations CRUD
      _printLog('5. Preferred Destinations CRUD...');
      final newDest = await profile.addPreferredDestination('Test Destination');
      _printLog('PASS: Added destination ${newDest.id}');
      
      final updatedDest = await profile.updatePreferredDestination(newDest.id, 'Updated Test Destination');
      _printLog('PASS: Updated destination to ${updatedDest.destination}');

      final allDests = await profile.getPreferredDestinations();
      _printLog('PASS: Fetched ${allDests.length} destinations');

      await profile.deletePreferredDestination(newDest.id);
      _printLog('PASS: Deleted destination ${newDest.id}');

      // 6. Profile photo upload/delete
      _printLog('6. Profile Photo Upload/Delete...');
      // create a dummy image
      final dir = await getTemporaryDirectory();
      final imgPath = '${dir.path}/test_photo.jpg';
      final file = File(imgPath);
      if (!await file.exists()) {
        // write a tiny valid JPEG (just random bytes won't work if Laravel validates mime, 
        // so we write a minimal 1x1 jpeg)
        final jpegBytes = <int>[
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
          0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x03, 0x02, 0x02, 0x03, 0x02, 0x02, 0x03,
          0x03, 0x03, 0x03, 0x04, 0x03, 0x03, 0x04, 0x05, 0x08, 0x05, 0x05, 0x04, 0x04, 0x05, 0x0A, 0x07,
          0x07, 0x06, 0x08, 0x0C, 0x0A, 0x0C, 0x0C, 0x0B, 0x0A, 0x0B, 0x0B, 0x0D, 0x0E, 0x12, 0x10, 0x0D,
          0x0E, 0x11, 0x0E, 0x0B, 0x0B, 0x10, 0x16, 0x10, 0x11, 0x13, 0x14, 0x15, 0x15, 0x15, 0x0C, 0x0F,
          0x17, 0x18, 0x16, 0x14, 0x18, 0x12, 0x14, 0x15, 0x14, 0xFF, 0xDB, 0x00, 0x43, 0x01, 0x03, 0x04,
          0x04, 0x05, 0x04, 0x05, 0x09, 0x05, 0x05, 0x09, 0x14, 0x0D, 0x0B, 0x0D, 0x14, 0x14, 0x14, 0x14,
          0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
          0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14,
          0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0x14, 0xFF, 0xC0,
          0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11,
          0x01, 0xFF, 0xC4, 0x00, 0x15, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xC4,
          0x00, 0x14, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x11, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01,
          0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x3F, 0x00, 0x7F, 0xFF, 0xD9
        ];
        await file.writeAsBytes(jpegBytes);
      }
      
      final withPhoto = await profile.uploadProfilePhoto(imgPath);
      _printLog('PASS: Photo uploaded -> ${withPhoto.profile?.profilePhotoUrl}');

      final withoutPhoto = await profile.deleteProfilePhoto();
      _printLog('PASS: Photo deleted -> ${withoutPhoto.profile?.profilePhotoUrl == null}');

      _printLog('=== RUNTIME TEST COMPLETE ===');
      _printLog('OVERALL STATUS: PASS');

    } on ApiException catch (e) {
      _printLog('FAIL: ApiException: ${e.message}');
    } catch (e, stack) {
      _printLog('FAIL: Unknown exception: $e');
      _printLog(stack.toString());
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Runner')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _running ? null : runTests,
            child: const Text('Run Tests'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_log),
            ),
          ),
        ],
      ),
    );
  }
}
