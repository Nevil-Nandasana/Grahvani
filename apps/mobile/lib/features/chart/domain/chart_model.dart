/// Chart Domain Models — BirthChart, PlanetPlacement, DashaPeriod
library;

import 'package:flutter/foundation.dart';

@immutable
class PlanetPlacement {
  const PlanetPlacement({
    required this.name,
    required this.longitude,
    required this.zodiacSign,
    required this.house,
    required this.degreeInSign,
    required this.nakshatra,
    required this.pada,
    required this.isRetrograde,
  });

  final String name;
  final double longitude;
  final String zodiacSign;
  final int house;
  final double degreeInSign;
  final String nakshatra;
  final int pada;
  final bool isRetrograde;

  factory PlanetPlacement.fromJson(Map<String, dynamic> json) {
    return PlanetPlacement(
      name: json['name'] as String,
      longitude: (json['longitude'] as num).toDouble(),
      zodiacSign: json['zodiac_sign'] as String,
      house: json['house'] as int,
      degreeInSign: (json['degree_in_sign'] as num).toDouble(),
      nakshatra: json['nakshatra'] as String,
      pada: json['pada'] as int,
      isRetrograde: json['is_retrograde'] as bool? ?? false,
    );
  }

  String get displayName => isRetrograde ? '$name ℛ' : name;
}

@immutable
class Ascendant {
  const Ascendant({required this.longitude, required this.zodiacSign});

  final double longitude;
  final String zodiacSign;

  factory Ascendant.fromJson(Map<String, dynamic> json) {
    return Ascendant(
      longitude: (json['longitude'] as num).toDouble(),
      zodiacSign: json['zodiac_sign'] as String,
    );
  }
}

@immutable
class AntarDasha {
  const AntarDasha({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.durationYears,
  });

  final String planet;
  final String startDate;
  final String endDate;
  final double durationYears;

  factory AntarDasha.fromJson(Map<String, dynamic> json) {
    return AntarDasha(
      planet: json['planet'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      durationYears: (json['duration_years'] as num).toDouble(),
    );
  }
}

@immutable
class MahaDasha {
  const MahaDasha({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.durationYears,
    required this.antarDashas,
  });

  final String planet;
  final String startDate;
  final String endDate;
  final double durationYears;
  final List<AntarDasha> antarDashas;

  factory MahaDasha.fromJson(Map<String, dynamic> json) {
    return MahaDasha(
      planet: json['planet'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      durationYears: (json['duration_years'] as num).toDouble(),
      antarDashas: (json['antar_dashas'] as List<dynamic>? ?? [])
          .map((e) => AntarDasha.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class VimshottariDasha {
  const VimshottariDasha({
    required this.birthNakshatra,
    required this.birthNakshatraLord,
    required this.mahaDashas,
  });

  final String birthNakshatra;
  final String birthNakshatraLord;
  final List<MahaDasha> mahaDashas;

  factory VimshottariDasha.fromJson(Map<String, dynamic> json) {
    return VimshottariDasha(
      birthNakshatra: json['birth_nakshatra'] as String,
      birthNakshatraLord: json['birth_nakshatra_lord'] as String,
      mahaDashas: (json['maha_dashas'] as List<dynamic>? ?? [])
          .map((e) => MahaDasha.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class BirthChartFacts {
  const BirthChartFacts({
    required this.chartId,
    required this.ayanamsa,
    required this.ascendant,
    required this.planets,
    required this.houseCusps,
    required this.vimshottariDasha,
  });

  final String chartId;
  final String ayanamsa;
  final Ascendant ascendant;
  final List<PlanetPlacement> planets;
  final List<double> houseCusps;
  final VimshottariDasha vimshottariDasha;

  factory BirthChartFacts.fromJson(String chartId, Map<String, dynamic> json) {
    return BirthChartFacts(
      chartId: chartId,
      ayanamsa: json['ayanamsa'] as String? ?? 'lahiri',
      ascendant: Ascendant.fromJson(json['ascendant'] as Map<String, dynamic>),
      planets: (json['planets'] as List<dynamic>)
          .map((e) => PlanetPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
      houseCusps: (json['house_cusps'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      vimshottariDasha: VimshottariDasha.fromJson(
          json['vimshottari_dasha'] as Map<String, dynamic>),
    );
  }

  /// Returns list of planets in the given house number (1-indexed).
  List<PlanetPlacement> planetsInHouse(int house) =>
      planets.where((p) => p.house == house).toList();
}
