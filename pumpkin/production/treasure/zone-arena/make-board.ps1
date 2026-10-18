Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$canvas = New-Object System.Drawing.Bitmap 2400,1250
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(18,24,34))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$title = New-Object System.Drawing.Font 'Arial',29,([System.Drawing.FontStyle]::Bold)
$label = New-Object System.Drawing.Font 'Arial',17
$small = New-Object System.Drawing.Font 'Arial',15
$white = [System.Drawing.Brushes]::White
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(184,199,215))
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,215,92))
$g.DrawString('RECOMMEND: CROWN ROAD  |  One map. Steal and escape.', $title,$white,24,20)
$g.DrawString('Build 1 complete loop, then zones 1-3. V1: zones 1-5. Zones 6-15 later. All concepts INFERRED / UNTESTED.', $label,$muted,27,73)
function Place-View([string]$file,[string]$caption,[int]$x,[int]$y,[int]$w,[int]$h) {
  $g.DrawString($caption,$label,$white,$x,$y)
  $im = [System.Drawing.Image]::FromFile((Join-Path $root $file))
  try {
    $scale = [Math]::Min($w / $im.Width,($h-34) / $im.Height)
    $dw = [int]($im.Width*$scale); $dh = [int]($im.Height*$scale)
    $dx = $x+[int](($w-$dw)/2); $dy = $y+34+[int](($h-34-$dh)/2)
    $g.DrawImage($im,$dx,$dy,$dw,$dh)
  } finally { $im.Dispose() }
}
Place-View '01-overview-v2.png' 'A / Whole map - fifteen-zone future' 24 125 760 830
Place-View '02-home.png' 'B / Home - see the deeper zones' 810 125 770 505
Place-View '03-zone-01-v2.png' 'C / Zone 1 - wake, bait, escape home' 1604 125 770 505
Place-View '04-zone-08-v2.png' 'D / Zone 8 - narrow landing, timed bend' 810 650 770 505
Place-View '05-zone-15-v2.png' 'E / Zone 15 - two-beat raid fork' 1604 650 770 505
$g.DrawString('Smallest core: zones 1-5', $title,$gold,24,985)
$g.DrawString('Studded structure + sparse Toy Meadow props', $small,$muted,26,1043)
$g.DrawString('3 blind AI critics chose A. Mean: 8/10 overall.', $small,$muted,26,1080)
$g.DrawString('Difficulty 7/10 is a judgment, not a playtest.', $small,$muted,26,1117)
$g.DrawString('Targets only: first try Z1 90% / Z8 40% / Z15 10%.  |  No Studio Play, 3D work or place edits. Pictures are not a built game.', $small,$muted,26,1204)
$path = Join-Path $root 'BOARD.jpg'
$canvas.Save($path,[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $canvas.Dispose(); $title.Dispose(); $label.Dispose(); $small.Dispose(); $muted.Dispose(); $gold.Dispose()
Write-Output $path
