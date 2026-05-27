import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/schedule_provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _dayLabels = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
];

const _dayKeywords = <String, int>{
  'saturday': 6, 'sutrday': 6, 'satur': 6,
  'sunday': 0,
  'monday': 1,
  'tuesday': 2,
  'wednesday': 3,
  'thursday': 4,
};

// Blocks containing these patterns are header/footer noise, not timetable cells
final _noiseRx = RegExp(
  r'timetable|teacher|generated|eng\.|mo\d{4}',
  caseSensitive: false,
);
final _dateRx = RegExp(r'\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}');

// Course codes look like "AI 304" or "CS101" — 2+ letters followed by 2+ digits
final _courseCodeRx = RegExp(r'^[A-Za-z]{2,}\s*\d{2,}');

// ── Screen ────────────────────────────────────────────────────────────────────

class ScheduleOcrImportScreen extends ConsumerStatefulWidget {
  const ScheduleOcrImportScreen({super.key});

  @override
  ConsumerState<ScheduleOcrImportScreen> createState() =>
      _ScheduleOcrImportScreenState();
}

class _ScheduleOcrImportScreenState
    extends ConsumerState<ScheduleOcrImportScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  bool _processing = false;
  String? _error;
  List<_ParsedEntry>? _entries;
  File? _imageFile;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (xFile == null) return;
      setState(() {
        _processing = true;
        _error = null;
        _entries = null;
        _imageFile = File(xFile.path);
      });
      await _process(xFile.path);
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Could not open image: $e';
      });
    }
  }

  Future<void> _process(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await _recognizer.processImage(inputImage);
      final entries = _parse(recognized);
      setState(() {
        _processing = false;
        _entries = entries;
        if (entries.isEmpty) {
          _error =
              'No timetable entries detected. Make sure the photo is well-lit, '
              'held straight, and the full grid is visible.';
        }
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'OCR error: $e';
      });
    }
  }

  // ── Parser ──────────────────────────────────────────────────────────────────

  List<_ParsedEntry> _parse(RecognizedText recognized) {
    final timeRx = RegExp(r'(\d{1,2})[.:](\d{2})');
    final dayRows = <int, double>{};   // dayOfWeek → midY of day label block
    final timeCols = <_TR, double>{}; // time range → midX of header block
    final rawContent = <_CB>[];       // non-classified text blocks

    for (final block in recognized.blocks) {
      final box = block.boundingBox;
      final raw = block.text.trim();
      if (raw.isEmpty) continue;

      final lower = raw.toLowerCase();

      // Discard header/footer noise and date strings
      if (_noiseRx.hasMatch(lower) || _dateRx.hasMatch(raw)) continue;

      final midX = (box.left + box.right) / 2;
      final midY = (box.top + box.bottom) / 2;

      // Day name?
      int? dow;
      for (final kv in _dayKeywords.entries) {
        if (lower.contains(kv.key)) { dow = kv.value; break; }
      }
      if (dow != null) { dayRows[dow] = midY; continue; }

      // Time header: block contains ≥2 time tokens → classify as column header.
      // The timetable shows two header rows (12h display + 24h).  We keep only
      // valid 24h ranges where start hour ≥ 7 and end > start.
      final ts = timeRx.allMatches(raw).toList();
      if (ts.length >= 2) {
        for (int i = 0; i < ts.length - 1; i++) {
          final sh = int.parse(ts[i].group(1)!);
          final sm = int.parse(ts[i].group(2)!);
          final eh = int.parse(ts[i + 1].group(1)!);
          final em = int.parse(ts[i + 1].group(2)!);
          // Skip 12h PM artifacts (e.g. "12:30 - 1:30" where end wraps to AM)
          // and unlikely early-morning slots
          if (sh < 7) continue;
          if (eh < sh || (eh == sh && em <= sm)) continue;
          timeCols.putIfAbsent(_TR(_t(sh, sm), _t(eh, em)), () => midX);
          break;
        }
        continue;
      }

      if (raw.length < 2) continue;
      rawContent.add(_CB(midX, midY, raw));
    }

    if (dayRows.isEmpty || timeCols.isEmpty) return [];

    // ── Cell grouping ───────────────────────────────────────────────────────
    // Map every content block to its (day, time-column) cell by nearest midY /
    // midX.  Blocks that are too far from any day row (noise / stray text) are
    // dropped.  All blocks that fall in the same cell are collected together.

    final cells = <String, List<_CB>>{};

    for (final cb in rawContent) {
      int? bestDow;
      double minYDist = double.infinity;
      for (final r in dayRows.entries) {
        final d = (r.value - cb.midY).abs();
        if (d < minYDist) { minYDist = d; bestDow = r.key; }
      }

      _TR? bestTR;
      double minXDist = double.infinity;
      for (final c in timeCols.entries) {
        final d = (c.value - cb.midX).abs();
        if (d < minXDist) { minXDist = d; bestTR = c.key; }
      }

      // Drop blocks with no clear row assignment (header/footer remnants)
      if (bestDow == null || bestTR == null || minYDist > 250) continue;

      final cellKey = '${bestDow}_${bestTR.start}';
      cells.putIfAbsent(cellKey, () => []).add(cb);
    }

    // ── Build entries ───────────────────────────────────────────────────────
    // Within each cell, sort blocks top-to-bottom: line 0 = course code,
    // line 1 = group, line 2 = room.  Cells whose top block is not a course
    // code (e.g. stray room labels) are discarded.

    final result = <_ParsedEntry>[];

    for (final kv in cells.entries) {
      // Key format: "${dow}_${startTime}" e.g. "6_08:30:00"
      final sepIdx = kv.key.indexOf('_');
      final dow = int.parse(kv.key.substring(0, sepIdx));
      final startTime = kv.key.substring(sepIdx + 1);

      _TR? tr;
      for (final t in timeCols.keys) {
        if (t.start == startTime) { tr = t; break; }
      }
      if (tr == null) continue;

      // Sort blocks within cell by vertical position
      final blocks = kv.value..sort((a, b) => a.midY.compareTo(b.midY));

      final courseCode = blocks[0].text;
      // Must look like a course code; single-letter room codes (e.g. "F 507")
      // or group tokens (e.g. "C 7 - AI") fail this check and are skipped
      if (!_courseCodeRx.hasMatch(courseCode)) continue;

      result.add(_ParsedEntry(
        dayOfWeek: dow,
        startTime: tr.start,
        endTime: tr.end,
        courseCode: courseCode,
        group: blocks.length > 1 ? blocks[1].text : null,
        room: blocks.length > 2 ? blocks[2].text : null,
      ));
    }

    result.sort((a, b) {
      final dc = a.dayOfWeek.compareTo(b.dayOfWeek);
      return dc != 0 ? dc : a.startTime.compareTo(b.startTime);
    });
    return result;
  }

  String _t(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final toSave = _entries!.where((e) => e.selected).toList();
    if (toSave.isEmpty) return;

    setState(() => _processing = true);
    final notifier = ref.read(scheduleProvider.notifier);
    int saved = 0;
    for (final e in toSave) {
      final ok = await notifier.addEntry(
        dayOfWeek: e.dayOfWeek,
        startTime: e.startTime,
        endTime: e.endTime,
        entryType: ScheduleEntryType.lecture,
        title: e.courseCode,
        groupName: e.group?.isNotEmpty == true ? e.group : null,
        location: e.room?.isNotEmpty == true ? e.room : null,
      );
      if (ok) saved++;
    }
    setState(() => _processing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('$saved ${saved == 1 ? 'entry' : 'entries'} added to schedule'),
      ));
      context.pop();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import from Photo')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              Gap(16),
              Text('Reading timetable…'),
            ],
          ),
        ),
      );
    }

    if (_entries != null) {
      return _ReviewScreen(
        imageFile: _imageFile,
        entries: _entries!,
        error: _error,
        onToggle: (i) =>
            setState(() => _entries![i].selected = !_entries![i].selected),
        onSave: _save,
        onRetry: () => setState(() {
          _entries = null;
          _error = null;
          _imageFile = null;
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import from Photo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_outlined,
                  size: 72, color: AppColors.primary),
              const Gap(20),
              const Text('Import Timetable',
                  style: AppTextStyles.headlineLarge),
              const Gap(8),
              Text(
                'Take a photo of your printed timetable or pick one from your gallery. '
                'Hold the camera straight and make sure the full grid is visible.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              ElevatedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
              ),
              const Gap(12),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a Photo'),
              ),
              if (_error != null) ...[
                const Gap(24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Review screen ─────────────────────────────────────────────────────────────

class _ReviewScreen extends StatelessWidget {
  const _ReviewScreen({
    required this.imageFile,
    required this.entries,
    required this.error,
    required this.onToggle,
    required this.onSave,
    required this.onRetry,
  });

  final File? imageFile;
  final List<_ParsedEntry> entries;
  final String? error;
  final void Function(int) onToggle;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final selected = entries.where((e) => e.selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Entries'),
        actions: [
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
      body: Column(
        children: [
          if (imageFile != null)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.file(imageFile!, fit: BoxFit.cover),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
            ),
          if (entries.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_outlined,
                        size: 56, color: AppColors.textHint),
                    const Gap(12),
                    const Text('No entries detected',
                        style: AppTextStyles.headlineMedium),
                    const Gap(8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Try a clearer, well-lit photo with the timetable fully visible.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Gap(24),
                    ElevatedButton(
                        onPressed: onRetry, child: const Text('Try Again')),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Row(
                children: [
                  Text(
                    '${entries.length} entries detected',
                    style: AppTextStyles.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    '$selected selected',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: entries.length,
                itemBuilder: (_, i) => _ReviewTile(
                  entry: entries[i],
                  onToggle: () => onToggle(i),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: selected > 0 ? onSave : null,
                  child: Text(
                      'Save $selected ${selected == 1 ? 'entry' : 'entries'}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.entry, required this.onToggle});
  final _ParsedEntry entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final sub = [
      '${entry.startTime.substring(0, 5)} – ${entry.endTime.substring(0, 5)}',
      if (entry.group?.isNotEmpty == true) entry.group!,
      if (entry.room?.isNotEmpty == true) entry.room!,
    ].join('  •  ');

    return CheckboxListTile(
      value: entry.selected,
      onChanged: (_) => onToggle(),
      title: Text(
        '${_dayLabels[entry.dayOfWeek]}  —  ${entry.courseCode}',
        style: AppTextStyles.labelMedium,
      ),
      subtitle: Text(sub, style: AppTextStyles.bodySmall),
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}

// ── Internal data models ──────────────────────────────────────────────────────

class _ParsedEntry {
  _ParsedEntry({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.courseCode,
    this.group,
    this.room,
  });
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String courseCode;
  final String? group;
  final String? room;
  bool selected = true;
}

class _TR {
  const _TR(this.start, this.end);
  final String start;
  final String end;

  @override
  bool operator ==(Object o) => o is _TR && start == o.start && end == o.end;

  @override
  int get hashCode => Object.hash(start, end);
}

// Single recognised text block mapped to image-space coordinates
class _CB {
  const _CB(this.midX, this.midY, this.text);
  final double midX;
  final double midY;
  final String text;
}
