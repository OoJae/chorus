# Symbol sources

The SVG files the symbol pictures in `chorus_ui/assets/symbols/` and the
server's `chorus_shared/lib/src/symbol_svgs.dart` are made from, for the words
that are not in `docs/brand/mulberry/`. All CC BY-SA 4.0.

- `mulberry/`: from Mulberry Symbols by Steve Lee
  (https://github.com/mulberrysymbols/mulberry-symbols), renamed to the board
  word they picture and otherwise unchanged: `all` (every), `he`
  (man_-_face), `like` (heart_shape), `not` (mistake_no_wrong), `she`
  (lady_-_face).
- `chorus/`: drawn for Chorus by the Chorus authors in the Mulberry style
  (thick dark outlines, flat fills, dotted squares for "a thing"), for words
  Mulberry has no picture a child would read as the word. Written by
  `draw_chorus_symbols.py`.

To redraw:

    python3 -I draw_chorus_symbols.py chorus
    node render_symbols.js mulberry ../assets/symbols
    node render_symbols.js chorus ../assets/symbols
    python3 -I gen_symbol_svgs.py ../../chorus_shared/lib/src/symbol_svgs.dart \
        ../../docs/brand/mulberry mulberry chorus

`render_symbols.js` needs Playwright for Node (set `PLAYWRIGHT` to its path
if it is not installed where Node finds it).
