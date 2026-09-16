class TravelAvailabilityModel {
  const TravelAvailabilityModel({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final DateTime startDate;
  final DateTime endDate;

  factory TravelAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return TravelAvailabilityModel(
      id: _parseInt(json['id']),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
      };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}
