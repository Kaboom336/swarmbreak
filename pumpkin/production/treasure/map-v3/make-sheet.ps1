Add-Type -AssemblyName System.Drawing
$taskRoot = $PSScriptRoot
$sheet = New-Object System.Drawing.Bitmap 2700,2040
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::FromArgb(15,23,35))
$white = [System.Drawing.Brushes]::White
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(186,203,221))
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,202,87))
$fontTitle = New-Object System.Drawing.Font 'Arial',42,([System.Drawing.FontStyle]::Bold)
$fontHead = New-Object System.Drawing.Font 'Arial',29,([System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font 'Arial',22
$g.DrawString('MEADOW V3 | THREE LAYOUTS, ONE SHARED CHASE',$fontTitle,$white,40,22)
$g.DrawString('Generated design concepts | 4-8 players | 2s Steal | 60s deadline | dimensions and corrections in MAP-V3.md',$fontBody,$muted,42,82)
$labels = @('A  ORCHARD RING','B  CORKSCREW SUMMIT','C  SPLIT VALLEY  /  PICK')
$subtitles = @('Loop reversals / inner interceptions','Height choices / staged descent','Bridge bait / two independent flanks')
function Draw-FitImage($file,$x,$y,$width,$height) {
    $img = [System.Drawing.Image]::FromFile((Join-Path $taskRoot $file))
    $scale = [Math]::Min($width / $img.Width,$height / $img.Height)
    $dw = [int]($img.Width * $scale)
    $dh = [int]($img.Height * $scale)
    $dx = [int]($x + ($width - $dw)/2)
    $dy = [int]($y + ($height - $dh)/2)
    $g.DrawImage($img,$dx,$dy,$dw,$dh)
    $img.Dispose()
}
for($i=0; $i -lt 3; $i++) {
    $x = 40 + $i * 880
    $brush = $white
    if($i -eq 2) { $brush = $gold }
    $g.DrawString($labels[$i],$fontHead,$brush,$x,142)
    $g.DrawString($subtitles[$i],$fontBody,$muted,$x,190)
    $letter = [char](65+$i)
    Draw-FitImage "$letter-blueprint.png" $x 240 850 1010
    Draw-FitImage "$letter-concept.png" $x 1272 850 650
}
$g.DrawString('JUDGE: C / Split Valley. Optional bridge, covered west crossing, elevated east route. Build one for Zion.',$fontBody,$gold,42,1938)
$g.DrawString('40s escapes are contested storyboards, not measured pacing. No game code edits or commit.',$fontBody,$muted,42,1980)
$g.Dispose()
$sheet.Save((Join-Path $taskRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose()
$fontTitle.Dispose(); $fontHead.Dispose(); $fontBody.Dispose(); $muted.Dispose(); $gold.Dispose()
