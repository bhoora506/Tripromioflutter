import os

path = r'D:\development\tripromio\lib\routes\app_routes.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if 'preferredDestinations = ' not in content:
    content = content.replace(
        "static const String editInterests = '/profile/interests';",
        "static const String editInterests = '/profile/interests';\n  static const String preferredDestinations = '/profile/destinations';"
    )
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated app_routes.dart')

path_router = r'D:\development\tripromio\lib\routes\app_router.dart'
with open(path_router, 'r', encoding='utf-8') as f:
    router_content = f.read()

if 'preferred_destinations_screen.dart' not in router_content:
    router_content = router_content.replace(
        "import '../presentation/screens/profile/edit_interests_screen.dart';",
        "import '../presentation/screens/profile/edit_interests_screen.dart';\nimport '../presentation/screens/profile/preferred_destinations_screen.dart';"
    )
    
if 'AppRoutes.preferredDestinations' not in router_content:
    router_content = router_content.replace(
        "AppRoutes.editProfile => const EditProfileScreen(),",
        "AppRoutes.editProfile => const EditProfileScreen(),\n      AppRoutes.preferredDestinations => const PreferredDestinationsScreen(),"
    )
    with open(path_router, 'w', encoding='utf-8') as f:
        f.write(router_content)
    print('Updated app_router.dart')
