$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=(Resolve-Path 'treasure/map-v4').Path
$sheet=New-Object System.Drawing.Bitmap 2400,1680
$graphics=[System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(238,242,245))
$font=New-Object System.Drawing.Font 'Arial',20
foreach($row in 0,1) {
 foreach($col in 0,1) {
  $tag=@('before','after')[$col]
  $view=@('look-three-quarter','look-hill')[$row]
  $x=$col*1200;$y=$row*840
  $graphics.DrawString("$($tag.ToUpper()) / $view / matched offline native geometry",$font,[System.Drawing.Brushes]::Black,$x+12,$y+8)
  $img=[System.Drawing.Image]::FromFile("$root/build-rlook-$tag-$view.png")
  $graphics.DrawImage($img,$x,$y+40,1200,800)
  $img.Dispose()
 }
}
$sheet.Save("$root/build-look.jpg",[System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics.Dispose();$font.Dispose();$sheet.Dispose()
