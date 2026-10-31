# PROJECT_NOTES.md — Agent Continuity Doc

> **For the AI agent**: Read this file at the start of any session working
> in this repo. It has the full history of what's been built, why, every
> bug hit and how it was fixed, and the current state of things. Keep it
> updated at the end of every change — add new entries to the changelog,
> don't delete old ones. This is the single source of truth for picking up
> where we left off.

## Project summary

A printable HTML/PDF chart: one row per year (1903–2025, newest first),
one column per league (MLB, NFL, NHL, NBA). Each cell shows that year's
champion and runner-up, colored in team brand colors, with records and
series results. Built entirely with plain-text data files + a PowerShell
generator script — no Node/Python available in this environment, so
everything is done in Windows PowerShell 5.1.

## Current file layout

```
championship-chart/
├── README.md              # public-facing description (for GitHub visitors)
├── PROJECT_NOTES.md        # this file — agent continuity/changelog
├── mlb.txt                 # raw data, one line per year
├── nfl.txt
├── nhl.txt
├── nba.txt
├── secondary.txt           # secondary brand color per team name
├── template.html           # page shell/CSS, has __ROWS__ placeholder
├── build.ps1                # generates championship_chart.html from the above
├── build_pdf.ps1             # renders championship_chart.html -> .pdf via headless Chrome/Edge
├── championship_chart.html  # generated output (view/print in browser)
└── championship_chart.pdf   # generated output (portrait, narrow margins, ready to print)
```

### Data file format

Each line in `mlb.txt`/`nfl.txt`/`nhl.txt`/`nba.txt`:
```
YEAR|CHAMPION|CHAMPION_RECORD|CHAMPION_SERIES_GAMES(or pts for NFL)|RUNNERUP|RUNNERUP_RECORD|RUNNERUP_SERIES_GAMES(or pts)|CHAMPION_HEX|RUNNERUP_HEX
```
"No championship held" years: `YEAR|NO SERIES (reason)|||||||` (MLB 1994
strike, NHL 1919 flu pandemic, NHL 2005 lockout).

`secondary.txt`: `TEAM NAME|#HEXCOLOR`, one line per unique team name
across all 4 leagues' data files.

### Regenerating
```powershell
cd championship-chart
.\build.ps1
.\build_pdf.ps1
```
**Gotcha**: `build_pdf.ps1` fails silently ("Access is denied") if the
previous `championship_chart.pdf` is still open in a viewer (Edge is the
default Windows PDF viewer) — close it first, then re-run.

## Data coverage as of now
MLB 1903–2026, NFL 1920–2025, NHL 1915–2026, NBA 1947–2026. All four
leagues' 2026-labeled seasons (which conclude mid-year for NHL/NBA, and
represent the 2025 NFL season via the Feb 2026 Super Bowl) have been
added as of Oct 2026 using Wikipedia's season-specific articles rather
than the general "list of champions" pages (which were still correct for
these years, confirming the data). The 2026 NFL season itself is still
in progress as of this writing and has not been added (Super Bowl LXI
would be Feb 2027).

## Full changelog (chronological)

1. **Initial build**: researched full championship history for all 4
   leagues via parallel AI research agents (Wikipedia-sourced), compiled
   into pipe-delimited `.txt` files, wrote a Python-style generator —
   except Python/Node weren't available in this environment, so the whole
   thing was rebuilt in PowerShell (`build.ps1`). Landscape print layout,
   zebra striping, basic team-color badges.
2. Increased row spacing/padding since cells felt cramped.
3. Removed "def." divider line between champion/runner-up to save space.
4. Bumped font sizes up repeatedly per feedback (title, headers, cell
   text, team badges) since there was room on the page.
5. Champion badge made larger/bolder than runner-up (19px vs 14.5px) so
   the winner visually dominates.
6. Pushed champion/runner-up contrast further: trophy emoji, uppercase,
   extra-bold, gold border, drop shadow on champion; runner-up shrunk,
   normal weight, reduced opacity.
7. **Major redesign**: champion's full cell background now filled with
   their team color (instead of a small badge); runner-up kept as a
   bordered pill inside. Auto white/dark text contrast via a luminance
   calculation (`Get-FG`/`Get-Luminance` in `build.ps1`).
