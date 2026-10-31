# Generates championship_chart.pdf from championship_chart.html using
# headless Chrome (falls back to Edge if Chrome isn't found).
# Run .\build.ps1 first if you've changed the data/template.

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path $here 'championship_chart.html'
$pdf = Join-Path $here 'championship_chart.pdf'

$chromePaths = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
$browser = $chromePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $browser) {
    Write-Error "No Chrome or Edge installation found to render the PDF."
    exit 1
}

$fileUri = "file:///" + ($html -replace '\\','/')
& $browser --headless=new --disable-gpu --print-to-pdf="$pdf" --no-pdf-header-footer "$fileUri" 2>$null

if (Test-Path -LiteralPath $pdf) {
    Write-Output "PDF written to: $pdf"
} else {
    Write-Error "PDF generation failed."
}
