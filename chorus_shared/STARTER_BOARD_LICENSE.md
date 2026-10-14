# Starter board: attribution and licence

The word list and layout of the Chorus home board (`lib/src/starter_board.dart`)
are adapted from the **Universal Core vocabulary**.

- Copyright: Center for Literacy and Disability Studies, University of North
  Carolina at Chapel Hill.
- Licence: Creative Commons Attribution-ShareAlike 4.0 International
  (CC BY-SA 4.0), https://creativecommons.org/licenses/by-sa/4.0/
- Source: https://www.project-core.com/

Chorus is not affiliated with or endorsed by the Center for Literacy and
Disability Studies.

## What was changed

- The 36 words are shown as colour-coded tiles without the original Universal
  Core symbols. Each tile shows a picture: from Mulberry Symbols for 28 of
  the 36, and for the other 8, drawn for Chorus in the same style.
- Each tile carries a part-of-speech colour key. The colour coding follows a
  modified Fitzgerald-style key.

## Symbols

The pictures for 28 of the starter words are from **Mulberry Symbols** by
Steve Lee, https://mulberrysymbols.org

- Licence: Creative Commons Attribution-ShareAlike 4.0 International
  (CC BY-SA 4.0), https://creativecommons.org/licenses/by-sa/4.0/

The pictures for the other 8 words (can, different, do, here, it, stop,
that, you) were drawn for Chorus in the same style by **the Chorus authors**,
because Mulberry Symbols has none a child would read as those words. They are
licensed CC BY-SA 4.0 too.

- `lib/src/symbol_svgs.dart` holds all 36 as SVG, with the Mulberry
  Symbols pictures of the ready-made boards' words, for the pages the server
  draws, such as the paper copy. The app shows them as PNG files drawn from
  the same SVGs,
  in `chorus_ui/assets/symbols/` (see the `LICENSE.md` there). The original
  SVG files are kept in `docs/brand/mulberry/` (the first 23) and
  `chorus_ui/symbols_src/` (the rest).

## Licence of the adaptation

This adaptation (the tiles and colour keys) and the starter-board data in
this package are released under CC BY-SA 4.0,
https://creativecommons.org/licenses/by-sa/4.0/
