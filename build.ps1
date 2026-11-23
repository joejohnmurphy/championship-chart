function Get-Luminance($hex) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0,2),16)
    $g = [Convert]::ToInt32($hex.Substring(2,2),16)
    $b = [Convert]::ToInt32($hex.Substring(4,2),16)
    return (0.299*$r + 0.587*$g + 0.114*$b)
}

function Get-FG($hex) {
    if ([string]::IsNullOrEmpty($hex)) { return '#000' }
    $lum = Get-Luminance $hex
    if ($lum -lt 140) { return '#fff' } else { return '#111' }
}

# --- Color-contrast helpers (WCAG-style relative luminance) ---

function Hex-ToRgb($hex) {
    $hex = $hex.TrimStart('#')
    return @(
        [Convert]::ToInt32($hex.Substring(0,2),16),
        [Convert]::ToInt32($hex.Substring(2,2),16),
        [Convert]::ToInt32($hex.Substring(4,2),16)
    )
}

function Rgb-ToHex($r,$g,$b) {
    $r = [Math]::Max(0,[Math]::Min(255,[Math]::Round($r)))
    $g = [Math]::Max(0,[Math]::Min(255,[Math]::Round($g)))
    $b = [Math]::Max(0,[Math]::Min(255,[Math]::Round($b)))
    return ('#{0:X2}{1:X2}{2:X2}' -f [int]$r,[int]$g,[int]$b)
}

function Get-RelLuminance($hex) {
    $rgb = Hex-ToRgb $hex
    $channels = $rgb | ForEach-Object {
        $c = $_ / 255.0
        if ($c -le 0.03928) { $c / 12.92 } else { [Math]::Pow((($c + 0.055) / 1.055), 2.4) }
    }
    return (0.2126*$channels[0] + 0.7152*$channels[1] + 0.0722*$channels[2])
}

function Get-ContrastRatio($hex1, $hex2) {
    $l1 = Get-RelLuminance $hex1
    $l2 = Get-RelLuminance $hex2
    $lighter = [Math]::Max($l1,$l2)
    $darker = [Math]::Min($l1,$l2)
    return ($lighter + 0.05) / ($darker + 0.05)
}

function Rgb-ToHsl($r,$g,$b) {
    $r = $r/255.0; $g = $g/255.0; $b = $b/255.0
    $max = [Math]::Max($r,[Math]::Max($g,$b))
    $min = [Math]::Min($r,[Math]::Min($g,$b))
    $h = 0; $s = 0; $l = ($max+$min)/2
    if ($max -ne $min) {
        $d = $max - $min
        $s = if ($l -gt 0.5) { $d / (2 - $max - $min) } else { $d / ($max + $min) }
        switch ($max) {
            $r { $h = (($g - $b) / $d) + $(if ($g -lt $b) { 6 } else { 0 }) }
            $g { $h = (($b - $r) / $d) + 2 }
            $b { $h = (($r - $g) / $d) + 4 }
        }
        $h = $h / 6
    }
    return @($h,$s,$l)
}

function Hue-ToRgb($p,$q,$t) {
    if ($t -lt 0) { $t += 1 }
    if ($t -gt 1) { $t -= 1 }
    if ($t -lt (1/6)) { return $p + ($q - $p) * 6 * $t }
    if ($t -lt (1/2)) { return $q }
    if ($t -lt (2/3)) { return $p + ($q - $p) * (2/3 - $t) * 6 }
    return $p
}

function Hsl-ToRgb($h,$s,$l) {
    if ($s -eq 0) {
        $v = $l * 255
        return @($v,$v,$v)
    }
    $q = if ($l -lt 0.5) { $l * (1 + $s) } else { $l + $s - $l * $s }
    $p = 2 * $l - $q
    $r = Hue-ToRgb $p $q ($h + 1/3)
    $g = Hue-ToRgb $p $q $h
    $b = Hue-ToRgb $p $q ($h - 1/3)
    return @(($r*255), ($g*255), ($b*255))
}

function Set-Lightness($hex, $newL) {
    $rgb = Hex-ToRgb $hex
    $hsl = Rgb-ToHsl $rgb[0] $rgb[1] $rgb[2]
    $rgbOut = Hsl-ToRgb $hsl[0] $hsl[1] $newL
    return Rgb-ToHex $rgbOut[0] $rgbOut[1] $rgbOut[2]
}

