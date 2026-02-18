import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan_carpool_models.dart';

class DemoPlanState {
  DemoPlanState({
    required this.event,
    required this.drivers,
    required this.students,
    this.globalStartTime,
    this.globalEndTime,
  });

  final EventInput event;
  final List<DriverInput> drivers;
  final List<StudentInput> students;
  final String? globalStartTime;
  final String? globalEndTime;

  factory DemoPlanState.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'];
    final driversJson = json['drivers'];
    final studentsJson = json['students'];

    return DemoPlanState(
      event: eventJson is Map<String, dynamic>
          ? EventInput.fromJson(eventJson)
          : EventInput(),
      drivers: driversJson is List
          ? driversJson
                .whereType<Map>()
                .map((e) => DriverInput.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <DriverInput>[],
      students: studentsJson is List
          ? studentsJson
                .whereType<Map>()
                .map((e) => StudentInput.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const <StudentInput>[],
      globalStartTime:
          (json['globalStartTime'] as String?)?.trim().isNotEmpty == true
          ? json['globalStartTime'] as String
          : null,
      globalEndTime:
          (json['globalEndTime'] as String?)?.trim().isNotEmpty == true
          ? json['globalEndTime'] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'event': event.toJson(),
    'drivers': drivers.map((e) => e.toJson()).toList(),
    'students': students.map((e) => e.toJson()).toList(),
    'globalStartTime': globalStartTime,
    'globalEndTime': globalEndTime,
  };
}

class DemoStateStore {
  static const String storageKey = 'carpool_demo_state_v1';
  static const String draftsKey = 'carpool_demo_drafts_v1';

  static const String defaultDraftName = 'Last Draft';

  static String _normalizeDraftName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? defaultDraftName : trimmed;
  }

  static Future<List<Map<String, dynamic>>> _readRawDraftEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(draftsKey);
    if (blob == null || blob.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(blob);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('[DemoStateStore] key=$draftsKey parse failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _writeRawDraftEntries(
    List<Map<String, dynamic>> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(draftsKey, jsonEncode(entries));
  }

  static Future<void> save(DemoPlanState state) async {
    await saveNamedDraft(defaultDraftName, state);
  }

  static Future<void> saveNamedDraft(String name, DemoPlanState state) async {
    final draftName = _normalizeDraftName(name);
    try {
      final prefs = await SharedPreferences.getInstance();
      final blob = jsonEncode(state.toJson());
      await prefs.setString(storageKey, blob);
      debugPrint('[DemoStateStore] key=$storageKey saved bytes=${blob.length}');

      final entries = await _readRawDraftEntries();
      entries.removeWhere((e) => (e['name'] as String?) == draftName);
      entries.add({
        'name': draftName,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'state': state.toJson(),
      });
      await _writeRawDraftEntries(entries);
      debugPrint('[DemoStateStore] key=$draftsKey saved draft="$draftName"');
    } catch (e) {
      debugPrint('[DemoStateStore] key=$storageKey save failed: $e');
    }
  }

  static Future<DemoPlanState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(storageKey);
    if (blob != null) {
      debugPrint('[DemoStateStore] key=$storageKey found bytes=${blob.length}');
    } else {
      debugPrint('[DemoStateStore] key=$storageKey not found');
    }
    if (blob == null || blob.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(blob);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return DemoPlanState.fromJson(decoded);
    } catch (e) {
      debugPrint('[DemoStateStore] key=$storageKey parse failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  static Future<List<DemoDraftMeta>> listDrafts() async {
    final entries = await _readRawDraftEntries();
    final drafts = entries
        .map((e) => DemoDraftMeta.fromJson(e))
        .where((e) => e.name.trim().isNotEmpty)
        .toList();
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  static Future<DemoPlanState?> loadNamedDraft(String name) async {
    final draftName = _normalizeDraftName(name);
    final entries = await _readRawDraftEntries();
    final match = entries.cast<Map<String, dynamic>?>().firstWhere(
      (e) => e != null && (e['name'] as String?) == draftName,
      orElse: () => null,
    );
    if (match == null) return null;
    final rawState = match['state'];
    if (rawState is! Map<String, dynamic>) return null;
    try {
      final state = DemoPlanState.fromJson(rawState);
      await save(state);
      return state;
    } catch (e) {
      debugPrint(
        '[DemoStateStore] key=$draftsKey draft="$draftName" parse failed: $e',
      );
      return null;
    }
  }

  static Future<void> deleteNamedDraft(String name) async {
    final draftName = _normalizeDraftName(name);
    final entries = await _readRawDraftEntries();
    entries.removeWhere((e) => (e['name'] as String?) == draftName);
    await _writeRawDraftEntries(entries);
    debugPrint('[DemoStateStore] key=$draftsKey deleted draft="$draftName"');
  }
}

class DemoDraftMeta {
  DemoDraftMeta({required this.name, required this.updatedAt});

  final String name;
  final DateTime updatedAt;

  factory DemoDraftMeta.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['updatedAt'] ?? '').toString();
    final parsedDate =
        DateTime.tryParse(rawDate)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return DemoDraftMeta(
      name: (json['name'] ?? '').toString(),
      updatedAt: parsedDate,
    );
  }
}
