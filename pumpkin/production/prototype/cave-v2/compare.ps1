param([string]$RenderId='r2-final')
Add-Type -AssemblyName System.Drawing
$compareRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path (Get-Location) 'prototype/cave-v2' }
$taskRoot = Split-Path $compareRoot -Parent
$productionRoot = Split-Path $taskRoot -Parent
$left = [System.Drawing.Image]::FromFile((Join-Path $productionRoot 'treasure/cave-v2/concept-v2.1.png'))
$right = [System.Drawing.Image]::FromFile((Join-Path $compareRoot ('build-r'+$RenderId+'-concept.png')))
$sheet = New-Object System.Drawing.Bitmap 2048,800
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(24,26,38))
$font = New-Object System.Drawing.Font 'Segoe UI',18
$brush = [System.Drawing.Brushes]::White
$g.DrawString('CONCEPT v2.1 - generated reference', $font, $brush, 20,15)
$g.DrawString('NATIVE GEOMETRY - offline render; approximate camera', $font, $brush, 1044,15)
foreach ($pair in @(@($left,0),@($right,1024))) {
 $img=$pair[0];$x=[int]$pair[1];$scale=[Math]::Min(1024.0/$img.Width,710.0/$img.Height)
 $w=[int]($img.Width*$scale);$h=[int]($img.Height*$scale)
 $g.DrawImage($img, $x+[int]((1024-$w)/2), 65+[int]((710-$h)/2), $w,$h)
}
$sheet.Save((Join-Path $compareRoot 'CONCEPT-COMPARE.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$sheet.Dispose();$left.Dispose();$right.Dispose();$font.Dispose()
