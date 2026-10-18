Add-Type -AssemblyName System.Drawing
$styles = @('studded-blocks','toy-meadow','faceted-woodland')
$labels = @('STUDDED BLOCKS','TOY MEADOW','FACETED WOODLAND')
$w=836; $h=471; $band=30
$bmp=New-Object Drawing.Bitmap ($w*3),(($h+$band)*3)
$g=[Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::FromArgb(22,29,34))
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=New-Object Drawing.Font 'Arial',12,([Drawing.FontStyle]::Bold)
for($s=0;$s -lt 3;$s++){
 $y=$s*($h+$band)
 $g.DrawString($labels[$s],$font,[Drawing.Brushes]::White,10,($y+5))
 for($v=1;$v -le 3;$v++){
  $im=[Drawing.Image]::FromFile("$PSScriptRoot/$($styles[$s])/view$v.png")
  $g.DrawImage($im,(($v-1)*$w),($y+$band),$w,$h); $im.Dispose()
 }
}
$bmp.Save("$PSScriptRoot/BOARD.jpg",[Drawing.Imaging.ImageFormat]::Jpeg); $g.Dispose(); $bmp.Dispose()
# Anonymous review order differs from the owner board: X=woodland, Y=blocks, Z=toy.
$order=@(2,0,1)
$bmp=New-Object Drawing.Bitmap ($w*3),(($h+$band)*3)
$g=[Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::FromArgb(22,29,34)); $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for($r=0;$r -lt 3;$r++){
 $y=$r*($h+$band); $g.DrawString(@('X','Y','Z')[$r],$font,[Drawing.Brushes]::White,10,($y+5))
 for($v=1;$v -le 3;$v++){
  $im=[Drawing.Image]::FromFile("$PSScriptRoot/$($styles[$order[$r]])/view$v.png")
  $g.DrawImage($im,(($v-1)*$w),($y+$band),$w,$h); $im.Dispose()
 }
}
$bmp.Save("$PSScriptRoot/BLIND.jpg",[Drawing.Imaging.ImageFormat]::Jpeg); $g.Dispose(); $bmp.Dispose(); $font.Dispose()
Write-Output 'BOARD.jpg and BLIND.jpg: 2508x1503, nine panels each.'
