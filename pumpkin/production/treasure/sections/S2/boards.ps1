Add-Type -AssemblyName System.Drawing
$ErrorActionPreference='Stop'
$h=Join-Path (Get-Location) 'treasure/sections/S2'
$font=New-Object Drawing.Font 'Arial',18
$tiny=New-Object Drawing.Font 'Arial',13
function DrawImage($g,$file,$x,$y,$w,$height){
 $im=[Drawing.Image]::FromFile($file)
 $g.DrawImage($im,[Drawing.Rectangle]::new($x,$y,$w,$height));$im.Dispose()
}
$b=New-Object Drawing.Bitmap 1800,520
$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::FromArgb(23,29,35))
$g.DrawString('S2 REFERENCES / local promotional art: hierarchy, grouping, palette only',$font,[Drawing.Brushes]::White,20,15)
$refs=@('_Grow_a_Garden__4.png','_Grow_a_Garden__1.png','99_Nights_in_the_Forest__1.png')
for($i=0;$i -lt 3;$i++){
 $im=[Drawing.Image]::FromFile((Join-Path (Get-Location) ('treasure/refs-topgames/'+$refs[$i])))
 $cropH=[single]($im.Height*.77);$cropW=[single]($cropH*5/3)
 $src=[Drawing.RectangleF]::new([single](($im.Width-$cropW)/2),[single]($im.Height-$cropH),$cropW,$cropH)
 $dst=[Drawing.RectangleF]::new([single]($i*600),60,600,360)
 $g.DrawImage($im,$dst,$src,[Drawing.GraphicsUnit]::Pixel);$im.Dispose()
 $label=if($i -lt 2){'Grow a Garden: fruit silhouettes, warm wood'}else{'99 Nights: warm destination in shadow'}
 $g.DrawString($label,$font,[Drawing.Brushes]::White,($i*600+10),435)
}
$g.DrawString('These crops do not prove live layout, camera, traversal, or lighting.',$tiny,[Drawing.Brushes]::LightGray,20,480)
$b.Save((Join-Path $h 'REFS.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$b.Dispose()
if(Test-Path (Join-Path $h 'after-walk.png')){
 $b=New-Object Drawing.Bitmap 1920,1260;$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::FromArgb(23,29,35))
 foreach($i in 0..2){$label=@('BEFORE / exact player camera','AFTER / actual builder + FBX','TARGET / generated aspiration')[$i];$g.DrawString($label,$font,[Drawing.Brushes]::White,($i*640+10),12)}
 $row=0
 foreach($view in @('walk','mouth','overview')){
  $y=50+$row*380
  DrawImage $g (Join-Path $h ('before-'+$view+'.png')) 0 $y 640 360
  DrawImage $g (Join-Path $h ('after-'+$view+'.png')) 640 $y 640 360
  DrawImage $g (Join-Path $h 'TARGET.png') 1280 $y 640 360
  $row++
 }
 $g.DrawString('Offline geometry, original FBX, point-light approximation. Beam shafts are labelled proxies. Live Studio suites UNKNOWN.',$tiny,[Drawing.Brushes]::LightGray,12,1205)
 $b.Save((Join-Path $h 'SBS.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
 $phone=New-Object Drawing.Bitmap 480,315;$pg=[Drawing.Graphics]::FromImage($phone);$pg.DrawImage($b,0,0,480,315);$phone.Save((Join-Path $h 'SBS-phone.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$pg.Dispose();$phone.Dispose();$g.Dispose();$b.Dispose()
}
$font.Dispose();$tiny.Dispose()
