/// The view-only board: a page that speaks, for someone outside the circle
/// such as a babysitter. Pure Dart with no database, so the page can be
/// tested as plain text.
///
/// The page is the board as laminated tiles, a sentence strip and two
/// buttons. A tap speaks the word with the browser's own voice and adds it
/// to the strip. It needs no account, sets no cookie and stores nothing:
/// the strip lives in the page and is gone when the tab closes.
library;

import '../printing/print_page.dart';

/// The darker bottom edge of each tile family on light card, by key.
const Map<String, String> tileEdges = {
  'verb': '#7db863',
  'pronoun': '#d6b53f',
  'question': '#9b7bdf',
  'descriptor': '#6e9fe0',
  'determiner': '#a9a8a3',
  'negation': '#d88858',
};

/// Fill and edge of each tile family on dark slate, by key: 8 to 12% less
/// bright than on card, so they do not glare.
const Map<String, (String, String)> darkTileColours = {
  'verb': ('#a9d993', '#5f9a48'),
  'pronoun': ('#e7d57d', '#b0942d'),
  'question': ('#c1aeef', '#7a5bc1'),
  'descriptor': ('#9dc2f1', '#4f7ebf'),
  'determiner': ('#cac9c4', '#8d8c87'),
  'negation': ('#efb88e', '#b76a3d'),
};

/// The view-only page for [board], open until [expiresAt].
///
/// Every piece of text from the snapshot is escaped, and what a tile says
/// travels in a `data-say` attribute, never inside the script. Colours are
/// chosen by class and pictures by label, so nothing from the snapshot
/// reaches the stylesheet or the script. The page loads nothing.
String renderViewOnlyPage(PrintBoard board, {required DateTime expiresAt}) {
  final child = board.childName;
  final heading = child == null ? board.name : "$child's board";
  final whose = child == null ? 'this board' : "$child's board";

  final out = StringBuffer()
    ..write('<!doctype html>\n<html lang="en">\n<head>\n')
    ..write('<meta charset="utf-8">\n')
    ..write('<meta name="viewport" content="width=device-width, ')
    ..write('initial-scale=1">\n')
    ..write('<meta name="robots" content="noindex, nofollow">\n')
    ..write('<meta name="color-scheme" content="light dark">\n')
    ..write('<title>${escapeHtml(heading)}</title>\n')
    ..write('<style>\n')
    ..write(_stylesheet(board))
    ..write('</style>\n</head>\n<body>\n')
    ..write('<header><span class="brand">${brandMarkSvg()}')
    ..write('<span>chorus</span></span>\n')
    ..write('<h1>${escapeHtml(heading)}</h1>\n');
  if (child != null) {
    out.write('<p class="sub">${escapeHtml(board.name)}</p>\n');
  }
  out
    ..write('</header>\n<main>\n')
    ..write('<div class="bar">')
    ..write('<div id="strip" class="strip" aria-label="Sentence"></div>')
    ..write('<button type="button" id="speak" class="act">Speak</button>')
    ..write('<button type="button" id="clear" class="act">Clear</button>')
    ..write('</div>\n')
    ..write('<p class="hint">Tap a word to hear it.</p>\n')
    ..write('<div class="board" role="group" aria-label="Words">\n');
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.cols; col++) {
      final tile = board.cells[(row, col)];
      if (tile == null) {
        out.write('<div class="empty" aria-hidden="true"></div>');
        continue;
      }
      final family = printColours.containsKey(tile.colorKey)
          ? ' c-${tile.colorKey}'
          : '';
      out
        ..write('<button type="button" class="tile$family" ')
        ..write('data-say="${escapeHtml(tile.spokenText)}">')
        ..write(tileFace(tile))
        ..write('</button>');
    }
    out.write('\n');
  }
  out
    ..write('</div>\n</main>\n<footer>\n')
    ..write('<p>A view-only copy of ${escapeHtml(whose)}, shared from ')
    ..write('Chorus. It stops working on ${printDate(expiresAt)}.</p>\n')
    ..write('<p>${escapeHtml(boardCredit)}</p>\n')
    ..write('</footer>\n<script>\n')
    ..write(_script)
    ..write('</script>\n</body>\n</html>\n');
  return out.toString();
}

