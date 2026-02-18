import 'dart:math';

import 'package:dio/dio.dart';

import '../models/place_selection.dart';

class PlacesService {
  PlacesService({String? backendBaseUrl})
    : _backendBaseUrl = backendBaseUrl ?? 'http://localhost:8080/api/places',
      _dio = Dio(
        BaseOptions(
          baseUrl: backendBaseUrl ?? 'http://localhost:8080/api/places',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

  final Dio _dio;
  final String _backendBaseUrl;

  bool get isConfigured => _backendBaseUrl.trim().isNotEmpty;

  String newSessionToken() => _uuidV4();

  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final res = await _dio.get(
      '/autocomplete',
      queryParameters: {
        'input': input,
        'sessionToken': sessionToken,
        'types': 'address',
        'components': 'country:us',
      },
    );

    final data = res.data as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN_ERROR';

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final err = data['error_message'] as String? ?? status;
      throw Exception('Autocomplete failed: $err');
    }

    return (data['predictions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => PlacePrediction(
            placeId: e['place_id'] as String? ?? '',
            description: e['description'] as String? ?? '',
          ),
        )
        .where((e) => e.placeId.isNotEmpty && e.description.isNotEmpty)
        .toList();
  }

  Future<PlaceSelection> placeDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final res = await _dio.get(
      '/details',
      queryParameters: {'placeId': placeId, 'sessionToken': sessionToken},
    );

    final data = res.data as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN_ERROR';

    if (status != 'OK') {
      final err = data['error_message'] as String? ?? status;
      throw Exception('Place details failed: $err');
    }

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw Exception('Place details missing result');
    }

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) {
      throw Exception('Place details missing location');
    }

    return PlaceSelection(
      placeId: result['place_id'] as String? ?? placeId,
      description: result['formatted_address'] as String? ?? '',
      location: LatLngPoint.fromJson(location),
    );
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int v) => v.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();

    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}
