/// The one-page progress report: counts from the word log for one week,
/// rendered as a page that prints cleanly. Never a sentence or a
/// transcript: words and numbers only.
///
/// Pure Dart with no database, so the page can be tested as plain text.
library;

import '../generated/protocol.dart';
import '../printing/print_page.dart'
    show brandMarkSvg, escapeHtml, printDate, renderNoticePage;

/// Most words listed under one heading, so the page stays one page.
const int maxReportListed = 24;

/// The page for [report], made on [savedAt], that stops opening at
/// [expiresAt]. Every piece of text is escaped; the page loads nothing and
/// runs no script.
String renderProgressPage(
  ProgressReport report, {
  required DateTime savedAt,
  required DateTime expiresAt,
}) {
  final week = report.week;
  final child = report.childName.trim().isEmpty
      ? 'The child'
      : report.childName.trim();
  final heading = '$child: progress, week of ${printDate(week.weekStart)}';
  final modelled = week.modelled ?? const <ModelledTally>[];
  final totalModelled = modelled.fold<int>(0, (sum, row) => sum + row.modelled);

  final out = StringBuffer()
    ..write('<!doctype html>\n<html lang="en">\n<head>\n')
    ..write('<meta charset="utf-8">\n')
    ..write('<meta name="viewport" content="width=device-width, ')
    ..write('initial-scale=1">\n')
    ..write('<meta name="robots" content="noindex, nofollow">\n')
    ..write('<title>${escapeHtml(heading)}</title>\n')
    ..write('<style>\n$_stylesheet</style>\n</head>\n<body>\n')
    ..write('<header><span class="brand">${brandMarkSvg()}')
    ..write('<span class="word">chorus</span></span>')
    ..write('<h1>${escapeHtml(heading)}</h1></header>\n')
    ..write('<p class="hint">Counts from the word log, Monday to Sunday. ')
    ..write('No sentences are kept, only how often each word was used.</p>\n')
    ..write('<section class="totals">\n')
    ..write(_total(week.wordsUsed, 'different words'))
    ..write(_total(week.firstTimeWords.length, 'new words'))
    ..write(_total(week.totalUses, 'words said in all'))
    ..write(_total(totalModelled, 'times an adult modelled a word'))
    ..write('</section>\n');

  if (report.focus.isNotEmpty) {
    out.write('<h2>Focus words</h2>\n<table>\n');
    out.write('<tr><th>Word</th><th>Modelled</th><th>Said</th>');
    out.write('<th>Tip</th></tr>\n');
    for (final line in report.focus) {
      out
        ..write('<tr><td class="w">${escapeHtml(line.label)}</td>')
        ..write('<td>${line.modelled}</td><td>${line.said}</td>')
        ..write('<td>${escapeHtml(line.tip)}</td></tr>\n');
    }
    out.write('</table>\n');
  }

  if (modelled.isNotEmpty) {
    out.write('<h2>Modelled and said</h2>\n<table>\n');
    out.write('<tr><th>Word</th><th>Modelled</th><th>Said</th></tr>\n');
    for (final row in modelled) {
      out
        ..write('<tr><td class="w">${escapeHtml(row.label)}</td>')
        ..write('<td>${row.modelled}</td><td>${row.said}</td></tr>\n');
    }
    out.write('</table>\n');
  }

  if (week.topWords.isNotEmpty) {
    out.write('<h2>Most used</h2>\n<table>\n');
    out.write('<tr><th>Word</th><th>Times</th></tr>\n');
    for (final word in week.topWords) {
      out
        ..write('<tr><td class="w">${escapeHtml(word.label)}</td>')
        ..write('<td>${word.count}</td></tr>\n');
    }
    out.write('</table>\n');
  }

  out
    ..write(_list('New this week', week.firstTimeWords))
    ..write(_list('Added and not used yet', _addedNotUsed(week)))
    ..write('<footer>\n')
    ..write('<p>Made on ${printDate(savedAt)}. ')
    ..write('This link stops working on ${printDate(expiresAt)}.</p>\n')
    ..write('</footer>\n</body>\n</html>\n');
  return out.toString();
}

/// Words added to a board this week that have not been said yet.
List<String> _addedNotUsed(WeekReport week) {
  final notUsed = {for (final word in week.notUsedYet) word.toLowerCase()};
  return [
    for (final word in week.addedWords)
      if (notUsed.contains(word.toLowerCase())) word,
  ];
}

String _total(int count, String what) =>
    '<div class="total"><span class="n">$count</span>'
    '<span class="t">${escapeHtml(what)}</span></div>\n';

String _list(String heading, List<String> words) {
  if (words.isEmpty) return '';
  final shown = words.take(maxReportListed).map(escapeHtml).join(', ');
  final more = words.length > maxReportListed
      ? ' and ${words.length - maxReportListed} more'
      : '';
  return '<h2>${escapeHtml(heading)}</h2>\n<p class="words">$shown$more</p>\n';
}

/// The page shown when a report link is unknown or has expired; the two
/// look the same.
String renderMissingReportPage() => renderNoticePage(
  title: 'Report not found',
  heading: 'This report is not here',
  text:
      'The link is wrong or has expired. Report links last 30 days. Ask an '
      'adult in the circle to make a new one.',
);

const String _stylesheet =
    'body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;'
    'margin:2rem auto;max-width:44rem;padding:0 1.25rem;background:#fff;'
    'color:#15171a;line-height:1.45}'
    'header{display:flex;flex-direction:column;gap:.75rem}'
    '.brand{display:flex;align-items:center;gap:.5rem;font-weight:700;'
    'font-size:1.1rem}.brand svg{width:28px;height:28px}'
    'h1{font-size:1.5rem;margin:.25rem 0}h2{font-size:1.1rem;'
    'margin:1.5rem 0 .5rem}.hint{color:#4a4f57}'
    '.totals{display:grid;grid-template-columns:repeat(4,1fr);gap:.75rem;'
    'margin:1.25rem 0}.total{border:1px solid #d9d4ca;border-radius:12px;'
    'padding:.75rem}.n{display:block;font-size:1.75rem;font-weight:700}'
    '.t{color:#4a4f57;font-size:.9rem}'
    'table{border-collapse:collapse;width:100%}th,td{text-align:left;'
    'padding:.35rem .5rem;border-bottom:1px solid #e6e1d8}'
    'th{font-size:.85rem;color:#4a4f57}.w{font-weight:600}'
    '.words{margin:.25rem 0}footer{margin-top:2rem;color:#4a4f57;'
    'font-size:.85rem}'
    '@media (max-width:560px){.totals{grid-template-columns:repeat(2,1fr)}}'
    '@media print{body{margin:0 auto}}\n';