/// The page for a link that never existed.
String renderViewOnlyUnknownPage() => renderNoticePage(
  title: 'Board not found',
  heading: 'This board is not here',
  text:
      'The link may be mistyped or cut short. Ask the family who shared it '
      'for the link again.',
);

/// The page for a link that has expired or was withdrawn.
String renderViewOnlyGonePage() => renderNoticePage(
  title: 'Board no longer shared',
  heading: 'This board is no longer shared',
  text:
      'The link has expired or the family withdrew it. A view-only board '
      'lasts 7 days. Ask the family for a new link.',
);

/// The page's styles. The board is as wide as the screen allows, and on a
/// wide, short screen narrow enough that it fits the height. Like the app,
/// it has one label size for every tile, the size its longest word fits
/// at.
String _stylesheet(PrintBoard board) {
  final cols = board.cols;
  final gaps = (cols - 1) * 6;
  final ratio = (cols / board.rows).toStringAsFixed(3);
  final longest = board.cells.values
      .map((tile) => tile.label.runes.length)
      .fold(4, (a, b) => a > b ? a : b);
  // A bold system font is a little over half an em wide per letter.
  final perWord = (longest * 0.62).toStringAsFixed(2);
  final light = StringBuffer();
  final dark = StringBuffer();
  printColours.forEach((key, fill) {
    light.write('.c-$key{--fill:$fill;--edge:${tileEdges[key]}}\n');
    final (darkFill, darkEdge) = darkTileColours[key]!;
    dark.write('.c-$key{--fill:$darkFill;--edge:$darkEdge}\n');
  });
  return '''
:root{--card:#f6f2ea;--surface:#ffffff;--ink:#15171a;--muted:#5a5f67;--line:#dcd6cb;--btn:#15171a;--btn-ink:#f6f2ea;--btn-edge:#000000;--bw:min(100vw - 24px,960px,max(320px,(100vh - 220px) * $ratio));--tw:calc((var(--bw) - ${gaps}px) / $cols - 6px)}
*{box-sizing:border-box}
body{margin:0;padding:16px 12px 24px;background:var(--card);color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;line-height:1.4}
header,main,footer{max-width:var(--bw);margin:0 auto}
.brand{display:flex;align-items:center;gap:.4rem;font-weight:700;font-size:1.1rem}
h1{font-size:1.6rem;margin:.75rem 0 0}
.sub{margin:0;color:var(--muted)}
.bar{display:flex;gap:8px;align-items:stretch;margin:16px 0 4px}
.strip{flex:1;min-width:0;min-height:56px;display:flex;flex-wrap:wrap;align-items:center;gap:4px 8px;padding:8px 12px;background:var(--surface);border:1px solid var(--line);border-radius:16px;font-size:1.25rem;font-weight:700}
.strip span{animation:land 200ms ease-out}
@keyframes land{from{opacity:0}to{opacity:1}}
.act{min-width:72px;min-height:56px;padding:0 16px;border:0;border-radius:16px;background:var(--btn);color:var(--btn-ink);font:inherit;font-weight:600;box-shadow:0 3px 0 var(--btn-edge);transition:transform 180ms cubic-bezier(.2,.9,.3,1),box-shadow 180ms cubic-bezier(.2,.9,.3,1);cursor:pointer}
.act:active{transform:translateY(2px);box-shadow:0 1px 0 var(--btn-edge)}
.hint{margin:4px 0 12px;color:var(--muted)}
.board{display:grid;grid-template-columns:repeat($cols,minmax(0,1fr));gap:6px}
.tile,.empty{aspect-ratio:1/1;border-radius:14px}
.empty{border:2px dashed var(--line)}
.tile{--fill:#ffffff;--edge:#a9a8a3;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;min-width:0;padding:4px 3px;border:0;background:var(--fill);color:#15171a;box-shadow:0 3px 0 var(--edge);font:inherit;font-weight:700;font-size:clamp(9px,min(var(--tw) * .2,var(--tw) / $perWord),22px);line-height:1.1;cursor:pointer;-webkit-tap-highlight-color:transparent;transition:transform 180ms cubic-bezier(.2,.9,.3,1),box-shadow 180ms cubic-bezier(.2,.9,.3,1);overflow:hidden}
.tile:active{transform:translateY(2px);box-shadow:0 1px 0 var(--edge)}
.tile .sym{flex:1 1 auto;min-height:0;width:72%}
.tile .sym svg{display:block;width:100%;height:100%}
.tile .label{flex:none;overflow-wrap:anywhere}
${light}button:focus-visible{outline:3px solid var(--ink);outline-offset:3px}
footer{margin-top:24px;font-size:.85rem;color:var(--muted)}
footer p{margin:.25rem 0}
@media (prefers-color-scheme:dark){
:root{--card:#101214;--surface:#1b1e22;--ink:#eee9e0;--muted:#a4a8af;--line:#30343a;--btn:#eee9e0;--btn-ink:#101214;--btn-edge:#8d8c87}
.tile{--fill:#dcd9d2;--edge:#8d8c87}
$dark}
@media (prefers-reduced-motion:reduce){
.strip span{animation:none}
.tile,.act{transition:none}
}
''';
}