# True if $hex is a gold/yellow shade close enough to the trophy emoji's own
# color that a gold trophy icon/number would wash out against it as a
# background (used to flip the trophy+count to a dark, contrasting color).
# True if $hex is a warm, light enough shade (gold, yellow, or orange) that
# gold-colored elements (the trophy emoji's natural color, the gold
# titlecount) would wash out against it as a background -- used to flip
# those to a dark, contrasting treatment instead. Calibrated against real
# team colors in this dataset: oranges/golds cluster around hue 10-65,
# saturation >=0.35, lightness 0.38-0.85 (saturation floor lowered from an
# initial 0.5 after New Orleans Saints' desaturated tan, S=0.44, was found
# slipping through); dark warm colors like a maroon (hue 0, lightness
# ~0.22) and cool colors (teal/aqua, hue ~184) are deliberately excluded.
function Test-IsGoldish($hex) {
    $rgb = Hex-ToRgb $hex
    $hsl = Rgb-ToHsl $rgb[0] $rgb[1] $rgb[2]
    $h = $hsl[0] * 360
    $s = $hsl[1]
    $l = $hsl[2]
    return ($h -ge 10 -and $h -le 65 -and $s -ge 0.35 -and $l -ge 0.38 -and $l -le 0.85)
}

# Computes the champion name's text color from the team's own secondary
# color, balancing two competing goals that caused repeated back-and-forth
# in earlier sessions (see changelog): keep the real team color recognizable
# (don't wash a saturated red out to pastel pink just to hit a strict WCAG
# ratio), while still avoiding literal pure-black text and giving genuinely
# too-dark "already passing" colors (e.g. a black secondary on an orange
# background) a small lift so they don't read as flat black.
#
# minRatio was lowered from the original 4.5 (strict WCAG AA) down to 2.0
# after user feedback that several real team pairs (Chiefs gold/red,
# Patriots red/navy, Pistons red/blue, Cubs red/navy) were being pushed
# into pale pastel pink/white by the stricter bar. A side-by-side test
# confirmed the literal, unadjusted team color with just the existing
# black text-stroke outline reads perfectly fine even at a raw contrast
# ratio as low as ~1.4 -- the stroke is doing the legibility work, not
# the fill color's contrast against the background. This project is a
# cosmetic chart with that stroke always present, not a WCAG-compliance
# tool, so trading contrast-ratio purity for authentic team color is the
# right call here. 2.0 is kept as a last-resort floor only for the rare
# pairs where the literal color is both low-contrast AND visually
# ambiguous (e.g. near-identical secondary/background tones).
function Get-ChampNameColor($secHex, $bgHex, $minRatio) {
    $rawRatio = Get-ContrastRatio $secHex $bgHex
    if ($rawRatio -ge $minRatio) {
        # Secondary color already reads fine as-is -- keep it untouched,
        # UNLESS it's quite dark (common for black/near-black secondaries
        # on a bright background), in which case nudge it a bit lighter
        # purely for a softer look, not because it fails legibility.
        $final = $secHex
        if ((Get-RelLuminance $final) -lt 0.09) {
            $rgb = Hex-ToRgb $final
            $hsl = Rgb-ToHsl $rgb[0] $rgb[1] $rgb[2]
            $lighter = Set-Lightness $final ($hsl[2] + 0.22)
            if ((Get-ContrastRatio $lighter $bgHex) -ge 1.6) { $final = $lighter }
        }
        return $final
    }
    $final = Get-LegibleColor $secHex $bgHex $minRatio
    if ((Get-RelLuminance $final) -lt 0.03) { $final = Set-Lightness $final 0.20 }
    if ((Get-ContrastRatio $final $bgHex) -lt 2.0) {
        if ((Get-ContrastRatio '#FFFFFF' $bgHex) -ge (Get-ContrastRatio '#2b2b2b' $bgHex)) {
            $final = '#FFFFFF'
        } else {
            $final = '#2b2b2b'
        }
    }
    return $final
}

