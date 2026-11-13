import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../feedback/problem_log.dart';
import '../../feedback/rating.dart';
import '../screens/profile_screen.dart' show appBuild;
import '../theme/app_theme.dart';

/// What the report is about (chips on the report screen).
enum ReportArea {
  strength('Strength'),
  run('Running'),
  heartRate('Heart rate'),
  timers('Timers & sounds'),
  data('Data & backup'),
  other('Something else');

  const ReportArea(this.label);
  final String label;
}

/// Settings › Help: "Report a problem" and "Rate HR Zones".
class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListenableBuilder(
          listenable: ProblemLog.instance,
          builder: (context, _) {
            final n = ProblemLog.instance.entries.length;
            return ListTile(
              key: const Key('reportProblem'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report a problem'),
              subtitle: Text(
                n == 0
                    ? 'Tell us what went wrong – it opens a message you can send'
                    : 'Tell us what went wrong · the app noticed $n problem${n == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openReportProblem(context),
            );
          },
        ),
        ListTile(
          key: const Key('rateApp'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.star_outline_rounded),
          title: const Text('Rate HR Zones'),
          subtitle: const Text('1 to 5 stars'),
          onTap: () => askForRating(context),
        ),
      ],
    );
  }
}

Future<void> openReportProblem(BuildContext context, {String? text, ReportArea? area}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ReportProblemScreen(initialText: text, initialArea: area),
  ),
);

