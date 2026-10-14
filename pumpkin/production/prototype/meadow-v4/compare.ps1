param([string]$Round='0')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path 'treasure/map-v4').Path
$sheet=New-Object System.Drawing.Bitmap 2304,1660
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(239,243,246))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=New-Object System.Drawing.Font 'Arial',20
function Tile($path,$x,$y,$w,$h) {
    $im=[System.Drawing.Image]::FromFile($path)
    $s=[Math]::Min($w/$im.Width,$h/$im.Height)
    $dw=[int]($im.Width*$s);$dh=[int]($im.Height*$s)
    $g.DrawImage($im,[int]($x+($w-$dw)/2),[int]($y+($h-$dh)/2),$dw,$dh)
    $im.Dispose()
}
$g.DrawString('APPROVED CONCEPT',$font,[System.Drawing.Brushes]::Black,20,16)
$g.DrawString("SHIPPED GEOMETRY / OFFLINE BLENDER / ROUND $Round",$font,[System.Drawing.Brushes]::Black,1160,16)
Tile "$root/concept.png" 0 55 1152 768
Tile "$root/build-r$Round-concept.png" 1152 55 1152 768
$g.DrawString('APPROVED BLUEPRINT (drawing; dimensions governed by MAP-V4)',$font,[System.Drawing.Brushes]::Black,20,846)
$g.DrawString('SHIPPED GEOMETRY / NORTH-UP PLAN',$font,[System.Drawing.Brushes]::Black,1160,846)
Tile "$root/blueprint.png" 0 895 1152 740
Tile "$root/build-r$Round-top.png" 1152 895 1152 740
$sheet.Save("$root/build-r$Round-sbs.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$sheet.Save("$root/build-sbs.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$sheet.Dispose();$font.Dispose()
