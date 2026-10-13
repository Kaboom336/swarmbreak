Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$isAcorn = (Split-Path (Split-Path $root -Parent) -Leaf) -eq 'golden-acorn'
$rounds = if ($isAcorn) { 4 } else { 3 }
$width = 1600
$height = 450 * ($rounds + 1)
$sheet = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(242,240,229))
$font = New-Object System.Drawing.Font 'Arial', 16
$brush = [System.Drawing.Brushes]::Black
function DrawTile($path,$x,$y,$w,$h) {
    $im = [System.Drawing.Image]::FromFile($path)
    $scale = [Math]::Min($w/$im.Width,$h/$im.Height)
    $dw = [int]($im.Width*$scale); $dh = [int]($im.Height*$scale)
    $g.DrawImage($im,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)
    $im.Dispose()
}
$production = Split-Path (Split-Path (Split-Path $root -Parent) -Parent) -Parent
if ($isAcorn) {
    DrawTile "$production/treasure/containers.png" 0 40 800 390
    DrawTile "$production/treasure/v2/open-reveal.png" 800 40 800 390
    $notes = @('R1: slim shell; opening too tight','R2: fuller shoulder; clearer reveal gap','R3: broad cap rim; stronger open silhouette','R4 KEEP: turned halves show both hollow interiors')
} else {
    DrawTile "$production/models/crow/blender/final-34.png" 0 40 500 390
    DrawTile "$production/models/pup/studio-pup-abc.jpg" 500 40 500 390
    DrawTile "$production/treasure/v2/meadow-island.png" 1000 40 600 390
    $notes = @('R1: base silhouette and face','R2: wider face/hat; larger eyes; straw hair','R3 KEEP: simplified hat; friendlier brow; cleaner silhouette')
}
$g.DrawString('REFERENCE ANCHORS: approved Crow / Pup A; supplied Meadow concept', $font,$brush,20,8)
for ($i=1; $i -le $rounds; $i++) {
    $y=450*$i
    $g.DrawString($notes[$i-1],$font,$brush,20,$y+8)
    if ($isAcorn) {
        DrawTile "$root/renders/iter$i-front.png" 0 ($y+40) 400 400
        DrawTile "$root/renders/iter$i-34.png" 400 ($y+40) 400 400
        DrawTile "$root/renders/iter$i-open-front.png" 800 ($y+40) 400 400
        DrawTile "$root/renders/iter$i-open-34.png" 1200 ($y+40) 400 400
    } else {
        DrawTile "$root/renders/iter$i-front.png" 0 ($y+40) 800 400
        DrawTile "$root/renders/iter$i-34.png" 800 ($y+40) 800 400
    }
}
$sheet.Save("$root/iterations.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $sheet.Dispose(); $font.Dispose()
