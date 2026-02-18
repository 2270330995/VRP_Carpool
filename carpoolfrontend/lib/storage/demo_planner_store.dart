import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_carpool_models.dart';
import 'demo_state_store.dart';

class DemoPlannerStore extends ChangeNotifier {
  DemoPlannerStore._();

  static final DemoPlannerStore instance = DemoPlannerStore._();
  static const String _lastResponseKey = 'carpool_demo_last_response_v1';

  EventInput _event = EventInput();
  List<DriverInput> _drivers = [
    DriverInput(id: 'd1', name: 'Driver 1', seatCapacity: 4),
  ];
  List<StudentInput> _students = [StudentInput(id: 's1', name: 'Student 1')];
  String _globalStartTime = '';
  String _globalEndTime = '';
  List<OptimizeRoutePlan> _lastPlans = const [];

  bool _loaded = false;
  Timer? _persistDebounce;

  EventInput get event => _event;
  List<DriverInput> get drivers => _drivers;
  List<StudentInput> get students => _students;
  String get globalStartTime => _globalStartTime;
  String get globalEndTime => _globalEndTime;
  List<OptimizeRoutePlan> get lastPlans => _lastPlans;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final saved = await DemoStateStore.load();
    if (saved != null) {
      _event = saved.event;
      _drivers = saved.drivers.isNotEmpty
          ? saved.drivers
          : [DriverInput(id: 'd1', name: 'Driver 1', seatCapacity: 4)];
      _students = saved.students.isNotEmpty
          ? saved.students
          : [StudentInput(id: 's1', name: 'Student 1')];
      _globalStartTime = saved.globalStartTime ?? '';
      _globalEndTime = saved.globalEndTime ?? '';
    }
    _lastPlans = await _loadLastPlans();
    _loaded = true;
    notifyListeners();
  }

  void setEvent(EventInput event) {
    _event = event;
    _changed();
  }

  void setDrivers(List<DriverInput> drivers) {
    _drivers = drivers.isNotEmpty
        ? drivers
        : [DriverInput(id: 'd1', name: 'Driver 1', seatCapacity: 4)];
    _changed();
  }

  void setStudents(List<StudentInput> students) {
    _students = students.isNotEmpty
        ? students
        : [StudentInput(id: 's1', name: 'Student 1')];
    _changed();
  }

  void setGlobalTimes({String? start, String? end}) {
    if (start != null) _globalStartTime = start;
    if (end != null) _globalEndTime = end;
    _changed();
  }

  Future<void> setLastPlans(List<OptimizeRoutePlan> plans) async {
    _lastPlans = plans;
    await _saveLastPlans(plans);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _event = EventInput();
    _drivers = [DriverInput(id: 'd1', name: 'Driver 1', seatCapacity: 4)];
    _students = [StudentInput(id: 's1', name: 'Student 1')];
    _globalStartTime = '';
    _globalEndTime = '';
    _lastPlans = const [];
    await DemoStateStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastResponseKey);
    notifyListeners();
  }

  void touch() {
    _changed();
  }

  Future<void> reloadFromDisk() async {
    _loaded = false;
    await ensureLoaded();
  }

  void _changed() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), _persistNow);
    notifyListeners();
  }

  Future<void> _persistNow() async {
    final state = DemoPlanState(
      event: _event,
      drivers: _drivers,
      students: _students,
      globalStartTime: _globalStartTime.trim().isEmpty
          ? null
          : _globalStartTime,
      globalEndTime: _globalEndTime.trim().isEmpty ? null : _globalEndTime,
    );
    await DemoStateStore.save(state);
  }

  Future<List<OptimizeRoutePlan>> _loadLastPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(_lastResponseKey);
    if (blob == null || blob.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(blob);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => OptimizeRoutePlan.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveLastPlans(List<OptimizeRoutePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final blob = jsonEncode(plans.map((e) => e.toJson()).toList());
    await prefs.setString(_lastResponseKey, blob);
  }
}