# Explicit per-team lightness nudge, used for a named list of teams the
# user flagged as reading too dark even though they technically clear the
# legibility bar in Get-ChampNameColor above. Unlike that function, this
# doesn't try to preserve a minimum contrast ratio -- it's a pure cosmetic
# request, trusting the always-on black text-stroke outline to keep the
# name readable even as the fill color itself gets noticeably lighter.
# Keeps hue/saturation, just raises HSL lightness by a fixed amount
# (capped so it never blows out to near-white). A handful of these teams'
# computed color is literal black (no hue/saturation to preserve, e.g. the
# Ravens/Jets/Cardinals/Lightning's black secondary) -- a small lightness
# delta barely moves black, so those get a fixed mid-gray instead.
function Soften-TextColor($hex, $delta) {
    if ($hex -eq '#000000') { return '#767676' }
    $rgb = Hex-ToRgb $hex
    $hsl = Rgb-ToHsl $rgb[0] $rgb[1] $rgb[2]
    $newL = [Math]::Min(0.72, $hsl[2] + $delta)
    return Set-Lightness $hex $newL
}

# Teams named in direct user feedback as having too-dark champion name
# text, regardless of what the contrast algorithm above computed for them.
# NOTE: this list used to also include Texas Rangers, Washington Nationals,
# San Francisco Giants, Cincinnati Reds, New York Jets, Chicago Cardinals,
# and Tampa Bay Lightning -- removed after a later round of feedback that
# this flat, no-floor cosmetic lighten had pushed several of those teams'
# *already marginal* contrast down even further (e.g. Texas Rangers went
# from a borderline-but-legible ratio ~2.07 to an actually-illegible
# ~1.15). Those teams now go through `$highContrastTeams` below instead,
# which enforces a real contrast floor rather than a blind lightness bump.
$softenTeams = @{
    'Boston Red Sox' = $true
    'St. Louis Cardinals' = $true
    'Philadelphia Phillies' = $true
    'Baltimore Ravens' = $true
    'Dallas Cowboys' = $true
    'Miami Dolphins' = $true
}

# Teams named in direct user feedback as genuinely hard to read -- unlike
# `$softenTeams` above (a pure cosmetic preference), this is treated as a
# real legibility bug: force a much higher minimum contrast ratio (4.0
# instead of the site-wide 2.0 floor) specifically for these teams, so
# `Get-ChampNameColor`'s own outward lightness search does the work of
# finding the smallest change that actually clears a comfortable bar,
# instead of leaving a borderline color untouched or (worse) lightening it
# with no regard for the resulting ratio.
$highContrastTeams = @{
    'Texas Rangers' = $true
    'Washington Nationals' = $true
    'Florida Marlins' = $true
    'Cincinnati Reds' = $true
    'Tampa Bay Buccaneers' = $true
    'New York Jets' = $true
    'Chicago Cardinals' = $true
    'Colorado Avalanche' = $true
    'Tampa Bay Lightning' = $true
    'Dallas Stars' = $true
    'Rochester Royals' = $true
}


# Ensures $textHex is legible against $bgHex. If contrast is already
# decent, returns the original color unchanged (preserves team color).
# Otherwise nudges the text color's lightness (same hue/saturation) toward
# white or black in small increments -- whichever direction clears the
# minimum ratio in fewer steps -- so the team's color identity is kept
# as close to the original as possible while the text stays readable.
#
# Previously this jumped straight to a handful of extreme preset
# lightness values (0.90, 0.95, 0.98, ...) and took the first one that
# cleared the bar. For saturated reds especially, that meant massively
# overshooting the minimum needed contrast and landing on a washed-out
# pastel pink even when a much smaller, richer adjustment would have
# cleared the same bar (e.g. Patriots red only needed to reach ~L=0.6 to
# clear 4.5, but the old code tried L=0.90 first and stopped there,
# producing a near-pastel-pink #FCCFD8 instead of a rich crimson).
function Get-LegibleColor($textHex, $bgHex, $minRatio) {
    $ratio = Get-ContrastRatio $textHex $bgHex
    if ($ratio -ge $minRatio) { return $textHex }

    $rgb = Hex-ToRgb $textHex
    $hsl = Rgb-ToHsl $rgb[0] $rgb[1] $rgb[2]
    $startL = $hsl[2]
    $step = 0.02

    $lighterHex = $null; $lighterSteps = $null
    $darkerHex = $null; $darkerSteps = $null
    $bestHex = $textHex
    $bestRatio = $ratio

    for ($i = 1; $i -le 60; $i++) {
        $l = $startL + ($i * $step)
        if ($l -gt 0.995) { break }
        $candidate = Set-Lightness $textHex $l
        $r = Get-ContrastRatio $candidate $bgHex
        if ($r -gt $bestRatio) { $bestRatio = $r; $bestHex = $candidate }
        if ($r -ge $minRatio -and $null -eq $lighterHex) { $lighterHex = $candidate; $lighterSteps = $i }
    }
    for ($i = 1; $i -le 60; $i++) {
        $l = $startL - ($i * $step)
        if ($l -lt 0.01) { break }
        $candidate = Set-Lightness $textHex $l
        $r = Get-ContrastRatio $candidate $bgHex
        if ($r -gt $bestRatio) { $bestRatio = $r; $bestHex = $candidate }
        if ($r -ge $minRatio -and $null -eq $darkerHex) { $darkerHex = $candidate; $darkerSteps = $i }
    }

    if ($lighterHex -and $darkerHex) {
        if ($lighterSteps -le $darkerSteps) { return $lighterHex } else { return $darkerHex }
    } elseif ($lighterHex) {
        return $lighterHex
    } elseif ($darkerHex) {
        return $darkerHex
    } else {
        return $bestHex
    }
}

