import os

path = r'D:\development\tripromio\lib\data\services\profile_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'preferred_destination_model.dart' not in content:
    content = content.replace(
        "import '../models/interest_model.dart';",
        "import '../models/interest_model.dart';\nimport '../models/preferred_destination_model.dart';"
    )

new_methods = '''

  // ── GET /api/profile/destinations ─────────────────────────────────────────

  Future<List<PreferredDestinationModel>> getPreferredDestinations() async {
    final response = await _client.get(ApiConstants.profileDestinations);
    final data = response.dataAsMap;
    final destList = data['destinations'] as List<dynamic>? ?? [];
    return destList
        .map((i) => PreferredDestinationModel.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  // ── POST /api/profile/destinations ────────────────────────────────────────

  Future<PreferredDestinationModel> addPreferredDestination(String destination) async {
    final response = await _client.post(
      ApiConstants.profileDestinations,
      body: {'destination': destination},
    );
    final data = response.dataAsMap;
    final destJson = data['destination'] as Map<String, dynamic>?;
    if (destJson == null) {
      return PreferredDestinationModel.fromJson(data);
    }
    return PreferredDestinationModel.fromJson(destJson);
  }

  // ── PUT /api/profile/destinations/{id} ────────────────────────────────────

  Future<PreferredDestinationModel> updatePreferredDestination(int id, String destination) async {
    final response = await _client.put(
      '${ApiConstants.profileDestinations}/$id',
      body: {'destination': destination},
    );
    final data = response.dataAsMap;
    final destJson = data['destination'] as Map<String, dynamic>?;
    if (destJson == null) {
      return PreferredDestinationModel.fromJson(data);
    }
    return PreferredDestinationModel.fromJson(destJson);
  }

  // ── DELETE /api/profile/destinations/{id} ─────────────────────────────────

  Future<void> deletePreferredDestination(int id) async {
    await _client.delete('${ApiConstants.profileDestinations}/$id');
  }
'''

if 'getPreferredDestinations()' not in content:
    content = content.replace('  void dispose() => _client.dispose();', new_methods + '\n  void dispose() => _client.dispose();')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated profile_service.dart')
