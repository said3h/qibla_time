enum NearbyPlaceCategory {
  mosque,
  halalRestaurant,
  halalButcher,
}

enum HalalVerificationStatus {
  verified,
  possible,
}

class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.name,
    this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.wheelchair,
    this.distanceMeters,
    this.halalVerification,
    this.sourceTags = const <String, String>{},
  });

  final String id;
  final NearbyPlaceCategory category;
  final double latitude;
  final double longitude;
  final String source;
  final String? name;
  final String? address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? wheelchair;
  final double? distanceMeters;
  final HalalVerificationStatus? halalVerification;
  final Map<String, String> sourceTags;

  NearbyPlace copyWith({
    double? distanceMeters,
  }) {
    return NearbyPlace(
      id: id,
      category: category,
      latitude: latitude,
      longitude: longitude,
      source: source,
      name: name,
      address: address,
      phone: phone,
      website: website,
      openingHours: openingHours,
      wheelchair: wheelchair,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      halalVerification: halalVerification,
      sourceTags: sourceTags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (openingHours != null) 'openingHours': openingHours,
      if (wheelchair != null) 'wheelchair': wheelchair,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (halalVerification != null)
        'halalVerification': halalVerification!.name,
      if (sourceTags.isNotEmpty) 'sourceTags': sourceTags,
    };
  }

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      id: json['id'] as String,
      category: NearbyPlaceCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => NearbyPlaceCategory.mosque,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      source: json['source'] as String? ?? 'OpenStreetMap',
      name: json['name'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['openingHours'] as String?,
      wheelchair: json['wheelchair'] as String?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      halalVerification: switch (json['halalVerification']) {
        'verified' => HalalVerificationStatus.verified,
        'possible' => HalalVerificationStatus.possible,
        _ => null,
      },
      sourceTags: (json['sourceTags'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value.toString())) ??
          const <String, String>{},
    );
  }
}