8. **Compression pass**: cut cell padding, thinned borders, roughly halved
   font sizes, merged name+record onto one line — all to fit more years
   on screen/print at once.
9. Added `secondary.txt` (secondary brand color for all ~157 unique team
   names) and switched the champion cell to a diagonal two-tone gradient
   (primary&rarr;secondary) instead of a flat fill; runner-up pill given a
   2px border in its own secondary color. Ambiguity note: "New York
   Giants" exists in both MLB (old NY baseball Giants, now SF Giants) and
   NFL data — `secondary.txt` has both, keyed as `New York Giants` and
   `New York Giants (NFL)`; `Get-Secondary` disambiguates by league param.
10. Gave "no championship" cells (1994 MLB, 1919 & 2005 NHL) a neutral
    gray background so they recede instead of standing out.
11. **Color uniqueness audit**: cross-checked every (primary, secondary)
    pair within each league for collisions between genuinely different
    teams. Most "duplicates" found were actually the same franchise under
    a historical name (correctly share colors, left alone — e.g. Brooklyn/
    LA Dodgers). The one real collision: NBA Bulls/Rockets/Raptors all
    red+black — fixed with historically-grounded alternates (Rockets
    &rarr; red+silver, Raptors &rarr; red+purple nod to their 1995
    branding).
12. Added Super Bowl numbers (Roman numerals) to NFL cells, 1966 onward.
    Formula: `SB# = year - 1965`. **Bug hit**: PowerShell's `[ordered]`
    hashtable indexer treats small int keys (50, 10, 5, etc.) as
    *positional* array indices, not dictionary lookups — silently
    corrupted numeral conversion. Fixed by using an array of
    `(value, numeral)` pairs instead of a hashtable in `To-Roman`.
13. Moved the Super Bowl label from its own line (which broke vertical
    alignment with the other 3 league columns) to an absolutely-positioned
    corner label (tried top-right first, moved to bottom-right per
    feedback) so it doesn't affect content flow/centering.
14. **Second color audit** (user flagged Dodgers/Astros/Royals/Yankees/
    Cardinals/Pirates as "looking off"): found and fixed real errors —
    Dodgers & Yankees secondary was red (neither team uses red; fixed to
    white), Pirates & Bruins had primary/secondary *swapped* (gold was
    used as the primary cell-fill when black should be primary and gold
    the accent — swapped in `mlb.txt`/`nhl.txt`), Astros had one
    inconsistent old entry (2005) using orange instead of navy as primary.
    Also fixed several secondary==primary no-contrast cases (Rangers,
    Angels, Ducks, Spurs, Panthers, Titans). Royals and Cardinals were
    checked and found already correct.
15. Fixed Super Bowl label contrast: since it sits in the bottom-right
    corner of a diagonal gradient cell, that corner is dominated by the
    *secondary* color, not primary — contrast calc switched from
    `$champColor` to `$champSecondary`.
16. Made the title bigger (18px&rarr;34px) and "fun": bold italic serif
    with a multi-color gradient text fill. Column headers bumped
    (10px&rarr;15px) with an emoji sport icon added to each (&#9918; MLB,
    &#127944; NFL, &#127954; NHL, &#127936; NBA).
17. Added cumulative championship counts: small superscript number next
    to the trophy showing total titles for that franchise through that
    year. Required a new `$aliases` table in `build.ps1` mapping
    historical/relocated team names to one canonical franchise key (e.g.
    Brooklyn Dodgers + LA Dodgers both count as "Dodgers") so counts carry
    through relocations instead of resetting. Pre-computed via a
    chronological walk per league into a `"league|year" -> count` lookup.
    **Known simplification**: the two historically *separate* "Baltimore
    Bullets" NBA franchises (1948 one folded in 1954; a different 1963
    franchise that became the Wizards) share an identical name in the
    data and get merged into one count — minor inaccuracy, not fixed
    (rare edge case).
18. Added PDF export (`build_pdf.ps1`) using headless Chrome/Edge
    (`--headless=new --print-to-pdf`), initially landscape to match the
    HTML's `@page` rule — worked immediately since the existing CSS
    already handled pagination (`page-break-inside: avoid` per row,
    repeating `<thead>`).
