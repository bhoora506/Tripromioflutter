import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripromio/data/models/user_model.dart';
import 'package:tripromio/presentation/screens/profile/edit_profile_screen.dart';

void main() {
  testWidgets('Test EditProfileScreen Travel Style crash', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR CAUGHT: ${details.exceptionAsString()}');
      print(details.stack);
    };

    final user = const UserModel(
      id: 1,
      name: 'Test',
      email: 'test@test.com',
      createdAt: '2023-01-01',
      profile: UserProfileModel(travelStyle: 'adventure'),
    );

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: RouteSettings(arguments: user),
          builder: (context) => const EditProfileScreen(),
        );
      },
    ));
    await tester.pumpAndSettle();

    final finder = find.byType(GestureDetector).last;
    await tester.tap(finder);
    
    // Instead of pumpAndSettle, just pump once to trigger the build of the bottom sheet
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