/// Tap to speak with the browser's own voice; nothing is sent or kept.
///
/// Only a voice on the device is chosen: an everyday en-US one, then any
/// en-US one, then any English one. An online voice (Chrome's Google
/// voices, Edge's "Online" ones, `localService` false) would send each
/// tapped word to a speech service, so it is never picked; with no voice of
/// its own, the browser speaks with its default.
///
/// Speech is cancelled before each new word, then the word waits until the
/// engine reports it has gone quiet (at most 300 ms), as the app does: a
/// browser that is told to speak while a cancelled word is still stopping
/// can drop the new one.
const String _script = r'''
(function () {
  'use strict';
  var synth = window.speechSynthesis;
  var strip = document.getElementById('strip');
  var said = [];
  var voice = null;
  var engineSpeaking = false;
  var turn = 0;
  var everyday = ['Samantha', 'Microsoft Zira', 'Microsoft David',
    'Google US English', 'Microsoft Aria', 'Microsoft Jenny'];

  function langOf(v) {
    return (v.lang || '').toLowerCase().replace('_', '-');
  }

  function isEnUs(v) {
    return langOf(v) === 'en-us';
  }

  function isEnglish(v) {
    return langOf(v) === 'en' || langOf(v).indexOf('en-') === 0;
  }

  function onDevice(v) {
    return v.localService !== false;
  }

  function chooseVoice() {
    if (!synth || voice) return;
    var list = Array.prototype.filter.call(synth.getVoices() || [], onDevice);
    for (var i = 0; i < everyday.length && !voice; i++) {
      for (var j = 0; j < list.length; j++) {
        if (isEnUs(list[j]) && list[j].name.indexOf(everyday[i]) === 0) {
          voice = list[j];
          break;
        }
      }
    }
    for (var k = 0; k < list.length && !voice; k++) {
      if (isEnUs(list[k])) voice = list[k];
    }
    for (var m = 0; m < list.length && !voice; m++) {
      if (isEnglish(list[m])) voice = list[m];
    }
  }

  function speak(text) {
    if (!synth || !text) return;
    var mine = ++turn;
    var wasSpeaking = engineSpeaking;
    synth.cancel();
    var waits = 0;
    (function go() {
      if (mine !== turn) return;
      if (wasSpeaking && engineSpeaking && waits < 30) {
        waits++;
        setTimeout(go, 10);
        return;
      }
      chooseVoice();
      var u = new SpeechSynthesisUtterance(text);
      u.lang = 'en-US';
      if (voice) u.voice = voice;
      u.rate = 0.9;
      u.onstart = function () { engineSpeaking = true; };
      u.onend = u.onerror = function () { engineSpeaking = false; };
      synth.speak(u);
    })();
  }

  function addWord(text) {
    said.push(text);
    var word = document.createElement('span');
    word.textContent = text;
    strip.appendChild(word);
  }

  if (synth && synth.addEventListener) {
    synth.addEventListener('voiceschanged', chooseVoice);
  }

  var tiles = document.querySelectorAll('.tile');
  for (var t = 0; t < tiles.length; t++) {
    tiles[t].addEventListener('click', function () {
      var text = this.getAttribute('data-say');
      addWord(text);
      speak(text);
    });
  }

  document.getElementById('speak').addEventListener('click', function () {
    speak(said.join(' '));
  });

  document.getElementById('clear').addEventListener('click', function () {
    said = [];
    strip.textContent = '';
    turn++;
    if (synth) synth.cancel();
  });
})();
''';
