$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$sheet = New-Object System.Drawing.Bitmap 1600,1670
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(235,240,238))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = New-Object System.Drawing.Font 'Arial',17
$title = New-Object System.Drawing.Font 'Arial',24,([System.Drawing.FontStyle]::Bold)
$black = [System.Drawing.Brushes]::Black
$g.DrawString('OFFLINE GEOMETRY PREVIEW - NOT STUDIO SCREENSHOTS',$title,$black,20,15)
$g.DrawString('Saved place Parts rendered in Blender. Roblox materials, sky and playability are unverified.',$font,$black,20,62)
function Tile($path,$x,$y,$w,$h) {
  $im = [System.Drawing.Image]::FromFile($path)
  $scale = [Math]::Min($w/$im.Width,$h/$im.Height)
  $dw = [int]($im.Width*$scale); $dh = [int]($im.Height*$scale)
  $g.DrawImage($im,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)
  $im.Dispose()
}
$names = @('A / Orchard Ring','B / Corkscrew Summit','C / Split Valley')
$escape = @('Escape: descend camp, cut across the south court; ring and hill routes offer flanks.',
  'Escape: descend +18/+12/+6 shelves; spiral and east switchback offer reversals.',
  'Escape: dog-leg off camp to optional bridge; west causeway and east ridge bypass it.')
for($i=0; $i -lt 3; $i++) {
  $letter = @('A','B','C')[$i]; $y = 110 + 515*$i
  $g.DrawString($names[$i],$title,$black,20,$y)
  $g.DrawString('Top / offline',$font,$black,20,($y+42))
  $g.DrawString('3/4 / offline',$font,$black,640,($y+42))
  $g.DrawString('v2 reference',$font,$black,1260,($y+42))
  Tile "$root/$letter-top-offline.png" 10 ($y+70) 620 390
  Tile "$root/$letter-34-offline.png" 630 ($y+70) 620 390
  Tile "$root/../../v2/meadow-island.png" 1250 ($y+70) 340 390
  $g.DrawString($escape[$i],$font,$black,20,($y+470))
}
$sheet.Save("$root/_sheet-OFFLINE.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $sheet.Dispose()