function Parse-File($path) {
    $data = @{}
    Get-Content -LiteralPath $path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '') { return }
        $parts = $line -split '\|'
        $year = [int]$parts[0]
        $data[$year] = $parts[1..($parts.Length-1)]
    }
    return $data
}

function Parse-Secondary($path) {
    $data = @{}
    Get-Content -LiteralPath $path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '') { return }
        $parts = $line -split '\|'
        $data[$parts[0]] = $parts[1]
    }
    return $data
}

function Get-Secondary($name, $league, $secondary) {
    if ($league -eq 'nfl' -and $name -eq 'New York Giants') {
        return $secondary['New York Giants (NFL)']
    }
    if ($secondary.ContainsKey($name)) {
        return $secondary[$name]
    }
    return '#888888'
}

function Format-NflRecord($rec) {
    $parts = $rec -split '-'
    if ($parts.Count -eq 3 -and [int]$parts[2] -eq 0) {
        return "$($parts[0])-$($parts[1])"
    }
    return $rec
}

function To-Roman($num) {
    $pairs = @(
        @(1000,'M'), @(900,'CM'), @(500,'D'), @(400,'CD'), @(100,'C'), @(90,'XC'),
        @(50,'L'), @(40,'XL'), @(10,'X'), @(9,'IX'), @(5,'V'), @(4,'IV'), @(1,'I')
    )
    $result = ''
    foreach ($pair in $pairs) {
        $value = $pair[0]
        $numeral = $pair[1]
        while ($num -ge $value) {
            $result += $numeral
            $num -= $value
        }
    }
    return $result
}

# Franchise alias groups: maps a historical/relocated team name to a single
# canonical key so cumulative championship counts follow the franchise, not
# the display name (e.g. Brooklyn Dodgers + LA Dodgers count together).
$aliases = @{
    'mlb' = @{
        'Brooklyn Dodgers'='Dodgers'; 'Brooklyn Robins'='Dodgers'; 'Los Angeles Dodgers'='Dodgers'
        'Boston Braves'='Braves'; 'Milwaukee Braves'='Braves'; 'Atlanta Braves'='Braves'
        'Philadelphia Athletics'='Athletics'; 'Oakland Athletics'='Athletics'
        'New York Giants'='SF/NY Giants'; 'San Francisco Giants'='SF/NY Giants'
        'St. Louis Browns'='Orioles'; 'Baltimore Orioles'='Orioles'
        'Washington Senators'='Twins'; 'Minnesota Twins'='Twins'
        'Boston Americans'='Red Sox'; 'Boston Red Sox'='Red Sox'
    }
    'nfl' = @{
        'Decatur Staleys'='Bears'; 'Chicago Staleys'='Bears'; 'Chicago Bears'='Bears'
        'Chicago Cardinals'='Cardinals'; 'Arizona Cardinals'='Cardinals'
        'Baltimore Colts'='Colts'; 'Indianapolis Colts'='Colts'
        'Cleveland Rams'='Rams'; 'Los Angeles Rams'='Rams'; 'St. Louis Rams'='Rams'
        'Portsmouth Spartans'='Lions'; 'Detroit Lions'='Lions'
        'Oakland Raiders'='Raiders'; 'Los Angeles Raiders'='Raiders'
        'Boston Redskins'='Redskins'; 'Washington Redskins'='Redskins'
    }
    'nhl' = @{
        'Toronto Arenas'='Maple Leafs'; 'Toronto St. Patricks'='Maple Leafs'; 'Toronto Maple Leafs'='Maple Leafs'
        'Chicago Black Hawks'='Blackhawks'; 'Chicago Blackhawks'='Blackhawks'
        'Mighty Ducks of Anaheim'='Ducks'; 'Anaheim Ducks'='Ducks'
        'Minnesota North Stars'='Stars'; 'Dallas Stars'='Stars'
    }
    'nba' = @{
        'Minneapolis Lakers'='Lakers'; 'Los Angeles Lakers'='Lakers'
        'Fort Wayne Pistons'='Pistons'; 'Detroit Pistons'='Pistons'
        'Philadelphia Warriors'='Warriors'; 'San Francisco Warriors'='Warriors'; 'Golden State Warriors'='Warriors'
        'Syracuse Nationals'='76ers'; 'Philadelphia 76ers'='76ers'
    }
}

