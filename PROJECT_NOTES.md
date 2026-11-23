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

**PDF generation is PAUSED as of Nov 2026** (explicit user request): only run
`.\build.ps1` after HTML/CSS changes. Do NOT run `.\build_pdf.ps1` unless the
user explicitly asks for it again -- they're iterating on the HTML/CSS and
don't want to spend time keeping both outputs in sync until they're satisfied
with the on-screen version. Re-enable once they say so (and note it here).


## Data coverage as of now
MLB 1903–2026, NFL 1920–2025, NHL 1915–2026, NBA 1947–2026. All four
leagues' 2026-labeled seasons (which conclude mid-year for NHL/NBA, and
represent the 2025 NFL season via the Feb 2026 Super Bowl) have been
added as of Oct 2026 using Wikipedia's season-specific articles rather
than the general "list of champions" pages (which were still correct for
these years, confirming the data). The 2026 NFL season itself is still
in progress as of this writing and has not been added (Super Bowl LXI
would be Feb 2027).

## Agent workflow tips (read before bulk-editing data files)

- **GitHub access**: there is no `gh` CLI and no `GITHUB_TOKEN`/`GH_TOKEN`
  in this sandbox as of Nov 2026. To read issues/PRs, hit the public REST
  API directly with the `webfetch` tool, e.g.
  `https://api.github.com/repos/joejohnmurphy/championship-chart/issues?state=open`.
  Posting comments/edits back requires auth that isn't available here --
  don't assume it works; surface the limitation and give the user
  ready-to-paste comment text instead. Check again each session in case
  this has since been set up (`where.exe gh`, `$env:GITHUB_TOKEN`).
