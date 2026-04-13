import 'dart:convert';

import 'package:equatable/equatable.dart';

class VoiceOption extends Equatable {
  final String name;
  final String locale;
  final String identifier;
  final String gender;
  final int? quality;
  final int? latency;
  final bool networkRequired;

  const VoiceOption({
    required this.name,
    required this.locale,
    this.identifier = '',
    this.gender = '',
    this.quality,
    this.latency,
    this.networkRequired = false,
  });

  factory VoiceOption.fromMap(Map<dynamic, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    }

    return VoiceOption(
      name: map['name']?.toString().trim() ?? '',
      locale: map['locale']?.toString().trim() ?? '',
      identifier: map['identifier']?.toString().trim() ?? '',
      gender: map['gender']?.toString().trim() ?? '',
      quality: parseInt(map['quality']),
      latency: parseInt(map['latency']),
      networkRequired: parseBool(map['network_required']),
    );
  }

  factory VoiceOption.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice JSON');
    }

    return VoiceOption.fromMap(decoded);
  }

  String get normalizedLocale => locale.replaceAll('_', '-').toLowerCase();
  String get normalizedLanguageCode {
    final normalized = normalizedLocale;
    final separatorIndex = normalized.indexOf('-');
    if (separatorIndex == -1) {
      return normalized;
    }

    return normalized.substring(0, separatorIndex);
  }

  String get id => identifier.isNotEmpty ? identifier : '$locale::$name';

  String get displayLabel {
    final base = name.isNotEmpty ? name : 'System voice';
    if (locale.isNotEmpty) {
      return '$base ($locale)';
    }
    return base;
  }

  bool supportsLanguage(String languageCode) {
    final normalizedLanguage = languageCode.toLowerCase();
    return normalizedLocale == normalizedLanguage ||
        normalizedLocale.startsWith('$normalizedLanguage-');
  }

  Map<String, String> toTtsPayload() {
    final payload = <String, String>{};
    if (identifier.isNotEmpty) {
      payload['identifier'] = identifier;
    }
    if (name.isNotEmpty) {
      payload['name'] = name;
    }
    if (locale.isNotEmpty) {
      payload['locale'] = locale;
    }
    return payload;
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'name': name,
      'locale': locale,
      'identifier': identifier,
      'gender': gender,
      'quality': quality,
      'latency': latency,
      'network_required': networkRequired,
    };
  }

  String toJsonString() => jsonEncode(toJsonMap());

  @override
  List<Object?> get props => [
    name,
    locale,
    identifier,
    gender,
    quality,
    latency,
    networkRequired,
  ];
}
