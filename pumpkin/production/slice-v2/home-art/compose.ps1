$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Add-Type -AssemblyName System.Drawing
$reference = [System.Drawing.Image]::FromFile((Join-Path $root 'treasure/v2/home-island.png'))
$render = [System.Drawing.Image]::FromFile((Join-Path $root 'slice-v2/evidence/home-art-final.png'))
$canvas = New-Object System.Drawing.Bitmap(2000, 632)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.Clear([System.Drawing.Color]::FromArgb(22,18,31))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font('Arial', 21, ([System.Drawing.FontStyle]::Bold))
$small = New-Object System.Drawing.Font('Arial', 12)
$g.DrawString('REFERENCE v2', $font, [System.Drawing.Brushes]::Gold, 12, 8)
$g.DrawString('OFFLINE BLENDER - HOME ART', $font, [System.Drawing.Brushes]::Gold, 1012, 8)
$g.DrawImage($reference, 0, 50, 990, 557)
$g.DrawImage($render, 1010, 50, 990, 557)
$g.DrawString('Same camera; six staged pets; real 3.5-stud plot terraces; income undefined. Studio NOT RUN.', $small, [System.Drawing.Brushes]::White, 1012, 610)
$canvas.Save((Join-Path $root 'slice-v2/evidence/sbs-home-art.jpg'), [System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $canvas.Dispose(); $reference.Dispose(); $render.Dispose(); $font.Dispose(); $small.Dispose()
