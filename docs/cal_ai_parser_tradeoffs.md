# Cal AI PDF Parser — Design Tradeoffs

## Decision: token-lookahead per line, not a whole-line regex

The Python reference (PyMuPDF) put every table cell on its own line, so the original
port's algorithm walked lines with an index and looked ahead a fixed number of lines
(bare-int calorie value, then next 6 lines are grams, 7th is a time) to detect a food
row.

`pdfrx_engine` (the Dart library actually used) does not extract text the same way —
it merges each table row onto a single line, e.g.:

```
Ground Turkey 780 96g 0g 48g 0g 0g 1440mg 3:11pm
```

instead of nine separate lines. This broke the line-count lookahead outright (0 food
entries, null calorie totals on first run against real data) since the lookahead was
checking line offsets that no longer existed.

Two ways to adapt were tried:

1. **Whole-line regex** — one pattern matching name-prefix + 8 trailing values,
   anchored to end-of-line, with a non-greedy `(.*?)` capturing the name.
2. **Token lookahead (chosen)** — split each line on whitespace, then reuse the
   original lookahead shape one level down: check whether the *last 8 tokens* of the
   line match (bare int, 5x grams, 1x mg, 1x time). Whatever tokens precede that tail
   are the name-prefix for that line.

## Why token lookahead won

- **More intuitive** — it's the same lookahead the Python-validated algorithm already
  used, just scoped to a line's trailing tokens instead of the next N lines. No new
  concept to reason about.
- **No backtracking** — the regex's `(.*?)` has to search for where the 8-value tail
  starts; the token version just slices the last 8 tokens and checks each against a
  small fixed pattern (`^\d+g$`, `^\d+mg$`, etc.). Cheaper and more predictable per line.
- **Both validated identically** against the 8-day reference file
  (`summaryjordan7days.pdf`): 8 days, 36 food entries, all 4 known calorie totals
  matched exactly (Aug 16 = 1330, Aug 17 = 2186, Aug 21 = 329, Aug 23 = 586), and
  multi-line wrapped food names (e.g. "Double Quarter Pound Cheeseburger with
  Mayonnaise or Salad Dressing on Bun") reassembled correctly either way.

## Why the performance difference doesn't matter much here (but the choice stands anyway)

Cal AI exports in practice are short — most imports will be a week or two, a month at
the outside — not the full ~8-month/209-day file used as one-time ground truth. At that
scale, a per-line regex vs. a per-line token slice is not a real bottleneck either way.
The token-lookahead approach was kept anyway because it's the clearer piece of code to
read and maintain, independent of the (negligible, at this data volume) performance
edge.

## Known residual risk (applies to either approach)

`currentDate` and `pendingName` reset per PDF page. If a single day's food list is long
enough to spill across a page boundary without Cal AI re-printing the date header on
the continuation page, entries after the break would be silently dropped. Not observed
in either validated file; worth a real check only if a much longer daily log is ever
imported.