19. Switched PDF to **portrait** with narrow (0.15in) margins per request.
    Added a `@media print` block (the `@page` rule itself only affects
    print, not on-screen view, so no separate stylesheet needed) to
    shrink headers/cell text for the narrower columns, and added
    `print-color-adjust: exact` so gradients/colors aren't dropped by the
    browser's print rendering.
20. **Fixed uneven row heights in the PDF**: long team names were
    wrapping to 2 lines while short names stayed on 1, making rows
    inconsistent height. Fixed by forcing single-line text with
    `text-overflow: ellipsis` truncation for print instead of wrapping,
    plus a fixed minimum `td` height — guarantees uniform row height
    regardless of name length (very long names truncate with "…").
21. **Moved to a git repo** at `C:\Users\jmurphy\repos\championship-chart`
    for GitHub. Split the old combined README into a public-facing
    `README.md` (what/how for visitors) and this `PROJECT_NOTES.md`
    (agent continuity doc, kept updated every session going forward).
22. Three cell-content/style changes per feedback:
    - Added "def." back before the runner-up name, same line (removed
      earlier during a compression pass, user wanted it back now that
      there's room).
    - Replaced clunky "won X" / "X pts" wording with a single combined
      outcome line on the champion's row: "Series 4-2" for MLB/NHL/NBA,
      "Final 24-14" for NFL. Runner-up's line now shows only their season
      record (no longer repeats a redundant stat), since the full series
      result is already captured on the champion's line.
    - **Color scheme overhaul**: replaced the diagonal gradient fill
      (felt "muddy"/dated) with a clean **solid primary-color fill + a
      7px secondary-color accent stripe on the left edge**
      (`linear-gradient(90deg, secondary 0-7px, primary 7px-100%)` — a
      hard-stop gradient used purely as a stripe trick, not a blend).
      User was offered 4 style options (hard diagonal split, vertical
      halves, solid+stripe, solid-only) via explicit choice; picked
      solid+stripe. Also reverted the Super Bowl label's contrast
      calculation back to `$champFg` (based on primary color) since the
      bottom-right corner is no longer dominated by the secondary color
      now that it's just a thin left-edge stripe.
23. Reverted the stripe/gradient scheme after seeing it rendered — user
    wants a 1972/1979 Topps baseball card aesthetic (which they said the
    general design already evoked). New approach:
    - Cell background is now a **solid fill** in the champion's primary
      color only (no stripe, no gradient).
    - The **champion's name text is now colored in their secondary color**
      (not an auto-computed white/black contrast color) — this is the key
      "trading card" look: team-colored lettering directly on the team's
      other color as the card background. Added a 4-direction thin dark
      text-shadow (mimics an outline/stroke) so the name stays legible
      even when primary/secondary happen to be low-contrast.
    - Replaced the single "Series 4-2" / "Final 24-14" line (which only
      attached to the champion's row and looked unbalanced) with a
      right-aligned, fixed-width `.tally` number at the end of **both**
      the champion's and runner-up's row — so e.g. a 4 and a 3 line up
      vertically like a little scoreboard column, regardless of how long
      the team name/record text is.       Each side just shows their own
      games-won (or points, for NFL) again, like early in the project,
      but now visually aligned between the two rows instead of being
      stuffed onto one line.
24. **Fixed unreadable champion-name text** (e.g. dark navy on red for
    Texas Rangers) by adding a proper WCAG-style contrast-ratio check
    (`Get-ContrastRatio`/`Get-RelLuminance` using the real sRGB-to-linear
    gamma formula, not the quick-and-dirty weighted-average one used for
    `Get-FG`). New `Get-LegibleColor($textHex, $bgHex, $minRatio)`: if the
    secondary color already contrasts well against the primary background,
    it's left untouched; otherwise its **lightness is nudged** (via HSL
    conversion, same hue/saturation preserved) toward white or black,
    whichever direction improves contrast more, until it clears the
    threshold (3.2 used). This keeps the team's color identity (still
    reads as "blue", "gold", etc.) while guaranteeing legibility, instead
    of just falling back to generic black/white text.
    **Significant bug hit while building this**: PowerShell operator
    precedence gotcha — `@($r*255, $g*255, $b*255)` does **not** parse as
    three separate multiplied terms; the comma operator binds tighter than
    expected, so PowerShell parsed it as `$r * (255, $g*255, $b*255)`
    (scalar times array), which fails with a cryptic
    "`System.Object[] does not contain a method named 'op_Multiply'`"
    error on every single cell during every build. Took substantial
    isolated testing (stripped-down repro scripts) to track down. **Fix**:
    always wrap each multiplied term in its own parens inside an `@()`
    list: `@(($r*255), ($g*255), ($b*255))`. Worth remembering for any
    future PowerShell array-literal code in this project: comma-separated
    arithmetic expressions inside `@(...)` need explicit parens per term.
