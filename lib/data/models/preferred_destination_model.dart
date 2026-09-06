class PreferredDestinationModel {
  const PreferredDestinationModel({
    required this.id,
    required this.destination,
    this.placeId,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final int id;
  final String destination;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? createdAt;

  factory PreferredDestinationModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing for ID
    int parsedId;
    if (json['id'] is int) {
      parsedId = json['id'] as int;
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      parsedId = 0;
    }

    // Safe parsing for latitude
    double? parsedLat;
    if (json['latitude'] is double) {
      parsedLat = json['latitude'] as double;
    } else if (json['latitude'] is int) {
      parsedLat = (json['latitude'] as int).toDouble();
    } else if (json['latitude'] is String) {
      parsedLat = double.tryParse(json['latitude'] as String);
    }

    // Safe parsing for longitude
    double? parsedLng;
    if (json['longitude'] is double) {
      parsedLng = json['longitude'] as double;
    } else if (json['longitude'] is int) {
      parsedLng = (json['longitude'] as int).toDouble();
    } else if (json['longitude'] is String) {
      parsedLng = double.tryParse(json['longitude'] as String);
    }

    return PreferredDestinationModel(
      id: parsedId,
      destination: json['destination']?.toString() ?? '',
      placeId: json['place_id']?.toString(),
      latitude: parsedLat,
      longitude: parsedLng,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'place_id': placeId,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
      };

  @override
  String toString() =>
      'PreferredDestinationModel(id: $id, destination: $destination)';
}
