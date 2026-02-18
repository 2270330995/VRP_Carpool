import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place_selection.dart';
import '../models/plan_carpool_models.dart';
import '../service/optimize_service.dart';
import '../service/places_service.dart';
import '../storage/demo_planner_store.dart';
import '../storage/demo_state_store.dart';

class PlanCarpoolPage extends StatefulWidget {
  const PlanCarpoolPage({super.key});

  @override
  State<PlanCarpoolPage> createState() => _PlanCarpoolPageState();
}

class _PlanCarpoolPageState extends State<PlanCarpoolPage> {
  final PlacesService _placesService = PlacesService();
  final OptimizeService _optimizeService = OptimizeService();
  final DemoPlannerStore _store = DemoPlannerStore.instance;

  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  bool _optimizing = false;
  String _activeDraftName = DemoStateStore.defaultDraftName;

  EventInput get _event => _store.event;
  List<DriverInput> get _drivers => _store.drivers;
  List<StudentInput> get _students => _store.students;
  List<OptimizeRoutePlan> get _plans => _store.lastPlans;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();
    _store.addListener(_onStoreChanged);
    Future.microtask(() async {
      await _store.ensureLoaded();
      if (!mounted) return;
      final defaults = _buildDefaultTimes();
      _startCtrl.text = _store.globalStartTime.isNotEmpty
          ? _toDisplayTime(_store.globalStartTime)
          : defaults.$1;
      _endCtrl.text = _store.globalEndTime.isNotEmpty
          ? _toDisplayTime(_store.globalEndTime)
          : defaults.$2;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _selectEventAddress() async {
    final selected = await _openPlacePicker(title: 'Select Event Address');
    if (selected == null) return;
    _event.place = selected;
    _store.touch();
  }

  Future<void> _selectDriverHome(int index) async {
    final selected = await _openPlacePicker(
      title: 'Select Driver Home',
      initialText: _drivers[index].home?.description,
    );
    if (selected == null) return;
    _drivers[index].home = selected;
    _store.touch();
  }

  Future<void> _selectStudentHome(int index) async {
    final selected = await _openPlacePicker(
      title: 'Select Passenger Home',
      initialText: _students[index].home?.description,
    );
    if (selected == null) return;
    _students[index].home = selected;
    _store.touch();
  }

  Future<PlaceSelection?> _openPlacePicker({
    required String title,
    String? initialText,
  }) async {
    return showDialog<PlaceSelection>(
      context: context,
      builder: (_) => _PlaceAutocompleteDialog(
        title: title,
        placesService: _placesService,
        initialText: initialText,
      ),
    );
  }

  void _addDriver() {
    final idx = _drivers.length + 1;
    _drivers.add(
      DriverInput(id: 'd$idx', name: 'Driver $idx', seatCapacity: 4),
    );
    _store.touch();
  }

  void _addStudent() {
    final idx = _students.length + 1;
    _students.add(StudentInput(id: 's$idx', name: 'Passenger $idx'));
    _store.touch();
  }

  void _removeDriver(int index) {
    _drivers.removeAt(index);
    _store.touch();
  }

  void _removeStudent(int index) {
    _students.removeAt(index);
    _store.touch();
  }

  Future<void> _optimize() async {
    if (_optimizing) return;

    final validationError = _validateInput();
    if (validationError != null) {
      _showSnackBar(validationError);
      return;
    }

    setState(() => _optimizing = true);
    try {
      final plans = await _optimizeService.optimize(
        event: _event,
        drivers: _drivers,
        students: _students,
        globalStartTime: _toUtcIsoTime(_startCtrl.text.trim()),
        globalEndTime: _toUtcIsoTime(_endCtrl.text.trim()),
      );

      if (!mounted) return;
      _store.setGlobalTimes(
        start: _toUtcIsoTime(_startCtrl.text.trim()) ?? '',
        end: _toUtcIsoTime(_endCtrl.text.trim()) ?? '',
      );
      await _store.setLastPlans(plans);
      if (_plans.isEmpty) {
        _showSnackBar('No route plans returned.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Optimize failed: $e');
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  (String, String) _buildDefaultTimes() {
    final now = DateTime.now();
    return (
      _formatDisplay(now),
      _formatDisplay(now.add(const Duration(hours: 6))),
    );
  }

  Future<void> _loadLastState({bool showNoDataMessage = true}) async {
    final state = await DemoStateStore.load();
    if (!mounted) return;
    if (state == null) {
      if (showNoDataMessage) {
        _showSnackBar('No saved plan found.');
      }
      return;
    }

    _store.setEvent(state.event);
    _store.setDrivers(state.drivers);
    _store.setStudents(state.students);
    _store.setGlobalTimes(
      start: state.globalStartTime ?? '',
      end: state.globalEndTime ?? '',
    );
    _activeDraftName = DemoStateStore.defaultDraftName;

    _startCtrl.text = (state.globalStartTime ?? '').isNotEmpty
        ? _toDisplayTime(state.globalStartTime!)
        : _buildDefaultTimes().$1;
    _endCtrl.text = (state.globalEndTime ?? '').isNotEmpty
        ? _toDisplayTime(state.globalEndTime!)
        : _buildDefaultTimes().$2;
    setState(() {});
    _showSnackBar('Loaded last plan');
  }

  Future<void> _saveState() async {
    final nameCtrl = TextEditingController(text: _activeDraftName);
    final selectedName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Draft'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Draft name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || selectedName == null) return;
    final draftName = selectedName.trim().isEmpty
        ? DemoStateStore.defaultDraftName
        : selectedName.trim();

    final snapshot = DemoPlanState(
      event: _event,
      drivers: List<DriverInput>.from(_drivers),
      students: List<StudentInput>.from(_students),
      globalStartTime: _startCtrl.text.trim().isEmpty
          ? null
          : _toUtcIsoTime(_startCtrl.text.trim()),
      globalEndTime: _endCtrl.text.trim().isEmpty
          ? null
          : _toUtcIsoTime(_endCtrl.text.trim()),
    );
    await DemoStateStore.saveNamedDraft(draftName, snapshot);
    _activeDraftName = draftName;
    _store.setGlobalTimes(
      start: snapshot.globalStartTime ?? '',
      end: snapshot.globalEndTime ?? '',
    );
    if (!mounted) return;
    _showSnackBar('Saved (draft)');
  }

  Future<void> _clearState() async {
    await _store.clearAll();
    if (!mounted) return;
    final defaults = _buildDefaultTimes();
    _startCtrl.text = defaults.$1;
    _endCtrl.text = defaults.$2;
    _activeDraftName = DemoStateStore.defaultDraftName;
    _showSnackBar('Cleared');
  }

  Future<void> _openDraftsDialog() async {
    final drafts = await DemoStateStore.listDrafts();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Saved Drafts'),
        content: SizedBox(
          width: 560,
          child: drafts.isEmpty
              ? const Text('No saved drafts.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  itemBuilder: (_, index) {
                    final draft = drafts[index];
                    return ListTile(
                      title: Text(draft.name),
                      subtitle: Text(draft.updatedAt.toLocal().toString()),
                      onTap: () async {
                        final loaded = await DemoStateStore.loadNamedDraft(
                          draft.name,
                        );
                        if (!mounted || loaded == null) return;
                        _store.setEvent(loaded.event);
                        _store.setDrivers(loaded.drivers);
                        _store.setStudents(loaded.students);
                        _store.setGlobalTimes(
                          start: loaded.globalStartTime ?? '',
                          end: loaded.globalEndTime ?? '',
                        );
                        _startCtrl.text =
                            loaded.globalStartTime?.isNotEmpty == true
                            ? _toDisplayTime(loaded.globalStartTime!)
                            : _buildDefaultTimes().$1;
                        _endCtrl.text = loaded.globalEndTime?.isNotEmpty == true
                            ? _toDisplayTime(loaded.globalEndTime!)
                            : _buildDefaultTimes().$2;
                        _activeDraftName = draft.name;
                        if (!mounted || !dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _showSnackBar("Loaded '${draft.name}'");
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await DemoStateStore.deleteNamedDraft(draft.name);
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _showSnackBar('Draft deleted');
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String? _validateInput() {
    if (_event.place == null) return 'Please select event address.';
    if (_drivers.isEmpty) return 'Please add at least one driver.';
    if (_students.isEmpty) return 'Please add at least one passenger.';

    for (int i = 0; i < _drivers.length; i++) {
      final d = _drivers[i];
      if (d.id.trim().isEmpty) return 'Driver ${i + 1}: id is required.';
      if (d.seatCapacity <= 0) {
        return 'Driver ${i + 1}: seat capacity must be > 0.';
      }
      if (d.home == null) return 'Driver ${i + 1}: home address is required.';
    }

    for (int i = 0; i < _students.length; i++) {
      final s = _students[i];
      if (s.id.trim().isEmpty) return 'Passenger ${i + 1}: id is required.';
      if (s.home == null) {
        return 'Passenger ${i + 1}: home address is required.';
      }
    }

    return null;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatDisplay(DateTime local) {
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  DateTime? _parseDisplayOrIso(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final isoParsed = DateTime.tryParse(text);
    if (isoParsed != null) {
      return isoParsed.isUtc ? isoParsed.toLocal() : isoParsed;
    }

    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(text);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6) ?? '0'),
    );
  }

  String _toDisplayTime(String raw) {
    final parsed = _parseDisplayOrIso(raw);
    return parsed == null ? raw : _formatDisplay(parsed);
  }

  String? _toUtcIsoTime(String raw) {
    final parsed = _parseDisplayOrIso(raw);
    if (parsed == null) return null;
    return parsed.toUtc().toIso8601String();
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final base = _parseDisplayOrIso(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final merged = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => controller.text = _formatDisplay(merged));
  }

  List<StudentInput> _unassignedStudents() {
    final assignedIds = <String>{};
    for (final plan in _plans) {
      for (final entry in plan.timeline) {
        if (entry.type == 'pickup' &&
            (entry.studentId ?? '').trim().isNotEmpty) {
          assignedIds.add(entry.studentId!.trim());
        }
      }
    }

    return _students
        .where((s) => !assignedIds.contains(s.id.trim()))
        .toList(growable: false);
  }

  Future<void> _openInGoogleMaps(OptimizeRoutePlan plan) async {
    final origin = plan.driverHome;
    final destination = plan.eventLocation;
    if (origin == null || destination == null) {
      _showSnackBar('Missing driver home or event location in route plan.');
      return;
    }

    final waypoints = plan.timeline
        .where((e) => e.type == 'pickup' && e.location != null)
        .map((e) => e.location!.toCommaPair())
        .toList();

    final uri = Uri.parse('https://www.google.com/maps/dir/').replace(
      queryParameters: {
        'api': '1',
        'origin': origin.toCommaPair(),
        'destination': destination.toCommaPair(),
        'travelmode': 'driving',
        if (waypoints.isNotEmpty) 'waypoints': waypoints.join('|'),
      },
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showSnackBar('Could not open Google Maps.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Carpool')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _loadLastState(),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Load Last'),
              ),
              OutlinedButton.icon(
                onPressed: _saveState,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
              OutlinedButton.icon(
                onPressed: _clearState,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
              OutlinedButton.icon(
                onPressed: _openDraftsDialog,
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Drafts'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EventCard(event: _event, onSelect: _selectEventAddress),
          const SizedBox(height: 12),
          _buildGlobalTimeCard(),
          const SizedBox(height: 12),
          _buildDriversCard(),
          const SizedBox(height: 12),
          _buildStudentsCard(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _optimizing ? null : _optimize,
            icon: _optimizing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route),
            label: Text(_optimizing ? 'Optimizing...' : 'Optimize'),
          ),
          const SizedBox(height: 16),
          if (_plans.isNotEmpty)
            ..._plans.map(
              (p) => _RoutePlanCard(
                plan: p,
                onOpenMap: () => _openInGoogleMaps(p),
              ),
            ),
          if (_plans.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildUnassignedSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassignedSection() {
    final unassigned = _unassignedStudents();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unassigned Passengers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (unassigned.isEmpty)
              const Text('None')
            else
              ...unassigned.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name.isNotEmpty ? s.name : s.id),
                  subtitle: Text(s.home?.description ?? 'Address not selected'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Time Window (optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _startCtrl,
              readOnly: true,
              onTap: () => _pickDateTime(_startCtrl),
              decoration: const InputDecoration(
                labelText: 'Start Time (local)',
                suffixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endCtrl,
              readOnly: true,
              onTap: () => _pickDateTime(_endCtrl),
              decoration: const InputDecoration(
                labelText: 'End Time (local)',
                suffixIcon: Icon(Icons.schedule),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Drivers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addDriver,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _drivers.length; i++)
              _DriverEditor(
                key: ValueKey('driver_$i'),
                driver: _drivers[i],
                onChanged: _store.touch,
                onSelectAddress: () => _selectDriverHome(i),
                onRemove: _drivers.length > 1 ? () => _removeDriver(i) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Passengers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _students.length; i++)
              _StudentEditor(
                key: ValueKey('student_$i'),
                student: _students[i],
                onChanged: _store.touch,
                onSelectAddress: () => _selectStudentHome(i),
                onRemove: _students.length > 1 ? () => _removeStudent(i) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onSelect});

  final EventInput event;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Event Address'),
        subtitle: Text(event.place?.description ?? 'Not selected'),
        trailing: OutlinedButton(
          onPressed: onSelect,
          child: const Text('Select'),
        ),
      ),
    );
  }
}

class _DriverEditor extends StatelessWidget {
  const _DriverEditor({
    super.key,
    required this.driver,
    required this.onChanged,
    required this.onSelectAddress,
    required this.onRemove,
  });

  final DriverInput driver;
  final VoidCallback onChanged;
  final VoidCallback onSelectAddress;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: driver.id,
                    decoration: const InputDecoration(labelText: 'Driver ID'),
                    onChanged: (v) {
                      driver.id = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: driver.name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (v) {
                      driver.name = v;
                      onChanged();
                    },
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: driver.seatCapacity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seat Capacity',
                    ),
                    onChanged: (v) {
                      driver.seatCapacity = int.tryParse(v) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Home'),
                    subtitle: Text(driver.home?.description ?? 'Not selected'),
                    trailing: OutlinedButton(
                      onPressed: onSelectAddress,
                      child: const Text('Pick'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentEditor extends StatelessWidget {
  const _StudentEditor({
    super.key,
    required this.student,
    required this.onChanged,
    required this.onSelectAddress,
    required this.onRemove,
  });

  final StudentInput student;
  final VoidCallback onChanged;
  final VoidCallback onSelectAddress;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: student.id,
                    decoration: const InputDecoration(
                      labelText: 'Passenger ID',
                    ),
                    onChanged: (v) {
                      student.id = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: student.name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (v) {
                      student.name = v;
                      onChanged();
                    },
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Home'),
              subtitle: Text(student.home?.description ?? 'Not selected'),
              trailing: OutlinedButton(
                onPressed: onSelectAddress,
                child: const Text('Pick'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePlanCard extends StatelessWidget {
  const _RoutePlanCard({required this.plan, required this.onOpenMap});

  final OptimizeRoutePlan plan;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Driver: ${plan.driverId ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Google Maps'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan.timeline.isEmpty)
              const Text('No timeline entries')
            else
              ...plan.timeline.map(
                (t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${t.sequence}. ${t.type ?? 'visit'} • passenger ${t.studentId ?? '-'}',
                  ),
                  subtitle: Text(
                    '${t.time ?? '-'}\n'
                    'loc: ${t.location?.lat ?? '-'}, ${t.location?.lng ?? '-'}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceAutocompleteDialog extends StatefulWidget {
  const _PlaceAutocompleteDialog({
    required this.title,
    required this.placesService,
    this.initialText,
  });

  final String title;
  final PlacesService placesService;
  final String? initialText;

  @override
  State<_PlaceAutocompleteDialog> createState() =>
      _PlaceAutocompleteDialogState();
}

class _PlaceAutocompleteDialogState extends State<_PlaceAutocompleteDialog> {
  late final TextEditingController _queryCtrl;
  late String _sessionToken;

  Timer? _debounce;
  bool _loading = false;
  List<PlacePrediction> _predictions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialText ?? '');
    _sessionToken = widget.placesService.newSessionToken();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _predictions = const [];
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final items = await widget.placesService.autocomplete(
          input: value.trim(),
          sessionToken: _sessionToken,
        );
        if (!mounted) return;
        setState(() => _predictions = items);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _pickPrediction(PlacePrediction p) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final place = await widget.placesService.placeDetails(
        placeId: p.placeId,
        sessionToken: _sessionToken,
      );
      _sessionToken = widget.placesService.newSessionToken();
      if (!mounted) return;
      Navigator.pop(context, place);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _queryCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search address',
                hintText: 'Start typing...',
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: _predictions.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No suggestions yet.'),
                    )
                  : ListView.builder(
                      itemCount: _predictions.length,
                      itemBuilder: (_, i) {
                        final p = _predictions[i];
                        return ListTile(
                          title: Text(p.description),
                          onTap: () => _pickPrediction(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