25. **Fixed "blurry"/unreadable champion names even after the contrast
    fix** (San Francisco Giants, Florida Marlins, Denver Broncos, New
    Jersey Devils flagged specifically). Root cause: the champion name's
    outline/drop-shadow was **hardcoded to always be dark**
    (`rgba(0,0,0,...)`). When `Get-LegibleColor` legitimately decided the
    best-contrast text color was itself dark (e.g. Blackhawks' black, or
    navy on orange for Broncos), a dark outline on dark text gave zero
    edge definition &mdash; fill and outline blended into one muddy blob,
    even though the raw text-vs-background contrast ratio was technically
    adequate. Fix: outline color is now computed **per cell**, opposite
    in tone from the final text color (via `Get-FG $champNameColor`) --
    light text gets a dark outline, dark text gets a light/white outline
    &mdash; so     letters always have a crisp edge regardless of which way
    the contrast algorithm pushed the fill color. Moved from a static CSS
    `text-shadow` on `.champ` to an inline `style` set per cell in
    `build.ps1`. Also bumped the minimum contrast ratio threshold in
    `Get-LegibleColor` from 3.2 to 4.5 for extra safety margin.
26. **Large fix-everything round, then fully reverted.** Attempted six
    fixes in one go: Pirates background to pure black, a warm-hue fallback
    in `Get-LegibleColor` to fix "pink" text (Tigers/Bears/NFL Giants/
    Islanders), a cross-league one-primary-color-per-team collision audit
    (Bulls/Rockets/Raptors etc.), tally-column alignment via `margin-left:
    auto`, a drop-shadow on the runner-up pill, and separating the trophy
    emoji from the shadowed name span to fix duplicate-looking rendering.
    **User feedback was that this round made things worse overall**, so
    every part of it was undone: `build.ps1` (`Get-LegibleColor`,
    `Set-Lightness`/removed `Set-LightnessDesaturated`, `Get-FG`, the
    trophy/champ HTML structure), `template.html` (`.result-line`,
    `.tally`, `.runner`, removed `.trophy`), and all data-file color
    changes in `mlb.txt`/`nfl.txt`/`nhl.txt`/`nba.txt`/`secondary.txt`
    were reverted back to their state from the end of entry 25 (the
    "adaptive outline tone" round, which the user *was* happy with).
    Current state = entry 25's fixes are live; entry 26 never happened as
    far as the generated output is concerned. If asked to revisit any of
    these six issues in the future, treat them as a fresh problem rather
    than assuming the old approach was close to right -- it wasn't, per
    feedback.
27. **Reintroduced just the runner-up pill depth styling from the
    reverted round** (user liked that one part specifically). `.runner`
    border thinned from 2px to 1.5px and given a `box-shadow` (drop shadow
    + a subtle inset top highlight), so the pill reads as a slightly
    raised badge instead of flat. Nothing else from entry 26 was
    reintroduced.
28. Also per feedback: removed "Super Bowl" text from the NFL corner
    label, leaving just the Roman numeral, and moved it from bottom-right
    to top-left of the cell.