function Get-Canonical($name, $league, $aliases) {
    if ($aliases[$league].ContainsKey($name)) { return $aliases[$league][$name] }
    return $name
}

$mlb = Parse-File 'mlb.txt'
$nfl = Parse-File 'nfl.txt'
$nhl = Parse-File 'nhl.txt'
$nba = Parse-File 'nba.txt'
$secondary = Parse-Secondary 'secondary.txt'

$allYears = @{}
foreach ($d in @($mlb,$nfl,$nhl,$nba)) { foreach ($k in $d.Keys) { $allYears[$k] = $true } }
$years = $allYears.Keys | Sort-Object -Descending
$yearsAscending = $allYears.Keys | Sort-Object

# Pre-compute cumulative championship counts per franchise, per league, keyed
# by "league|year" -> count (count already includes that year's title).
$cumulative = @{}
foreach ($leagueName in @('mlb','nfl','nhl','nba')) {
    $data = switch ($leagueName) { 'mlb'{$mlb} 'nfl'{$nfl} 'nhl'{$nhl} 'nba'{$nba} }
    $counts = @{}
    foreach ($y in $yearsAscending) {
        if (-not $data.ContainsKey($y)) { continue }
        $champ = $data[$y][0]
        if ($champ -like 'NO *') { continue }
        $canon = Get-Canonical $champ $leagueName $aliases
        if (-not $counts.ContainsKey($canon)) { $counts[$canon] = 0 }
        $counts[$canon] += 1
        $cumulative["$leagueName|$y"] = $counts[$canon]
    }
}

