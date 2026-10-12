param([int]$Iteration = 0)
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$production = (Resolve-Path (Join-Path $root '../../..')).Path
$font = New-Object System.Drawing.Font('Segoe UI', 18)
$small = New-Object System.Drawing.Font('Segoe UI', 13)
$ink = [System.Drawing.Brushes]::White
function Draw-ImageFit($graphics, $path, $x, $y, $width, $height) {
    $img = [System.Drawing.Image]::FromFile($path)
    $ratio = [Math]::Min($width / $img.Width, $height / $img.Height)
    $w = [int]($img.Width * $ratio); $h = [int]($img.Height * $ratio)
    $graphics.DrawImage($img, [int]($x+($width-$w)/2), [int]($y+($height-$h)/2), $w, $h)
    $img.Dispose()
}
# Iteration grid: columns front / three-quarter / side / 5.5-stud scale lineup.
if ($Iteration -eq 0) {
$canvas = New-Object System.Drawing.Bitmap(1600, 1340)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(29,27,36))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawString('CROW / THREE SCULPT ITERATIONS / 1 unit = 1 stud', $font, $ink, 20, 12)
$tags = @('front','34','side','scale')
$notes = @('01  Base silhouette / 1,980 triangles','02  Wider head, huge eyes, stepped waving wings','03  Softer gaze, shorter bill, smaller tapered bib / FINAL')
for ($row=0; $row -lt 3; $row++) {
    $y = 55 + $row*425
    $g.DrawString($notes[$row], $small, $ink, 20, $y)
    for ($col=0; $col -lt 4; $col++) {
        Draw-ImageFit $g (Join-Path $root "renders/iter$($row+1)-$($tags[$col]).png") ($col*400) ($y+30) 400 390
    }
}
$canvas.Save((Join-Path $root 'iterations.jpg'), [System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $canvas.Dispose()
}
# Literal side-by-side reference evidence, with a Pup A crop and the full supplied Pet Sim frame.
$canvas = New-Object System.Drawing.Bitmap(1600, 820)
$g = [System.Drawing.Graphics]::FromImage($canvas); $g.Clear([System.Drawing.Color]::FromArgb(29,27,36))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawString('Pup A / APPROVED STYLE', $font, $ink, 20, 20)
$crowLabel = if ($Iteration -eq 0) { 'Crow / FINAL THREE-QUARTER' } else { "Crow / ITERATION $Iteration" }
$g.DrawString($crowLabel, $font, $ink, 440, 20)
$g.DrawString('Pet Simulator 99 / READABILITY BAR', $font, $ink, 910, 20)
$pup = [System.Drawing.Image]::FromFile((Join-Path $production 'models/pup/studio-pup-abc.jpg'))
$src = New-Object System.Drawing.Rectangle(345, 245, 170, 185)
$dest = New-Object System.Drawing.Rectangle(25, 185, 370, 403)
$g.DrawImage($pup,$dest,$src,[System.Drawing.GraphicsUnit]::Pixel); $pup.Dispose()
$crowImage = if ($Iteration -eq 0) { 'final-34.png' } else { "renders/iter$Iteration-34.png" }
Draw-ImageFit $g (Join-Path $root $crowImage) 420 80 480 640
Draw-ImageFit $g (Join-Path $production 'concepts/refs2/pets-ref-1.jpg') 910 90 670 620
$g.DrawString('Soft bricks + pumpkin stem', $small, $ink, 25, 740)
$g.DrawString('Big face + short body + waving wings', $small, $ink, 440, 740)
$g.DrawString('Bold eyes + simple colour blocks', $small, $ink, 940, 740)
$target = if ($Iteration -eq 0) { 'reference-comparison.jpg' } else { "renders/iter$Iteration-reference.jpg" }
$canvas.Save((Join-Path $root $target), [System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $canvas.Dispose(); $font.Dispose(); $small.Dispose()
