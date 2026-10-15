# Compose actual Blender previews. No vendor code runs.
Add-Type -AssemblyName System.Drawing
$kitRoot = Join-Path $PWD 'assets/kits'
$manifest = Get-Content (Join-Path $kitRoot 'manifest.json') -Raw | ConvertFrom-Json
$columns = 8
$cellWidth = 192
$cellHeight = 226
$rows = [int][Math]::Ceiling($manifest.exports.Count / $columns)
$bitmap = New-Object System.Drawing.Bitmap ($columns*$cellWidth),($rows*$cellHeight)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::FromArgb(30,34,42))
$font = New-Object System.Drawing.Font 'Arial',8
$brush = [System.Drawing.Brushes]::White
$index = 0
foreach ($entry in $manifest.exports) {
    $stem = $entry.pack + '__' + $entry.name
    $thumbPath = Join-Path $kitRoot ('_thumbs/' + $entry.island + '__' + $stem + '.png')
    $preview = [System.Drawing.Image]::FromFile($thumbPath)
    $x = ($index % $columns)*$cellWidth
    $y = [Math]::Floor($index / $columns)*$cellHeight
    $graphics.DrawImage($preview,$x,$y,192,192)
    $graphics.DrawString(($entry.island + ' / ' + $entry.name),$font,$brush,$x+4,$y+194)
    $graphics.DrawString($entry.pack,$font,$brush,$x+4,$y+210)
    $preview.Dispose()
    $index++
}
$bitmap.Save((Join-Path $kitRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics.Dispose()
$bitmap.Dispose()
$font.Dispose()
Write-Output "PASS contact sheet $index model previews"