29. **Added 2026 championships** for MLB, NHL, and NBA (all three
    concluded by Oct 2026) plus the NFL's 2025-season champion (Super
    Bowl LX, played Feb 2026) — the only remaining gap is the 2026 NFL
    season itself, still in progress. Sourced via Wikipedia's dedicated
    season articles (`2026_World_Series`-equivalent season pages, Super
    Bowl LX, `2026_Stanley_Cup_Final`, `2026_NBA_Finals`) rather than the
    general all-time champions list pages, to get full regular-season
    win-loss records alongside the series results:
    - MLB: Milwaukee Brewers (103-59) def. Tampa Bay Rays (98-64), 4-1 —
      first World Series title in Brewers franchise history.
    - NFL (2025 season / Super Bowl LX): Seattle Seahawks (14-3) def. New
      England Patriots (14-3), 29-13.
    - NHL: Carolina Hurricanes (53-22-7) def. Vegas Golden Knights
      (39-26-17), 4-2 — Hurricanes' 2nd Cup (first since 2006).
    - NBA: New York Knicks (53-29) def. San Antonio Spurs (62-20), 4-1 —
      Knicks' 3rd championship (first since 1973).
    All four reused existing hex colors already present in the data files
    for these teams (no new colors needed). Verified cumulative
    championship-count badges came out correct for all four (Brewers 1st,
    Hurricanes 2nd, Knicks 3rd) as a sanity check on the `$aliases`/
    `$cumulative` logic still working properly with the new rows appended.
30. Per feedback: moved the trophy icon closer to the title-count number
    (tightened via negative margin on `.trophy`, iterated twice -3px then
    -5px), and moved the Super Bowl Roman-numeral corner label from
    top-left back to bottom-right (it had been top-left briefly, moved
    there earlier per a different request, then back per this one) to
    resolve it visually overlapping the trophy in narrow NFL cells.
31. **Combined the two separate right-aligned "tally" numbers into one
    score.** Previously each row (champion and runner-up) had its own
    right-aligned games-won/points number pushed to the cell's right edge
    via `margin-left: auto`, which looked like two disconnected numbers.
    Replaced with a single `.score` span (e.g. "4-1") placed once, right
    after the runner-up's record on the runner-up's row only -- removed
    `$champTally`/`$runnerTally` and the champion row's trailing number
    entirely; `$scoreLabel = "$champGames-$runnerGames"` computed once.
    **First attempt overshot**: kept `margin-left: auto` on the new
    `.score`, which again pushed it to the far right and left the rest of
    the runner-up row (def./pill/record) bunched on the left -- broke the
    centering the row previously had. Fixed by removing the auto-margin
    entirely so `.score` behaves like any other item in the still
    center-justified `.result-line` flex row, sitting immediately next to
    the record as part of the centered group instead of being pinned to
    an edge.
32. Removed the explanatory subtitle line under the title ("Champion
    (top, name in team's secondary color)...") and the data-source
    disclaimer footnote at the bottom of the page, plus their associated
    CSS (`.subtitle`, `.footnote`, and their print-media overrides), per
    request to simplify the page.

## Open items / things to revisit if asked
- Baltimore Bullets (1948 vs 1963 franchise) cumulative-count merge — see
  item 17 above.
- 2026 NFL season champion not yet added (season still in progress as of
  this writing; add once Super Bowl LXI is played, Feb 2027).
- Historical team colors are current-era brand colors, not period-accurate
  for relocated/renamed teams — acceptable simplification per earlier
  discussion, but flagged in README as a caveat.

33. Two small fixes: (1) NFL season records with zero ties (e.g.
    "14-3-0") now display as just "14-3" via a new `Format-NflRecord`
    helper in `build.ps1` -- only applied to the NFL column, and only
    strips the trailing `-0`; a genuine tie (e.g. "11-1-2") still shows
    all three numbers. (2) Replaced the NHL header's 🏒 emoji, which
    rendered as noticeably cartoonish, with a minimal inline SVG (two
    thin `currentColor` lines for the stick, a small filled ellipse for
    the puck) sized via `1em` so it scales consistently with the other
    three emoji sport icons without needing separate print-size rules.
34. Moved `.score` out of the centered flex row entirely and made it
    `position: absolute; bottom: 1px; left: 3px` (mirroring `.sbline`'s
    `bottom: 1px; right: 3px`), so the runner-up row ("def. [team]
    [record]") centers purely on its own content again, with the score
    sitting in the bottom-left corner -- opposite the Super Bowl numeral
    in the bottom-right for NFL cells.
