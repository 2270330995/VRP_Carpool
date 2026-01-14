import 'package:dio/dio.dart';
import '../models/destination.dart';
import '../models/driver.dart';
import '../models/passenger.dart';

class ApiService {
  ApiService({String baseUrl = 'http://localhost:8080'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );

  final Dio _dio;

  // ---------- Destinations ----------
  Future<List<Destination>> getDestinations({bool includeInactive = false}) async {
    final res = await _dio.get(
      '/api/destinations',
      queryParameters: {
        if (includeInactive) 'includeInactive': true,
      },
    );
    return (res.data as List).map((e) => Destination.fromJson(e)).toList();
  }

  Future<void> addDestination(Destination destination) async {
    await _dio.post('/api/destinations', data: destination.toJson());
  }

  Future<void> restoreDestination(String id) async {
    await _dio.patch('/api/destinations/$id/restore');
  }

  // ---------- Drivers ----------
  Future<List<Driver>> getDrivers({bool includeInactive = false}) async {
    final res = await _dio.get(
      '/api/drivers',
      queryParameters: {
        if (includeInactive) 'includeInactive': true,
      },
    );
    return (res.data as List).map((e) => Driver.fromJson(e)).toList();
  }

  Future<void> addDriver(Driver driver) async {
    await _dio.post('/api/drivers', data: driver.toJson());
  }

  // ---------- Passengers ----------
  Future<List<Passenger>> getPassengers({bool includeInactive = false}) async {
    final res = await _dio.get(
      '/api/passengers',
      queryParameters: {
        if (includeInactive) 'includeInactive': true,
      },
    );
    return (res.data as List).map((e) => Passenger.fromJson(e)).toList();
  }

  Future<void> addPassenger(Passenger passenger) async {
    await _dio.post('/api/passengers', data: passenger.toJson());
  }

  // ---------- Assign ----------
  Future<void> assign({
    required int destinationId,
    String? note,
    List<String>? driverIds,
    List<String>? passengerIds,
  }) async {
    await _dio.post(
      '/api/assign',
      queryParameters: {
        'destinationId': destinationId,
        if (note != null && note.trim().isNotEmpty) 'note': note,
        if (driverIds != null && driverIds.isNotEmpty) 'driverIds': driverIds,
        if (passengerIds != null && passengerIds.isNotEmpty)
          'passengerIds': passengerIds,
      },
    );
  }

  Future<void> deleteDriver(String id) async {
    await _dio.delete('/api/drivers/$id');
  }

  Future<void> restoreDriver(String id) async {
    await _dio.patch('/api/drivers/$id/restore');
  }

  Future<void> deletePassenger(String id) async {
    await _dio.delete('/api/passengers/$id');
  }

  Future<void> restorePassenger(String id) async {
    await _dio.patch('/api/passengers/$id/restore');
  }

  Future<void> deleteDestination(String id) async {
    await _dio.delete('/api/destinations/$id');
  }

  Future<Map<String, dynamic>> getLatestRun({
    List<String>? passengerIds,
  }) async {
    final res = await _dio.get(
      '/api/assign/runs/latest',
      queryParameters: {
        if (passengerIds != null && passengerIds.isNotEmpty)
          'passengerIds': passengerIds,
      },
    );
    return res.data;
  }

  Future<String> getNavigateUrl({
    required int runId,
    required int driverId,
  }) async {
    final res = await _dio.get(
      '/api/assign/runs/$runId/drivers/$driverId/navigate',
    );
    return res.data['url'];
  }
}