function Build-Cell($parts, $league, $secondary, $year, $cumulative) {
    if ($null -eq $parts) { return '<td class="empty"></td>' }
    $champ = $parts[0]
    if ($champ -like 'NO *') {
        return "<td class=`"empty noevent`">$champ</td>"
    }
    $champRec = $parts[1]; $champGames = $parts[2]; $runner = $parts[3]
    $runnerRec = $parts[4]; $runnerGames = $parts[5]
    $champColor = $parts[6]; $runnerColor = $parts[7]

    $champFg = Get-FG $champColor
    $runnerFg = Get-FG $runnerColor
    $champSecondary = Get-Secondary $champ $league $secondary
    $runnerSecondary = Get-Secondary $runner $league $secondary
    $champCount = $cumulative["$league|$year"]
    # San Francisco Giants is a special case: their secondary is a
    # near-black warm color (#27251F) against a vivid orange background.
    # By the numbers that pairing already has good contrast (~4.9) and
    # pushing it lighter in either direction (tested extensively) only
    # makes it *worse* -- lighter washes through a low-contrast "muddy
    # tan" zone before ever regaining ratio, and only recovers past
    # literal white, which looks wrong for the team. A direct visual
    # comparison confirmed the literal, unmodified secondary color reads
    # best here, so it's left alone entirely rather than run through
    # either adjustment path below.
    if ($champ -eq 'San Francisco Giants') {
        $champNameColor = $champSecondary
    } elseif ($highContrastTeams.ContainsKey($champ)) {
        $champNameColor = Get-ChampNameColor $champSecondary $champColor 4.0
    } else {
        $champNameColor = Get-ChampNameColor $champSecondary $champColor 2.0
        if ($softenTeams.ContainsKey($champ)) {
            if ($champSecondary -eq '#000000') {
                $champNameColor = '#767676'
            } else {
                $champNameColor = Soften-TextColor $champNameColor 0.16
            }
        }
    }
    # Outline is always solid black and always just a thin stroke -- no
    # shadow, no light/dark branching by background. Simple and
    # consistent everywhere.
    $champOutline = "-webkit-text-stroke:0.45px #000;text-stroke:0.45px #000"
    # Still needed to decide the trophy/titlecount's light-vs-dark
    # treatment (a gold trophy/number washes out on a gold/orange
    # background) -- unrelated to the outline/shadow decisions above.
    $champIsLightBg = Test-IsGoldish $champColor

    $champLine = $champRec
    $runnerLine = $runnerRec
    if ($league -eq 'nfl') {
        $champLine = Format-NflRecord $champRec
        $runnerLine = Format-NflRecord $runnerRec
    }

    $scoreLabel = "$champGames-$runnerGames"
    $showScore = $true
    if ($league -eq 'nfl' -and $year -lt 1932) {
        # No championship game was played, so there's no game score to
        # show -- the "4-2"/"24-14"-style pill would just render as a
        # bare "-" placeholder, which doesn't mean anything here.
        $showScore = $false
    }
    if ($champFg -eq '#fff') {
        $scorePillBg = 'rgba(255,255,255,0.22)'
        $scorePillBorder = 'rgba(255,255,255,0.4)'
    } else {
        $scorePillBg = 'rgba(0,0,0,0.18)'
        $scorePillBorder = 'rgba(0,0,0,0.35)'
    }
    $sbLabel = ''
    if ($league -eq 'nfl' -and $year -ge 1966) {
        $sbNum = To-Roman ($year - 1965)
        $sbLabel = "<div class=`"sbline`" style=`"color:$champFg`">$sbNum</div>"
    }

    if ($champIsLightBg) {
        # A blurred drop-shadow filter on a tiny color-emoji glyph doesn't
        # render as a clean outline at this size -- it smears into an
        # unrecognizable blob (confirmed via screenshot). A crisp,
        # zero-blur, multi-directional text-shadow (the classic hard-edge
        # "outline" trick) traces the glyph's actual alpha shape instead,
        # so the trophy still reads as a trophy, just with a thin dark
        # edge for contrast against a gold/orange background.
        $trophyFilter = 'text-shadow:1px 0 0 #000,-1px 0 0 #000,0 1px 0 #000,0 -1px 0 #000,1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000'
        $countColor = '#1a1a1a'
    } else {
        $trophyFilter = ''
        $countColor = '#FFD700'
    }

    $html = "<td style=`"background:$champColor;color:$champFg`">"

    # 1920-1931 NFL seasons had no championship game -- the "runner-up"
    # there is just the second-place team by season record, not a team
    # that was actually defeated in a game, so "def." is factually wrong
    # for those rows specifically (every other row, including 1932
    # onward, is a real game/series result).
    $defLabel = 'def.'
    if ($league -eq 'nfl' -and $year -lt 1932) {
        $defLabel = '2nd place:'
    }

    $html += $sbLabel
    $html += "<div class=`"result-line`"><span class=`"champ`" style=`"color:$champNameColor;$champOutline`">$champ</span><span class=`"recline-champ`">$champLine</span><span class=`"trophy`" style=`"$trophyFilter`">&#127942;</span><span class=`"titlecount`" style=`"color:$countColor`">$champCount</span></div>"
    $scoreSpan = ''
    if ($showScore) {
        $scoreSpan = "<span class=`"score`" style=`"color:$champFg;background:$scorePillBg;border-color:$scorePillBorder`">$scoreLabel</span>"
    }
    $html += "<div class=`"result-line`"><span class=`"def-label`">$defLabel</span><span class=`"runner`" style=`"background:$runnerColor;color:$runnerFg;border-color:$runnerSecondary`">$runner</span><span class=`"recline-runner`" style=`"color:$champFg`">$runnerLine</span>$scoreSpan</div>"
    $html += '</td>'
    return $html
}

$rows = foreach ($y in $years) {
    $row = "<tr><td class=`"year`">$y</td>"
    $row += Build-Cell $mlb[$y] 'mlb' $secondary $y $cumulative
    $row += Build-Cell $nfl[$y] 'nfl' $secondary $y $cumulative
    $row += Build-Cell $nhl[$y] 'nhl' $secondary $y $cumulative
    $row += Build-Cell $nba[$y] 'nba' $secondary $y $cumulative
    $row += '</tr>'
    $row
}

$tableBody = $rows -join "`n"

$template = Get-Content -LiteralPath 'template.html' -Raw -Encoding UTF8
$out = $template.Replace('__ROWS__', $tableBody)
Set-Content -LiteralPath 'championship_chart.html' -Value $out -Encoding UTF8

Write-Output "Rows: $($years.Count)"
