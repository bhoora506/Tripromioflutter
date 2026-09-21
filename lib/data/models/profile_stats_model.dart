class ProfileStatsModel {
  const ProfileStatsModel({
    required this.tripsCount,
    required this.connectionsCount,
  });

  final int tripsCount;
  final int connectionsCount;

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      tripsCount: json['trips_count'] as int? ?? 0,
      connectionsCount: json['connections_count'] as int? ?? 0,
    );
  }
}