- **Bulk color/text edits across the `.txt` data files**: do NOT blind
  find-and-replace on a hex color value alone -- the same color is
  frequently reused by multiple unrelated teams in the same file (e.g.
  `#006BB6` was both the Knicks' and 76ers' blue in `nba.txt`, `#27251F`
  was both the Pirates' and White Sox's black in `mlb.txt`). A plain
  replace would silently corrupt the wrong teams. But don't swing to the
  other extreme either (fixing one line at a time via the `Edit` tool in
  a dozen separate round-trips, which is slow and burns tokens). Instead,
  anchor the replacement to the **team name on the same line** and do it
  in one bulk pass per file/team, e.g.:
  ```powershell
  (Get-Content nba.txt) -replace '(Detroit Pistons\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|)#C8102E', '${1}#1D42BA' | Set-Content nba.txt
  ```
  This is the pattern to default to for any future "change team X's
  color everywhere it appears" request.

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
35. **Worked two GitHub issues** (repo: `joejohnmurphy/championship-chart`).
    No `gh` CLI or `GITHUB_TOKEN`/`GH_TOKEN` is available in this sandbox,
    so issues were read via the public REST API (`api.github.com/repos/...
    /issues`) through the webfetch tool, and comments could not be posted
    back automatically -- see note at the end of this entry.
    - **Issue #1 "trophy size and location"**: Reworked the champion row's
      HTML structure in `build.ps1`'s `Build-Cell`: the trophy emoji and
      its `.titlecount` (cumulative-championships superscript) used to
      sit at the very start of the line, in front of the team name, with
      the titlecount actually nested *inside* `.champ` next to the name.
      Moved both out to a new trailing `<span class="trophy-wrap">` that
      comes **after** the win-loss record, so the visual order is now
      [TEAM NAME] [record] 🏆⁽count⁾. `.trophy-wrap` is a small
      `inline-flex` with its own `gap: 1px` so trophy and count sit close
      but don't touch -- replaces the old `.trophy { margin-right: -5px }`
      hack (which had pulled the trophy backwards into the team name).
      Trophy font-size reduced 10px&rarr;8px (print 7px&rarr;6px).
      `.titlecount` detached from `.champ` entirely: now its own sibling
      span, colored gold (`#d4af00`) with a dark `text-shadow` to match
      the trophy's color instead of inheriting the team's name color, and
      sized down slightly (8px&rarr;7px, print 6px&rarr;5.5px). Added
      `.result-line + .result-line { margin-top: 2px }` (1px in print) so
      there's a small explicit gap between the champion row and the
      runner-up row, which previously had zero margin between them.
    - **Issue #2 "update colors"**: Fixed four team color pairs that the
      user flagged as wrong, in all cases by swapping which color was
      stored as the cell-fill (`primary`, in the league `.txt` files) vs.
      the name-text/border accent (`secondary`, in `secondary.txt`):
      - **Pistons** (both "Detroit Pistons" and the old "Fort Wayne
        Pistons" entries): primary flipped from red `#C8102E` to blue
        `#1D42BA`; secondary flipped from blue `#1D42BA` to red
        `#C8102E`. Touched every `nba.txt` row where Pistons appear as
        either champion or runner-up (1955, 1956, 1988, 1989, 1990, 2004,
        2005).
      - **Knicks**: primary changed from `#006BB6` to the requested
        `#1D428A` (every Knicks row: 1951, 1952, 1953, 1970, 1972, 1973,
        1994, 1999, 2026) -- careful to *not* touch the Philadelphia/
        Golden State 76ers-or-Warriors rows that happened to share the
        old `#006BB6`/`#1D428A` values, since those are different teams.
        Secondary (`#F58426`, orange) was already correct, left alone.
      - **Steelers**: primary/secondary swapped so the cell background is
        now black (`#101820`, was the old secondary) and the name text/
        border is gold (`#FFB612`, was the old primary) -- i.e. "yellow
        font on black background" as requested. Updated all 8 `nfl.txt`
        rows where Steelers appear as champion or runner-up.
      - **Pirates**: primary/secondary swapped the other direction --
        background is now yellow/gold (`#FDB827`, was the old secondary)
        and the name text is black (`#27251F`, was the old primary), i.e.
        "black font on yellow background". This **reverses** the swap
        done back in entry 14 of this changelog (which had made black the
        primary) -- noted here in case of confusion if revisited again;
        this is an explicit, deliberate user request to go back the other
        way. Updated all 6 `mlb.txt` rows where Pirates appear as
        champion or runner-up (1903, 1909, 1925, 1927, 1960, 1971, 1979).
      Ran `build.ps1` + `build_pdf.ps1` after all changes to confirm no
      errors and spot-checked the generated HTML for all four teams'
      correct colors and the new trophy/score layout.
    - **Follow-up needed**: since there's no `gh`/token in this
      environment, the work done for issues #1 and #2 was *not* posted
      back as GitHub comments. If asked to comment on these issues in a
      future session, check first whether `gh` or a token is available;
      if not, surface this limitation to the user again rather than
      assuming it's been fixed.
36. **PDF generation paused** per explicit user request -- see the
    "Regenerating" section above. Only `.\build.ps1` should be run going
    forward until the user says otherwise; do not run `.\build_pdf.ps1`
    "just to keep it in sync."
    Also fixed vertical alignment of the trophy/title-count: `.trophy-wrap`
    (added in entry 35's issue #1 fix) was using `align-items: baseline`,
    inherited from the parent `.result-line`'s own `baseline` alignment --
    the trophy emoji's font metrics don't share a text baseline with the
    adjacent `.recline-champ` record text the way normal glyphs do, so it
    visually floated above/below the record instead of looking like part
    of the same line. Changed `.trophy-wrap` to `align-items: center` plus
    `align-self: center` (overriding the baseline alignment it would
    otherwise inherit from `.result-line`), so the trophy+count now sit
    vertically centered against the record on the champion's row.
37. **Trophy readability on gold backgrounds + full vertical centering.**
    Two related fixes, both in `build.ps1`/`template.html`:
    - The 🏆 emoji is a fixed-color emoji glyph -- its gold/yellow fill
      can't be recolored via CSS `color`, so on a gold-ish team background
      (e.g. Pittsburgh Pirates' `#FDB827`) the icon nearly disappeared.
      Replaced the emoji with an inline SVG trophy (Material Design's
      `emoji_events` glyph path, `fill="currentColor"`) so its color is
      now fully controllable via CSS, the same approach already used for
      the NHL header's hockey-stick-and-puck icon. Added
      `Test-IsGoldish($hex)` in `build.ps1` (HSL-based: hue 35-65,
      saturation &ge;0.25, lightness 0.35-0.88) to flag backgrounds close
      to the trophy's own gold. When true, both the trophy SVG and the
      `.titlecount` number switch to dark (`#1a1a1a`) with a light
      text-shadow instead of the default gold (`#FFD700`) with a dark
      text-shadow -- computed once per cell and applied via inline
      `style` (not hardcoded in the stylesheet), same pattern as the
      existing `Get-LegibleColor`/`$champOutline` adaptive-contrast logic.
      Verified: Pittsburgh Pirates rows (gold bg) now render a dark
      trophy+number; every other team keeps the standard gold.
    - **"Center the winner's record vertically with the name/trophy"**:
      the root cause was `.result-line`'s own `align-items: baseline` --
      changed to `align-items: center`, so `.champ` (name), `.recline-champ`
      (record), and `.trophy-wrap` (trophy+count) are all now centered on
      the same flex cross-axis instead of baseline-aligned (which had put
      the record and trophy at slightly different vertical offsets than
      the name due to differing font-sizes/metrics). This change applies
      to both the champion and runner-up rows since they share the
      `.result-line` class; no issues observed on the runner-up row from
      the switch. The now-redundant `align-self: center` override added to
      `.trophy-wrap` in entry 36 was removed since the parent itself
      centers by default now.
    - `.trophy` CSS switched from `font-size`/`line-height` (emoji-era) to
      `width`/`height` in `em` units (SVG-era) so it scales with the cell's
      font-size like the emoji did; sized up again in entry 38 below after
      the shape itself was simplified.
    - **This entry's fix was wrong and had to be corrected in entry 38 --
      see that entry for what actually went wrong and how it was diagnosed
      with real screenshots.** Left here unedited for the historical
      record of what was tried.
38. **Entry 37 made things visibly worse; user called it out directly and
    asked whether this was beyond the model's ability.** Root cause of
    both problems: entry 37 was written *blind* -- CSS/SVG changes were
    made and declared correct purely by reasoning about markup, without
    ever actually rendering and looking at the page. Two concrete bugs
    resulted:
    - The Material Design `emoji_events` SVG path (fine multi-curve detail,
      designed for icon-font sizes ~16-24px) turned to an illegible yellow
      sliver at the ~7-8px this project renders trophies at -- thin
      curves/negative-space handles just don't survive that much
      downscaling. **Fix**: replaced it with a deliberately crude, bold
      geometric shape built from a `<polygon>` (trapezoid cup) + two
      `<rect>`s (stem, base) instead of a detailed path -- straight edges
      with no fine curves hold up far better at tiny render sizes.
    - `.titlecount` still had a leftover `vertical-align: super` rule from
      the pre-entry-35 design (when the count sat superscript next to the
      team name, inside running text). After entry 35 moved it into the
      flex-based `.trophy-wrap`, that rule should have been deleted but
      wasn't, and it was in fact still shifting the number upward despite
      being inside a flex container (where `vertical-align` is supposed
      to be ignored per spec) -- removed it along with adding explicit
      `line-height: 1` on `.trophy-wrap`/`.titlecount` so there's no
      residual inherited line-height (1.15 from `.result-line`) inflating
      the box and throwing off the centering.
    - **Process fix, not a model-capability fix**: diagnosed and verified
      both of the above using real headless-Chrome screenshots instead of
      reasoning about CSS blind -- `build_pdf.ps1` already proved headless
      Chrome is available in this environment; the same
      `--headless=new --screenshot=out.png <file-uri>` flags capture a
      PNG instead of a PDF. Cropped/zoomed the PNG with .NET
      `System.Drawing` (nearest-neighbor interpolation to avoid blurring
      away the exact pixel-level detail being judged) and viewed it with
      the `Read` tool, which supports images. Confirmed the fix visually
      (trophy now a recognizable cup shape, number sits level with the
      win-loss record) before reporting it as done, including a
      standalone isolated-snippet screenshot specifically to re-verify
      the gold-background dark-trophy contrast case from entry 37 still
      works with the new shape.
    - **Going forward**: for any future change to icon shapes, pixel-level
      alignment, color contrast, or anything else where "does this look
      right" can't be answered by reading markup/CSS alone, take a
      screenshot with headless Chrome and actually look at it (crop/zoom
      with .NET `System.Drawing` as needed) *before* declaring the work
      done. Don't re-introduce the blind-CSS-guessing pattern this entry
      had to clean up after.
39. **Entry 38's screenshot-verified SVG fix still wasn't good enough --
    user said the trophy looked *even worse* than entry 37's, the
    vertical alignment was still inconsistent, and asked directly whether
    this was beyond the model's ability.** Correct response was not to
    defend the previous approach but to go back further and actually find
    what the user meant by "the one we had at the start of this session"
    -- the original 🏆 **emoji**, not any SVG replacement. Two real fixes,
    both screenshot-verified before/after this time (including a small
    isolated-snippet test harness built from the live `<style>` block, to
    iterate fast without a full rebuild each time):
    - **Reverted the SVG entirely back to the plain `&#127942;` emoji
      character.** The polygon-cup SVG from entry 38 was a worse
      *design*, not just unreadable at tiny size like the Material icon
      in entry 37 -- it just doesn't read as "trophy," independent of
      size/alignment. Confirmed via screenshot test that a `filter:
      drop-shadow(...)` (not `text-shadow`, which color emoji silently
      ignore) *does* add a visible dark outline around an emoji glyph
      without altering its native colors -- this is the real answer to
      "alter the color of the trophy...so it's readable" on a gold
      background: you can't recolor an emoji's fill, but you can outline
      it. Used two stacked `drop-shadow()`s for a thicker outline, applied
      only when `Test-IsGoldish` is true (same helper as before); the
      `.titlecount` number, being plain text, still gets the dark-color
      swap as before since that part always worked correctly.
    - **Found the actual root cause of the vertical misalignment**: it
      was never `vertical-align` or `align-items` on the outer row --
      wrapping the trophy and count together in their own nested
      `display: inline-flex` (`.trophy-wrap`, added back in entry 35) was
      the bug. Color emoji glyphs carry unusually tall internal font
      metrics/bounding boxes baked into the font itself; once that glyph
      became one of only two flex items in its own small flex container,
      `align-items: center` centered the *titlecount* against the
      *emoji's* oversized box rather than against the row's actual text,
      so the number rode high and inconsistently depending on exact
      glyph/digit-count combinations. **Fix**: removed `.trophy-wrap`
      entirely. `.trophy` (the emoji) and `.titlecount` (the number) are
      now direct siblings of `.champ`/`.recline-champ` as plain children
      of `.result-line`, so all four are centered against the same
      reference frame (the row's own flex cross-axis, dominated by the
      11px `.champ` text) instead of two different nested ones. Spacing
      between the trophy and its count is now a small negative
      `margin-right: -3px` on `.trophy` (pulling them close) rather than
      a `gap` value scoped to a wrapper that no longer exists.
    - Verified with real screenshots at multiple zoom levels across many
      rows (1-digit and 2-digit counts, light and dark backgrounds, the
      gold Pirates case specifically) before responding -- not just one
      row in isolation, since entry 38's mistake was declaring victory
      off a single clean-looking example.
40. **Entry 39's alignment still wasn't right everywhere; user pointed at
    NFL 1991 (Washington Redskins) specifically and, reasonably, asked
    why they had to keep flagging individual rows instead of this getting
    caught across the board.** What actually happened on investigation,
    screenshot-verified at each step:
    - First reproduced the *reported* row in isolation and it looked
      basically fine -- which was a signal to distrust the original
      "evidence" rather than conclude there was no bug. Went back and
      re-cropped the full-page screenshot from entry 39's own verification
      pass with a larger, more careful crop window and found the earlier
      crop had been sloppy: a too-short/misaligned crop rectangle had
      visually spliced together content from two adjacent table rows,
      making an actually-minor offset look like a dramatic one. Lesson
      for future screenshot-based verification: always crop generously
      and double-check the crop boundary lands cleanly between rows, or a
      wrong diagnosis gets chased instead of the real one.
    - The **real** bug, once isolated correctly: the trophy emoji and its
      count sat a small but consistent amount lower than the adjacent
      win-loss record text, in *every* row, in *every* column -- not
      unique to NFL or to 1991. This is the color emoji's own internal
      font-metric padding (same root cause identified in entry 39, just
      with a smaller visible magnitude than first appeared) pulling the
      glyph's visual center down relative to plain Latin text, even
      though both are nominally flex-centered on the same baseline.
      **Fix**: added `position: relative; top: -1px;` to both `.trophy`
      and `.titlecount` in `template.html` -- a small universal upward
      nudge that compensates for the emoji's own metrics without
      reintroducing any nested flex container. Chosen by testing several
      offsets (`-0.5px`, `-1px`) in an isolated multi-row harness across
      a deliberately varied sample (long/short team names, 1- and 2-digit
      counts, multiple leagues) before touching the real files, then
      re-verified on the actual rebuilt `championship_chart.html` across
      ~20 rows spanning all four leagues in one combined screenshot crop
      -- not just the one row the user mentioned -- specifically because
      the user's complaint was about a *systemic* gap in verification,
      not just one bad row. Print-media CSS needed no separate override
      since it only changes `.titlecount`'s `font-size`, not its
      `position`/`top`, so the nudge applies there too automatically.
    - **Process note for future sessions**: "fixed and verified" claims
      in this project now require (a) a screenshot of the actual rebuilt
      `championship_chart.html`, not an isolated snippet only, and (b) a
      crop wide/tall enough to unambiguously show full rows with margin
      on all sides -- a tight crop that might be bisecting two rows is
      worse than no crop at all, because it produces false confidence in
      either direction.
41. **Four-part request, all screenshot-verified before/after**: more
    padding around the winner/loser rows, a shorter title, bigger
    on-screen default text (no browser zoom needed), and a cleanup of the
    "fuzzy/muddy" text shadows especially visible on light backgrounds.
    - **Padding**: bumped base `td` padding from `2px 5px` to `7px 9px`
      (the `@media print` block already explicitly overrides `td`
      padding to its own fixed `2px 3px`, so this doesn't touch the
      paused print output at all). Since `td` padding wraps the whole
      two-row stack (champion row + runner-up row) and `vertical-align:
      middle` centers that stack in the cell, increasing it adds space
      above the first (winner) row and below the second (loser) row
      exactly as asked, without changing the gap *between* the two rows
      (that's the separate `.result-line + .result-line` margin-top,
      untouched in spirit though bumped slightly as part of the general
      scale-up below).
    - **Title**: `<h1>` text shortened from "Champions of the Big Four —
      MLB &middot; NFL &middot; NHL &middot; NBA" to just "Champions of
      the Big Four", since the league names/trophy names are already in
      each column's `<th>`. The `<title>` tag (browser tab text) was left
      untouched since it isn't rendered on the page and wasn't part of
      what the user was looking at.
    - **Overall readability scale-up**: this was the biggest change.
      Audited every `@media print` rule first to confirm which base
      properties it already overrides (font-size on nearly everything,
      plus `td`/`th` padding and both `col` widths) -- then significantly
      enlarged the *base* (screen) values for fonts, column widths,
      padding, and spacing throughout `template.html`, relying on the
      existing print overrides to keep the paused PDF output exactly as
      it was (verified print wasn't touched by re-reading the print block
      after, not just assuming). Roughly a 1.3-1.4x scale across the
      board: `col.sport-col` 260px&rarr;345px, `col.year-col`
      48px&rarr;66px, `.champ` 11px&rarr;14px, `th` 15px&rarr;20px, `td`
      9px&rarr;12px, `h1` 34px&rarr;42px, body padding 8px&rarr;16px, and
      so on for every other text element (`.runner`, `.score`,
      `.def-label`, `.recline-champ`/`.recline-runner`, `.sbline`,
      `.trophy`, `.titlecount`). **One gap found and closed**: `.score`'s
      padding/margin-left had no existing print override (only its
      font-size did), so enlarging it in the base rule would have leaked
      into the print output -- added an explicit `.score { padding:...;
      margin-left:... }` override inside `@media print` restoring the
      old small values, and did the same for `.trophy`'s `margin-right`
      and `.sbline`'s `right` offset once noticed they had the identical
      gap. Verified the full-page on-screen render at a realistic laptop
      window size needs no zooming to read comfortably.
    - **Shadow cleanup**: the old approach stacked 2-4 blurred
      `text-shadow` layers (`0 0 2px`, blur radius >0) to fake an outline
      around the champion name, plus a flat always-dark `text-shadow: 0
      1px 1px rgba(0,0,0,0.4)` on the smaller supporting text
      (`.def-label`, `.recline-champ`, `.recline-runner`, `.sbline`)
      regardless of what color that text actually was -- blur is what
      reads as "fuzzy," and a dark shadow under text that's sometimes
      itself dark (e.g. on the Pirates' gold background) is what read as
      "muddy." Replaced both in `build.ps1`:
      - Champion name: swapped the blurred glow for a thin
        `-webkit-text-stroke: 0.5px <opposite-tone>` plus a single
        *zero-blur* `text-shadow: 1px 1px 0 <opposite-tone-rgba>` --
        crisp hard edge instead of a soft halo, same adaptive
        light/dark-outline logic as before (`Get-FG` on the final text
        color) so it still works on any background.
      - Supporting text (`def.`, both win-loss records, the Super Bowl
        numeral): now gets a per-cell `$smallShadow` computed from
        `$champFg` (zero-blur, opposite tone) applied inline, replacing
        the old static always-dark CSS rule. Removed those now-redundant
        `text-shadow` declarations from `template.html` entirely (color
        is still driven by `$champFg`/CSS `opacity` as before, only the
        shadow is new).
      - Trophy count (`.titlecount`): simplified from two duplicated
        identical blurred shadow layers (apparent copy-paste leftover) to
        one zero-blur shadow, keeping the existing gold-background dark
        swap from entry 39/`Test-IsGoldish` unchanged.
      Verified specifically against the Pirates gold-background row
      (the clearest "light background" test case) and a selection of
      dark-background rows side by side -- outline is now a clean hard
      edge on both, no haze.
42. **Follow-up on entry 41's shadow cleanup: user still didn't like it on
    orange/gold/lighter backgrounds specifically, for both the text and
    the trophy.** Investigated with real screenshots rather than guessing
    and found two distinct, compounding problems:
    - The champion-name outline from entry 41 (`-webkit-text-stroke` +
      a 1px-offset zero-blur `text-shadow`, both the same color) looked
      *thicker and blobbier* than intended specifically on saturated warm
      backgrounds (orange especially) -- the stroke and the offset shadow
      visually overlap/compound into a chunky halo rather than a clean
      line. Compared four alternatives (stroke+shadow / stroke-only /
      4-direction solid shadow / darker fill + thinner stroke) side by
      side in an isolated test against San Francisco Giants' actual
      orange (`#FD5A1E`) before picking: **stroke-only, no text-shadow at
      all** (`-webkit-text-stroke: 0.45px <opposite-tone>`) was clearly
      the cleanest -- thin, uniform, no doubled-up thickness in any
      direction.
    - `Test-IsGoldish` (added in entry 39, which decides whether the
      trophy/titlecount flip to a dark contrasting style) had its hue
      range set to 35-65&deg;, tuned only for actual gold/yellow. Real
      team oranges (SF Giants, Denver Broncos, Bengals/Oilers/Flyers,
      etc.) sit at hue ~14-18&deg; -- just outside that window -- so the
      gold trophy emoji and gold titlecount were being left as-is against
      backgrounds that are visually just as hard to read a gold icon
      against as true gold is. **Calibrated properly this time**: wrote
      out the actual HSL hue/saturation/lightness for ~10 real team
      colors from the data files (oranges, golds, a maroon that should
      *stay* excluded, and an aqua that should also stay excluded) using
      the project's own `Rgb-ToHsl` logic, rather than guessing numbers.
      Found oranges/golds cluster tightly at hue 10-41&deg;, saturation
      &ge;0.5, lightness 0.38-0.57, while the maroon that must stay
      excluded sits at lightness ~0.22 and the aqua at hue ~184&deg; --
      comfortably outside that band either way. Widened
      `Test-IsGoldish`'s range to `hue 10-65, saturation >=0.5, lightness
      0.38-0.85` to now catch orange as well as gold without catching
      dark warm colors or cool colors.
      **Hit the exact `@()`-comma-precedence PowerShell bug documented in
      entry 24 again** while writing the one-off calibration script
      (`@($h*360,$s,$l)` parsed wrong) -- same fix as before, wrap each
      term in its own parens. Worth a third mention here since it keeps
      recurring: **any time a comma-separated arithmetic expression is
      built inside `@(...)` in this codebase, wrap every individual term
      in parens**, even in throwaway one-off diagnostic scripts, not just
      the main build files.
    - Verified both fixes together via real screenshots zoomed in on the
      exact previously-bad cells (SF Giants orange, Denver Broncos
      orange) side by side with unaffected dark-background cells (Kansas
      City Royals navy) to confirm no regression -- orange rows now show
      a thin clean name outline plus a dark-outlined trophy and dark
      count, matching the treatment gold cells already had.
43. **User still didn't like the white outline/shadow on light backgrounds
    after entry 42 -- specifically called out San Francisco Giants and
    New Orleans Saints as examples (plural, implying a category, not an
    exhaustive list) and asked for a cleaner alternative to white.**
    Considered and discarded a pure contrast-ratio-based approach first
    (e.g. "skip the outline entirely whenever text-vs-background contrast
    is already >= some ratio") -- computed real ratios for Giants (4.86),
    Saints (9.67), and Denver Broncos (4.75, the original case that
    justified having an outline system at all per entry 25) and found
    Giants and Broncos sit too close together (4.86 vs 4.75) for any
    single numeric threshold to treat one as "needs an outline" and the
    other as "doesn't" the way the user's feedback implied they should
    differ -- the actual distinguishing factor is background *hue/
    warmth*, not raw contrast ratio.
    - **Real fix**: reused `Test-IsGoldish` (already calibrated in entry
      42 for exactly this light/warm-background category, originally
      only for the trophy) as the single source of truth for outline/
      shadow tone everywhere in a cell -- computed once per cell as
      `$champIsLightBg` instead of being called redundantly in multiple
      places with slightly different logic each time (which is how the
      inconsistency crept in originally). When true: champion-name
      outline switches from the old "opposite of the text's own color"
      rule to a flat dark stroke; the supporting text's shadow
      (`$smallShadow`) is forced dark regardless of what `$champFg`'s
      cruder weighted-luminance formula says (it disagreed with the
      perceptual hue-based check for some of these colors); and the
      trophy count's shadow -- found to have the exact same bug in a
      second location, dark count text paired with a *white* shadow on
      light backgrounds -- was switched from white to dark too.
    - **Found one real gap during calibration**: New Orleans Saints' tan
      (`#D3BC8D`) has hue 40.3&deg; (comfortably in range) and lightness
      0.69 (in range), but only *saturation 0.44* -- just under entry 42's
      0.5 floor, so it was slipping through `Test-IsGoldish` entirely and
      still showing the bug even conceptually "fixed" by that entry.
      Lowered the saturation floor to 0.35 and re-ran `Test-IsGoldish`
      against every team color in all four `.txt` files to sanity-check
      the resulting list (Ducks orange, Orioles orange, Broncos orange,
      Oilers orange, a Frankford Yellow Jackets gold, Saints tan, Flyers
      orange, Pirates gold, Vegas Golden Knights tan-gold -- all
      legitimately light/warm, nothing unexpected pulled in).
    - **Design principle worth recording explicitly**: on a light/warm
      background, a dark outline/shadow that happens to closely match an
      already-dark text color (and is therefore barely visible) is
      *correct*, not a bug -- the old system's whole premise (entry 25)
      was that the outline is only load-bearing when it's the thing
      making otherwise-marginal text legible. Once `Get-LegibleColor` has
      already guaranteed a contrast ratio against the background, an
      outline that blends into already-legible text is purely decorative
      and harmless; forcing it to a *different, visible* tone in that
      situation (i.e. white, just to make sure the outline itself is
      visible) is exactly what caused this whole family of complaints.
    - Verified by rebuilding and re-screenshotting the exact previously-bad
      cells (Giants, Saints) plus unrelated dark-background cells (Royals
      navy, Steelers black) side by side to confirm the fix applied only
      where intended.
44. **Entry 43's "always match the background's warmth" logic still
    wasn't it** -- user said the orange cells (Giants) now looked "fat and
    flat" (the uniform dark stroke read as heavy/blobby with nothing
    making the text pop) and Phillies (a vivid red, outside the
    light/warm bucket, so still on the old opposite-of-text-tone path)
    still had the disliked white outline. Rather than guess a fourth
    time, built a **visual comparison sheet**: 7 candidate treatments
    (no decoration / dark stroke / white stroke / soft shadow only /
    stroke-matching-text-color / bold-weight-only / stroke+soft-shadow
    combo) rendered side by side against the three actual problem
    backgrounds (Giants orange, Phillies red, Saints tan), saved as a PNG
    + HTML the user could open themselves
    (`%TEMP%\opencode\shadow_review.png`), and asked them to pick a
    winner instead of me continuing to guess blind. **This worked** --
    much faster resolution than the previous several rounds of
    back-and-forth.
    - **User's verdict, applied as explicit rules** (not a heuristic to
      infer from examples this time, but literal instructions): plain
      text with no decoration ("option 1") looked best overall. On top of
      that: (a) the winner's name must **never render in literal black**;
      (b) the outline is **always solid black**, unconditionally, with no
      light/dark branching by background; (c) if the name's computed
      color would have been black, lighten it (not just swap to a
      different hue) so it's a "lighter black" rather than a flat gray
      substitution; (d) **all text-shadows, everywhere in the project,
      removed** -- not just the champion name's, all of them.
    - **Implementation in `build.ps1`**: `$champNameColor` now gets a
      post-process check -- `Get-RelLuminance $champNameColor -lt 0.03`
      (i.e. it's effectively black) triggers `Set-Lightness $champNameColor
      0.20`, which preserves the color's own hue while lifting its
      lightness, rather than flattening to a generic gray. (Concretely:
      Philadelphia Phillies' near-black `#00040A` -- which has a faint
      blue cast -- became a clean navy `#002966` instead of a neutral
      gray, which reads as more "on-brand" for a team whose real secondary
      color is navy.) `$champOutline` collapsed to a single unconditional
      line: `-webkit-text-stroke:0.45px #000` -- no branching, no
      shadow, same on every single cell. All the per-cell `$smallShadow`
      /`text-shadow` logic for `.recline-champ`, `.recline-runner`,
      `.def-label`, `.sbline`, and `.titlecount` was deleted outright
      (those elements now just carry color, nothing else). The `h1`
      title's own subtle `text-shadow` in `template.html` was removed
      too, since the instruction was "anywhere," not just the data cells.
      The trophy emoji's `filter: drop-shadow(...)` on light/warm
      backgrounds was deliberately **kept** -- it's a shadow on a
      pictographic icon glyph, not on text, and it's the only mechanism
      available to add contrast to a fixed-color emoji (CSS `color` can't
      recolor it, unlike real text).
    - Verified post-rebuild on Giants, Saints, and Phillies specifically
      (Phillies' champion-name color is confirmed hue-preserving-lightened
      from `#00040A` to `#002966`, with the now-unconditional black
      stroke and zero shadow) plus a general sweep of ~20 rows across all
      four leagues for consistency. Ran a `Select-String` check for the
      literal string `text-shadow` across the generated
      `championship_chart.html` afterward and confirmed zero matches.
45. **Five more targeted fixes**, all screenshot-verified against the
    actual rebuilt file before/after:
    - **Trophy count font**: `.titlecount` had no `font-family` set, so it
      was silently inheriting `body`'s decorative `Georgia` serif --
      exactly the kind of font the user suspected was behind the
      persistent vertical-alignment inconsistency (serif numerals,
      especially in a display serif like Georgia, don't have the
      uniform, tabular digit height/baseline that sans-serif fonts like
      Arial do). Set `.titlecount { font-family: Arial, Helvetica,
      sans-serif; }` explicitly.
    - **Runner (loser) pill depth without a shadow**: removed `.runner`'s
      `box-shadow` entirely (both the drop-shadow and the inset
      highlight) and replaced the uniform `border: 1.5px solid` with
      asymmetric `border-width: 1px 3px 3px 1px` (thin top/left, thick
      bottom/right) on the same `border-style: solid`. This fakes a
      "cast down-and-right" depth cue using only border geometry, no
      shadow primitive at all. Border *color* is still set per-cell via
      the existing inline `border-color` style, unaffected by this
      change. Print media given a proportionally thinner override
      (`1px 2px 2px 1px`).
    - **Column headers**: removed the en dash between the sport name and
      championship name (e.g. "MLB &ndash; World Series") and moved the
      sport emoji into that gap instead (`MLB &#9918; World Series`).
      `.sport-icon`'s CSS changed from `margin-right` only (appropriate
      when the icon led the line) to `margin: 0 5px` (appropriate now
      that it's sandwiched between two text segments).
    - **Oklahoma City Thunder's font too dark**: root cause was a gap in
      the contrast-search logic (see entry below) -- Thunder's orange
      secondary (`#EF3B24`) against their own blue primary (`#007AC1`)
      turns out to be a genuinely hard pair: neither lightening nor
      darkening that exact orange hue/saturation ever clears a 4.5
      contrast ratio before hitting the search bounds (best case in
      either direction tops out around ratio 4.3-4.46, under the bar).
      The existing "never literal black" safety net (entry 44) would
      nudge the near-black fallback back up slightly, landing on a muddy
      dark brown (`#5C140A`, actual measured ratio only 2.92 -- quite
      poor). **Fix**: added a second safety net in `build.ps1` *after*
      the lighten-if-black step -- if the final color's contrast ratio
      is still under 4.0, abandon hue preservation entirely and fall
      back to whichever of plain white or a "lighter black" (`#2b2b2b`,
      never literal black, consistent with entry 44's rule) contrasts
      better against the background. For Thunder this now resolves to
      plain white (ratio 4.61) instead of the illegible dark brown.
    - **The "pink" names (Cubs, Astros, Patriots, etc.) -- the actual
      root cause, not a band-aid**: found and fixed a real bug in
      `Get-LegibleColor`. It was testing a small set of *extreme* preset
      lightness values (`0.90, 0.95, 0.98, 0.10, 0.05, 0.02`) in a fixed
      order and returning the **first** one that cleared the minimum
      ratio -- for saturated reds especially, this means grabbing
      `L=0.90` immediately (since it's tried first) even when a much
      smaller nudge (e.g. `L=0.60-0.65`) would have cleared the exact
      same bar with a far richer, less washed-out result. Rewrote the
      function to walk outward from the color's *own* starting lightness
      in small `0.02` increments, in both directions, and pick whichever
      direction clears the minimum ratio in the *fewest* steps (i.e. the
      smallest possible change from the original color) rather than
      jumping to a preset extreme. Confirmed via direct calculation
      before implementing: Patriots red `#C60C30` only needs `L&asymp;0.60`
      to clear 4.75 ratio against navy, not the `L=0.90` (`#FCCFD8`,
      ratio 11.47 -- wildly overshooting) the old code produced.
      Real measured results after the fix: Patriots `#C60C30` &rarr;
      `#F44E6E` (rich crimson, was pale pink `#FCCFD8`), Astros
      `#EB6E1F` &rarr; `#EC762B` (vivid orange, was pale peach `#FBE1D0`),
      Cubs `#CC3433` &rarr; `#E28D8D` (coral/salmon, was washed pink
      `#F5D6D6`). Also had to delete a chunk of now-orphaned dead code
      left over from the previous version of the function (the new
      implementation was written as a full replacement but the editor
      tool only matched part of the old body, leaving dangling
      close-braces and a second `return $bestHex` -- caught by reading
      the file back afterward, not by the build succeeding, since
      PowerShell happily parsed the orphaned fragment as dead code after
      the real `return`).
    - Verified all five together: titlecount digits now consistently
      level with the trophy and record across a sweep of rows regardless
      of digit count; runner pills show a visible asymmetric
      bottom-right-weighted border with no blurred shadow; column headers
      read "MLB &#9918; WORLD SERIES" with no dash; Thunder renders in
      plain legible white; Cubs/Astros/Patriots all read as saturated,
      recognizably-colored team names rather than pastel pink/peach.
46. **Worked GitHub issue #3 "cosmetic issues"** (11 items). No `gh`/token
    available in this sandbox (checked again, still absent) -- read via the
    public REST API through webfetch, same as issues #1/#2 in entry 35.
    Comment-ready summary text was handed to the user directly rather than
    posted. All changes screenshot-verified (headless Edge +
    `System.Drawing` crop/zoom) before/after, per the process rule from
    entries 38/40.
    - **Root-caused and fixed the recurring "pink" team names for good**
      (items 3/4/5/11: Chiefs, Pistons, Patriots, Cubs). The real problem
      wasn't `Get-LegibleColor`'s search strategy (already fixed in entry
      45) -- it was the minimum-contrast-ratio bar itself. A direct
      side-by-side screenshot test (literal unadjusted Pistons red
      `#C8102E` on their blue, raw contrast ratio only ~1.4, vs. two
      algorithmically-adjusted versions) showed the **literal color with
      just the existing black text-stroke outline looked best of the
      three** -- the stroke was already doing the legibility work, making
      the contrast-ratio adjustment counterproductive busywork that only
      ever made colors worse (washed toward pink/pastel) without a
      visible legibility benefit. Replaced the old inline contrast logic
      in `Build-Cell` with a new `Get-ChampNameColor` function and dropped
      the minimum ratio from 4.5 (then briefly tested at 3.2) down to
      **2.0** -- low enough that most previously-"fixed" team colors now
      render as their literal, unmodified secondary color (Chiefs gold
      `#FFB81C`, Patriots red `#C60C30`, Cubs red `#CC3433` all pass
      through untouched), with the lightness-walk adjustment only
      kicking in for genuinely low-contrast pairs like Pistons
      (`#C8102E` on `#1D42BA`, raw ratio 1.4) where it now lands on a much
      more vivid true red (`#EF3150`) instead of the old washed salmon/
      pink. Re-ran the full-dataset scan afterward (every champion across
      all 4 leagues) to confirm no team was left with a literal illegible
      pairing -- worst cases (e.g. Vegas Golden Knights' tan-on-tan) still
      get nudged, just less aggressively.
    - Added a parallel small fix (item 6) for the opposite problem: a
      secondary color that already clears the (now much lower) bar but is
      still quite dark (e.g. a black secondary on an orange background,
      SF Giants/Broncos/Oilers) now gets a gentle lightness bump (+0.22,
      only if it doesn't tank the contrast below 1.6) purely for a softer
      look, since passing colors were previously left completely
      untouched even when borderline-black.
    - **Item 10 (trophy "shading" on light/gold backgrounds not working)**:
      root cause was a blurred `filter: drop-shadow(...)` on a tiny
      (~8px) color-emoji glyph -- at that render size the blur completely
      destroyed the trophy's shape, turning it into an unrecognizable
      blob/medal-like smear (confirmed via zoomed screenshot, e.g. the
      2009 New Orleans Saints row). Replaced with a zero-blur,
      8-directional 1px-offset `text-shadow` (the classic hard-edge
      "pixel outline" trick) -- this traces the glyph's actual alpha
      shape instead of blurring it, so the trophy reads as a trophy with
      a crisp dark edge, same as the already-working champion-name
      outline technique elsewhere in the project.
    - **Item 1 (runner-up "shadow" box not reading as a shadow)**: built a
      5-option visual comparison sheet (saved to
      `%TEMP%\opencode\runner_review.png`, current/asymmetric-border vs.
      thin-border-plus-soft-shadow vs. double-ring-inset vs.
      bottom-accent-bar vs. pressed-tab-gradient) and picked "double-ring
      inset" -- a thin solid border plus a `box-shadow: 0 0 0 2px
      rgba(255,255,255,0.55)` halo -- as the cleanest/most "artistic"
      option without a heavy border or a smeared shadow. Replaces the
      asymmetric `border-width: 1px 3px 3px 1px` from entry 45 entirely
      (both the base and `@media print` rules).
    - **Item 2 ("A" in Anaheim Ducks cut off on the left)**: root cause is
      a known flexbox quirk -- a flex item with `overflow:hidden;
      white-space:nowrap` sitting inside a `justify-content:center`
      parent gets clipped symmetrically from *both* sides once it's
      wider than the available space, not just truncated with an
      ellipsis on the right, so sufficiently long/wide names can lose
      their first letter(s) before any ellipsis would show (window-width
      dependent -- didn't reproduce at this session's 1600px test width,
      but the mechanism is real and will bite at narrower widths). Fixed
      by adding `text-align: left` to both `.champ` and `.runner`, which
      makes `text-overflow: ellipsis` truncate consistently from the
      right only, regardless of viewport width.
    - **Item 7** ("Ottawa Senators (orig.)" clunky): renamed to "Ottawa
      Senators (I)" in both `nhl.txt` and `secondary.txt` (bulk
      find-replace, not touching the current-day "Ottawa Senators" entry)
      -- brief, reads naturally as "the first Senators" without the
      awkward parenthetical word.
    - **Item 8** (NFL scores missing for 1931 and earlier): investigated
      via Wikipedia's "History of the NFL championship" article --
      **not a bug**. The NFL had no championship game at all from
      1920-1932; the champion was simply whoever had the best season
      record (first-ever playoff game was 1932, 9-0, and that score is
      already in the data). There is no score to add for 1920-1931
      because no such game was ever played -- explained this to the user
      rather than fabricating a number.
    - **Item 9** (sport emoji in column headers not vertically centered
      with the header text): the plain emoji glyphs (baseball/football/
      basketball) sit slightly high relative to the bold Arial header
      text's baseline, confirmed via zoomed screenshot. Added
      `position: relative; top: 2px;` to `.sport-icon` (same
      metrics-compensation trick already used for `.trophy`/
      `.titlecount` since entry 40). The NHL icon (already a custom SVG,
      not an emoji) didn't need this and was unaffected.
    - Also updated `build.ps1`'s `New-ChampNameColor`-adjacent comments to
      reflect the new 2.0 threshold and the reasoning above, so a future
      session doesn't see "4.5" or "3.2" in old comments and get confused
      about which number is actually live.
    - Ran `.\build.ps1` only, per the PDF-paused standing rule -- did not
      touch `.\build_pdf.ps1` or `championship_chart.pdf`.
47. **Follow-up on item 8 from entry 46**: user asked why a "loser" is
    listed at all for 1920-1931 NFL rows if there was no championship
    game. Answer: the second team on those rows is accurate data (the
    actual second-place-by-record team that season), but the word
    `"def."` ("defeated") printed in front of it was misleading -- nobody
    defeated anybody in a game those years. Rather than removing the
    second-place team entirely (which the user first floated, then
    reconsidered), the fix is just a label swap: `Build-Cell` in
    `build.ps1` now computes `$defLabel` conditionally -- `"def."` for
    every row except NFL years before 1932, which get `"2nd place:"`
    instead (1932 onward keeps `"def."` since that's when the actual
    first playoff game started). No changes to `nfl.txt` or CSS needed;
    `"2nd place:"` fits fine in the existing `.def-label` flex slot at the
    same font-size. Verified via screenshot across the full 1913-1932
    range: "2nd place:" reads cleanly beside the runner-up pill from 1920
    through 1931, and 1932's Portsmouth Spartans row (the real first
    playoff game) correctly still shows "def."
48. **Second follow-up on the same 1920-1931 NFL rows**: the oval score
    pill (normally "4-2"-style for MLB/NHL/NBA or "24-14"-style for NFL)
    was still appearing on these rows even after entry 47's label fix --
    since there's no game, `$champGames`/`$runnerGames` are blank in
    `nfl.txt` for those years, so the pill was rendering as a bare,
    meaningless "-" oval. Added a `$showScore` flag in `Build-Cell`
    (false only for `$league -eq 'nfl' -and $year -lt 1932`) and wrapped
    the `.score` span in a conditional `$scoreSpan` variable that's empty
    for those rows, so the pill is omitted entirely rather than showing a
    placeholder dash. Every other row/league unaffected. Verified via
    screenshot across 1913-1932: no score oval on 1920-1931 NFL rows, oval
    still present everywhere else including 1932 onward.
49. **Named-team "too dark" font fix**: user listed 13 specific teams
    whose champion name text still read as too dark despite already
    clearing `Get-ChampNameColor`'s legibility bar: Texas Rangers,
    Washington Nationals, Boston Red Sox, San Francisco Giants, St. Louis
    Cardinals, Philadelphia Phillies, Cincinnati Reds, Baltimore Ravens,
    Dallas Cowboys, Miami Dolphins, New York Jets, Chicago Cardinals, and
    Tampa Bay Lightning. This is a pure cosmetic preference, not a
    legibility failure, so rather than touching the shared contrast
    algorithm (and risking regressing teams that weren't mentioned), added
    a small, explicit `$softenTeams` lookup table in `build.ps1` plus a
    `Soften-TextColor` helper applied only to those named teams after the
    normal color pipeline runs:
    - For teams whose secondary is a real hue (the navy/red teams above),
      nudges HSL lightness up by a flat `+0.16` (keeps hue/saturation, so
      navy stays recognizably navy, just a lighter shade of it) -- no
      contrast-ratio floor gating this, unlike every other color function
      in the project, since this is an explicit "I know it's less
      contrasty, I want it lighter anyway" request, trusting the
      always-on black text-stroke outline to carry legibility.
    - For teams whose secondary is literal black (Ravens, Jets, Chicago
      Cardinals, Tampa Bay Lightning -- black has no hue/saturation, so a
      small lightness delta barely moves it, confirmed via screenshot that
      `+0.16` on black was still nearly unreadable against dark
      backgrounds like the Jets' dark green), uses a fixed mid-gray
      `#767676` instead of the delta math.
    - Verified every one of the 13 teams individually via zoomed
      screenshot crops of the real rebuilt `championship_chart.html`
      (not an isolated snippet) -- Red Sox/Cardinals/Rangers/Nationals/
      Phillies/Cowboys/Dolphins all read as clearly lighter versions of
      their own hue, Giants reads as a lighter warm tan, and the four
      black-secondary teams (Ravens/Jets/Cardinals/Lightning) all read as
      a clean, consistent light gray.
50. Removed the light white "double-ring" halo (`box-shadow: 0 0 0 2px
    rgba(255,255,255,0.55)`, added in entry 46's item 1 fix) from around
    the runner-up pill, per request -- `.runner` now just has its plain
    solid border (both base and `@media print` rules), no outer glow.
51. **Real legibility fix for 12 named teams** (distinct from entry 49's
    purely cosmetic "make it lighter" request -- this time the user
    explicitly framed it as a contrast/readability problem): Texas
    Rangers, Washington Nationals, San Francisco Giants, Florida Marlins,
    Cincinnati Reds, Tampa Bay Buccaneers, New York Jets, Chicago
    Cardinals, Colorado Avalanche, Tampa Bay Lightning, Dallas Stars,
    Rochester Royals.
    - **Root cause**: entry 49's `$softenTeams` mechanism applied a flat,
      no-floor `+0.16` HSL lightness bump with zero regard for the
      resulting contrast ratio. For teams whose color was already
      borderline (not comfortably passing), that cosmetic bump pushed
      them from "marginal but legible" to genuinely illegible -- e.g.
      Texas Rangers went from ratio ~2.07 to ~1.15. Measured actual
      on-screen ratios for all 12 flagged teams confirmed several were
      well under 2.0, i.e. a real problem, not just a preference.
      Overlap with entry 49: Texas Rangers, Washington Nationals, San
      Francisco Giants, Cincinnati Reds, New York Jets, Chicago
      Cardinals, and Tampa Bay Lightning were *removed* from
      `$softenTeams` entirely (their cosmetic lighten was the regression);
      `$softenTeams` now only contains the 6 teams whose issue genuinely
      was just preference and didn't regress: Boston Red Sox, St. Louis
      Cardinals, Philadelphia Phillies, Baltimore Ravens, Dallas Cowboys,
      Miami Dolphins.
    - **Fix**: added a new `$highContrastTeams` lookup (11 of the 12 --
      see Giants exception below) that forces `Get-ChampNameColor`'s own
      minimum-ratio parameter up to **4.0** (from the site-wide 2.0)
      specifically for these teams, letting its existing outward
      lightness-search algorithm do its job properly -- i.e. find the
      *smallest* color change that clears a comfortable bar, rather than
      leaving a marginal color untouched (the 2.0 floor) or blindly
      lightening past it (entry 49's bug). Measured results: Texas
      Rangers `#003278`&rarr;`#B5D4FF` (ratio 4.14), Florida Marlins
      `#EF3340`&rarr;`#760911` (ratio 4.02, *darker* direction won here
      since the Marlins' background is a light cyan -- confirms the
      algorithm correctly picks whichever direction is the smaller
      change, not always "lighter"), Cincinnati Reds/New York Jets/
      Chicago Cardinals/Tampa Bay Lightning (all literal black
      secondaries) all converge on a light gray in the ~`#8A8A8A`-
      `#D1D1D1` range depending on how dark their background is.
    - **San Francisco Giants special case**: this pairing (near-black
      warm secondary `#27251F` on vivid orange `#FD5A1E`) already has a
      *good* contrast ratio by the numbers (~4.86) -- raising the bar
      further does nothing, and entry 49's cosmetic lighten pass
      (`#666051`, ratio only 1.98) was actively worse. Tested lightening
      across the *entire* lightness range by hand: contrast ratio
      actually **drops** the moment you lighten at all (down to ~1.0-1.5
      through a "muddy tan" zone) and only recovers above ~L=0.9, by
      which point it no longer reads as the team's color at all. Built a
      5-swatch visual comparison (literal/previous-soften/black/white/
      navy) against the real Giants orange and confirmed **the literal,
      completely unmodified secondary color reads best of all of
      them** -- so Giants is special-cased in `Build-Cell` to just use
      `$champSecondary` directly, bypassing both `Get-ChampNameColor` and
      `$softenTeams` entirely. (This is the one case all session where
      "leave it alone" was the correct fix, discovered only by testing
      swatches side by side rather than trusting the contrast-ratio
      formula in isolation -- a reminder that WCAG-style ratio doesn't
      always track perceived legibility, especially warm-on-warm pairs.)
    - Verified all 12 teams individually via zoomed screenshots of the
      real rebuilt `championship_chart.html` (Texas Rangers, Washington
      Nationals, Florida Marlins, Cincinnati Reds x3 different years,
      Tampa Bay Buccaneers, New York Jets, Colorado Avalanche, Tampa Bay
      Lightning x3, Dallas Stars, Rochester Royals, and San Francisco
      Giants reverting cleanly to its original dark color) -- all read
      clearly now; Chicago Cardinals (NFL) confirmed via direct
      calculation (`#B8B8B8`, ratio 4.03) consistent with the other
      literal-black-secondary teams since no NFL-column row for that
      team happened to land in a convenient screenshot crop.