/// Write what went wrong; the app adds its version, phone and the errors it
/// noticed, and opens the share sheet (mail, WhatsApp…). Nothing is sent by
/// itself.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, this.initialText, this.initialArea});

  final String? initialText;
  final ReportArea? initialArea;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  late final _text = TextEditingController(text: widget.initialText ?? '');
  late ReportArea? _area = widget.initialArea;
  bool _details = true;
  bool _showErrors = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<String> _report() async {
    final s = Services.of(context);
    final ratings = await s.ratings();
    final errors = ProblemLog.instance.entries;
    return buildReport(
      text: _text.text,
      area: _area,
      details: _details,
      errors: errors,
      lastRating: ratings.lastOrNull,
      workoutRunning: s.session.active != null,
      runRunning: s.run.active,
    );
  }

  Future<void> _send() async {
    final box = context.findRenderObject() as RenderBox?;
    final messenger = ScaffoldMessenger.of(context);
    final report = await _report();
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: report,
          subject: 'HR Zones – problem report',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (result.status != ShareResultStatus.dismissed && mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Thanks! The report is on its way.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open the share sheet: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = AppTheme.of(context);
    final errors = ProblemLog.instance.entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What is it about?', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in ReportArea.values)
                ChoiceChip(
                  key: Key('area_${a.name}'),
                  label: Text(a.label),
                  selected: _area == a,
                  onSelected: (on) => setState(() => _area = on ? a : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('What happened?', style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('reportText'),
            controller: _text,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What did you do, what did you expect, what happened instead?'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            key: const Key('reportDetails'),
            contentPadding: EdgeInsets.zero,
            value: _details,
            onChanged: (v) => setState(() => _details = v),
            title: const Text('Add app details'),
            subtitle: Text(
              errors.isEmpty
                  ? 'App version and phone. No workouts, names or places.'
                  : 'App version, phone and the ${errors.length} problem${errors.length == 1 ? '' : 's'} '
                        'the app noticed. No workouts, names or places.',
            ),
          ),
          if (errors.isNotEmpty) ...[
            TextButton(
              key: const Key('showErrors'),
              onPressed: () => setState(() => _showErrors = !_showErrors),
              child: Text(_showErrors ? 'Hide what the app noticed' : 'Show what the app noticed'),
            ),
            if (_showErrors)
              for (final e in errors.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_date(e.at)}  ${e.message}',
                    style: text.bodySmall?.copyWith(color: t.muted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('sendReport'),
            onPressed: _text.text.trim().isEmpty && _area == null ? null : _send,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send report'),
          ),
          const SizedBox(height: 8),
          Text(
            'Opens the share sheet – pick Mail, WhatsApp or Messages. Nothing is sent without you.',
            style: text.bodySmall?.copyWith(color: t.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');
String _date(DateTime d) => '${d.day}/${d.month} ${_two(d.hour)}:${_two(d.minute)}';

/// The text of a report (plain text, readable in any mail app).
String buildReport({
  required String text,
  ReportArea? area,
  required bool details,
  List<ProblemEntry> errors = const [],
  Rating? lastRating,
  bool workoutRunning = false,
  bool runRunning = false,
}) {
  final b = StringBuffer('HR Zones – problem report\n');
  if (area != null) b.writeln('About: ${area.label}');
  b
    ..writeln()
    ..writeln(text.trim().isEmpty ? '(no description)' : text.trim());
  if (!details) return b.toString();
  b
    ..writeln()
    ..writeln('— App details —')
    ..writeln('Version: $appBuild')
    ..writeln('Phone: ${kIsWeb ? 'web preview' : defaultTargetPlatform.name}')
    ..writeln('Sent: ${DateTime.now().toIso8601String()}');
  if (workoutRunning) b.writeln('A strength workout is running');
  if (runRunning) b.writeln('A run is running');
  if (lastRating != null) b.writeln('Last rating: ${lastRating.stars}/5 (${_date(lastRating.at)})');
  if (errors.isNotEmpty) {
    b
      ..writeln()
      ..writeln('— Problems the app noticed (newest first) —');
    for (final e in errors.take(15)) {
      b.writeln('${e.at.toIso8601String()}  ${e.message}');
      if (e.where != null) b.writeln(e.where!.split('\n').take(3).map((l) => '    $l').join('\n'));
    }
  }
  return b.toString();
}

// ── Rate the app ─────────────────────────────────────────────────────────

/// Asks "How do you like HR Zones?" when it is due (a week after the first
/// open, then monthly) – never during a workout or run. Called at start-up
/// and when the app comes back to the foreground.
Future<void> maybeAskForRating(BuildContext context) async {
  final s = Services.of(context);
  if (s.session.active != null || s.run.active || s.needsOnboarding.value) return;
  if (!await s.ratingDue()) return;
  if (!context.mounted) return;
  await askForRating(context);
}

/// The 1–5 star question. 4–5 stars: thanks. 1–3: offers to tell us why
/// (opens Report a problem).
Future<void> askForRating(BuildContext context) async {
  final s = Services.of(context);
  final stars = await showDialog<int>(context: context, builder: (context) => const _RateDialog());
  await s.answerRating(stars);
  if (stars == null || !context.mounted) return;
  if (stars >= 4) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you! Glad you like it.')));
    return;
  }
  final tell = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sorry to hear that'),
      content: const Text('What should we make better? A few words help a lot.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
        FilledButton(
          key: const Key('rateTellUs'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tell us'),
        ),
      ],
    ),
  );
  if (tell == true && context.mounted) {
    await openReportProblem(context, text: 'I gave $stars/5 because ', area: ReportArea.other);
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog();

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return AlertDialog(
      key: const Key('rateDialog'),
      title: const Text('How do you like HR Zones?', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('star_$i'),
                  iconSize: 40,
                  visualDensity: VisualDensity.compact,
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i <= _stars ? t.bright : t.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            const ['Tap a star', 'Not good', 'Could be better', 'OK', 'Good', 'Love it'][_stars],
            style: TextStyle(color: t.muted),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(key: const Key('rateLater'), onPressed: () => Navigator.pop(context), child: const Text('Not now')),
        FilledButton(
          key: const Key('rateSubmit'),
          onPressed: _stars == 0 ? null : () => Navigator.pop(context, _stars),
          child: const Text('Rate'),
        ),
      ],
    );
  }
}
