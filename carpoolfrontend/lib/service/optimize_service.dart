import 'package:dio/dio.dart';

import '../models/plan_carpool_models.dart';

class OptimizeService {
  OptimizeService({String baseUrl = 'http://localhost:8080/api'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

  final Dio _dio;

  Future<List<OptimizeRoutePlan>> optimize({
    required EventInput event,
    required List<DriverInput> drivers,
    required List<StudentInput> students,
    String? globalStartTime,
    String? globalEndTime,
  }) async {
    final body = {
      'event': {'location': event.place!.location.toJson()},
      'drivers': drivers
          .map(
            (d) => {
              'id': d.id,
              'home': d.home!.location.toJson(),
              'seatCapacity': d.seatCapacity,
            },
          )
          .toList(),
      'students': students
          .map((s) => {'id': s.id, 'home': s.home!.location.toJson()})
          .toList(),
      if (globalStartTime != null && globalStartTime.trim().isNotEmpty)
        'globalStartTime': globalStartTime,
      if (globalEndTime != null && globalEndTime.trim().isNotEmpty)
        'globalEndTime': globalEndTime,
    };

    try {
      final res = await _dio.post('/optimize', data: body);
      final list = (res.data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OptimizeRoutePlan.fromJson)
          .toList();

      return list;
    } on DioException catch (e) {
      final request = e.requestOptions;
      final method = request.method;
      final url = request.uri.toString();
      final statusCode = e.response?.statusCode;
      final responseBody = e.response?.data;
      throw Exception(
        'Optimize request failed: method=$method url=$url '
        'statusCode=${statusCode ?? 'N/A'} responseBody=${responseBody ?? 'N/A'}',
      );
    }
  }
}
