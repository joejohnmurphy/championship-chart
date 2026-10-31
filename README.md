# Championship History Chart

A printable reference chart of every MLB, NFL, NHL, and NBA champion in
history — one row per year, one column per league. Each cell shows the
champion and the runner-up they defeated, colored in each team's own brand
colors, along with season records and series results.

## What's in each cell

- **Champion** (top): team name in a gradient fill of their primary &rarr;
  secondary brand color, with a trophy icon and a small superscript number
  showing their cumulative championship count through that year (merged
  across relocations/renames — e.g. Brooklyn Dodgers + LA Dodgers count
  together).
- **Runner-up** (bottom): team name in a bordered pill using their own team
  colors.
- Both show their regular-season record and the series result (games won
  for MLB/NHL/NBA; point totals for the single NFL championship game).
- NFL cells from 1966 onward also show the Super Bowl number (Roman
  numerals) in the corner.
- Years with no championship held (1994 MLB strike, 1919 & 2005 NHL) are
  shown in neutral gray.

## Output formats

- **`championship_chart.html`** — view in any browser, or use the
  browser's Print dialog (landscape works best on-screen).
- **`championship_chart.pdf`** — pre-rendered, portrait orientation with
  narrow margins, ready to print directly. Regenerate with `build_pdf.ps1`
  after any data/style change.

## Data coverage

| League | Years covered |
|---|---|
| MLB  | 1903–2026 |
| NFL  | 1920–2025 |
| NHL  | 1915–2026 (gaps: 1919, 2005 — no champion) |
| NBA  | 1947–2026 |

## How it's built

Everything is generated from plain-text data files by a PowerShell script
— no Node/Python/build tools required.

| File | Purpose |
|---|---|
| `mlb.txt`, `nfl.txt`, `nhl.txt`, `nba.txt` | Raw per-year data, one line each. Format: `YEAR\|CHAMPION\|CHAMPION_RECORD\|CHAMPION_SERIES_GAMES_OR_PTS\|RUNNERUP\|RUNNERUP_RECORD\|RUNNERUP_SERIES_GAMES_OR_PTS\|CHAMPION_HEX\|RUNNERUP_HEX` |
| `secondary.txt` | Secondary brand hex color per team name: `TEAM NAME\|#HEXCOLOR` |
| `template.html` | Page shell (all CSS, header/footer); contains a `__ROWS__` placeholder |
| `build.ps1` | Reads the data files, builds the table rows, writes `championship_chart.html` |
| `build_pdf.ps1` | Renders the HTML to `championship_chart.pdf` via headless Chrome/Edge |

### Regenerating after a data or style change

```powershell
cd championship-chart
.\build.ps1
.\build_pdf.ps1
```

> **Note:** if `championship_chart.pdf` is currently open in a PDF viewer
> (e.g. Edge), `build_pdf.ps1` will fail to overwrite it — close the file
> first.

### Adding a new year

1. Open the relevant league's `.txt` file.
2. Append a new line in the same pipe-delimited format: champion & runner-up
   names, each team's regular-season record, series games won (or NFL
   championship-game points), and each team's current primary hex color.
3. If either team is new, add its secondary color to `secondary.txt`.
4. Run `.\build.ps1` (and `.\build_pdf.ps1`) to regenerate.

## Known data caveats

- Historical data was compiled by AI research agents from public sources
  (primarily Wikipedia championship lists) and spot-checked, but not
  independently verified line-by-line.
- Pre-1930 season records (especially early NFL/NHL) are best-effort
  approximations from short/irregular-schedule eras.
- Team colors are each franchise's *current* brand colors, not necessarily
  historically-accurate for relocated/renamed/defunct teams.
- A few long-defunct franchises with no modern brand guide have
  approximated colors.
- 2026 NFL champion not yet added — that season is still in progress as
  of when this was last updated (Super Bowl LXI will be played Feb 2027).

For the full history of design decisions, bugs found/fixed, and the
reasoning behind specific choices, see
[`PROJECT_NOTES.md`](PROJECT_NOTES.md).
