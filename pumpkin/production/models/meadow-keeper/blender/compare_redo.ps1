param([int]$Round=1, [string]$RootPath='C:/dev/codex-lab/pumpkin-loop/pumpkin/production/models/meadow-keeper/blender')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=$RootPath
$prod=Split-Path (Split-Path (Split-Path $root -Parent) -Parent) -Parent
$sheet=New-Object System.Drawing.Bitmap 1800,1000
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(233,235,237))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=New-Object System.Drawing.Font 'Arial',15
$small=New-Object System.Drawing.Font 'Arial',12
function Tile($path,$crop,$x,$y,$w,$h) {
 $im=[System.Drawing.Image]::FromFile($path)
 if ($null -eq $crop) { $crop=New-Object System.Drawing.Rectangle 0,0,$im.Width,$im.Height }
 $scale=[Math]::Min($w/$crop.Width,$h/$crop.Height)
 $dw=[int]($crop.Width*$scale); $dh=[int]($crop.Height*$scale)
 $dest=New-Object System.Drawing.Rectangle ([int]($x+($w-$dw)/2)),([int]($y+($h-$dh)/2)),$dw,$dh
 $g.DrawImage($im,$dest,$crop,[System.Drawing.GraphicsUnit]::Pixel)
 $im.Dispose()
}
function Rect($x,$y,$w,$h) { New-Object System.Drawing.Rectangle $x,$y,$w,$h }
$g.DrawString("KEEPER REDO ROUND $Round - ours vs supplied references",$font,[System.Drawing.Brushes]::Black,20,12)
$g.DrawString('OURS - front',$font,[System.Drawing.Brushes]::Black,25,50)
$g.DrawString('REFERENCE - guardian sheet front',$font,[System.Drawing.Brushes]::Black,465,50)
$g.DrawString('OURS - three quarter',$font,[System.Drawing.Brushes]::Black,910,50)
$g.DrawString('REFERENCE - title card',$font,[System.Drawing.Brushes]::Black,1360,50)
Tile "$root/renders/redo$Round-front.png" (Rect 155 65 690 860) 0 85 445 580
Tile "$prod/concepts/v7/guardian-sheet.png" (Rect 310 64 318 385) 450 85 445 580
Tile "$root/renders/redo$Round-34.png" (Rect 140 55 740 860) 900 85 445 580
Tile "$prod/treasure/title-card.png" (Rect 185 250 393 391) 1350 85 445 580
$g.DrawString('REFERENCE - v2 meadow throw',$small,[System.Drawing.Brushes]::Black,40,694)
$g.DrawString('REFERENCE - meadow island',$small,[System.Drawing.Brushes]::Black,490,694)
$g.DrawString('REFERENCE - sheet warn pose',$small,[System.Drawing.Brushes]::Black,935,694)
$g.DrawString('APPROVED STYLE - Crow',$small,[System.Drawing.Brushes]::Black,1380,694)
Tile "$prod/treasure/v2/meadow-island.png" (Rect 730 65 180 172) 0 720 440 260
Tile "$prod/treasure/meadow-island.png" (Rect 685 120 297 293) 450 720 440 260
Tile "$prod/concepts/v7/guardian-sheet.png" (Rect 658 548 325 322) 900 720 440 260
Tile "$prod/models/crow/blender/final-34.png" $null 1350 720 440 260
$out="$root/renders/redo$Round-compare.jpg"
$sheet.Save($out,[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose(); $sheet.Dispose(); $font.Dispose(); $small.Dispose()
if ($Round -ge 4) { Copy-Item -LiteralPath $out -Destination "$root/compare.jpg" -Force }
Write-Output $out
