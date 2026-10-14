Add-Type -AssemblyName System.Drawing
$sheet = New-Object System.Drawing.Bitmap 3600,1080
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(15,23,35))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$title = New-Object System.Drawing.Font 'Arial',32,([System.Drawing.FontStyle]::Bold)
$body = New-Object System.Drawing.Font 'Arial',23
$muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190,205,221))
$gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,202,87))
$g.DrawString('MEADOW V4  |  ONE MERGED C + B LAYOUT',$title,[System.Drawing.Brushes]::White,36,22)
$g.DrawString('Built-in generated concepts | 352 x 352 | summit +24 | main walk 29.6s ESTIMATED at 16 studs/s | no runtime proof',$body,$muted,36,76)
$paths = @((Join-Path $PSScriptRoot 'blueprint.png'),(Join-Path $PSScriptRoot 'concept.png'),(Join-Path $PSScriptRoot '../v2/meadow-island.png'))
$labels = @('V4 / TOP-DOWN BLUEPRINT','V4 / IN-GAME STYLE CONCEPT','V2 / MEADOW ART REFERENCE')
for($i=0; $i -lt 3; $i++) {
    $x = 36 + $i * 1180
    $g.DrawString($labels[$i],$title,$gold,$x,136)
    $img = [System.Drawing.Image]::FromFile($paths[$i])
    $scale = [Math]::Min(1144 / $img.Width,790 / $img.Height)
    $w = [int]($img.Width * $scale)
    $h = [int]($img.Height * $scale)
    $g.DrawImage($img,[int]($x+(1144-$w)/2),[int](198+(790-$h)/2),$w,$h)
    $img.Dispose()
}
$g.DrawString('Blind critic: expose shelf entry, landings and exit. Fixed once. Geometry and constraints: MAP-V4.md | Code untouched / no commit.',$body,$muted,36,1026)
$g.Dispose()
$sheet.Save((Join-Path $PSScriptRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Dispose()
$title.Dispose()
$body.Dispose()
$muted.Dispose()
$gold.Dispose()
