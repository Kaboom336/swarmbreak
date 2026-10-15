Add-Type -AssemblyName System.Drawing
$dir=if($PSScriptRoot){$PSScriptRoot}else{Join-Path (Get-Location) 'prototype/cave-v2'}
$font=[System.Drawing.Font]::new('Segoe UI',20)
$title=[System.Drawing.Font]::new('Segoe UI',28)
$views=@('portal','top-routes','main-eye','cart-eye','cave-eye','far')
$sheet=[System.Drawing.Bitmap]::new(2400,5270)
$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.Color]::FromArgb(22,29,42))
$g.DrawString('CAVE V2 | CONNECTION + PATH | BEFORE / AFTER',$title,[System.Drawing.Brushes]::White,24,12)
$g.DrawString('Saved native geometry; repeating material proxies. Studio appearance remains unverified.',$font,[System.Drawing.Brushes]::LightGray,24,58)
for($i=0;$i -lt 6;$i++){
 $y=110+$i*855
 $g.DrawString(('BEFORE | '+$views[$i]),$font,[System.Drawing.Brushes]::White,18,$y)
 $g.DrawString(('AFTER | '+$views[$i]),$font,[System.Drawing.Brushes]::White,1218,$y)
 foreach($pair in @(@('connect-before',0),@('connect-final',1200))){
  $img=[System.Drawing.Image]::FromFile((Join-Path $dir ('readable-'+$pair[0]+'-'+$views[$i]+'.png')))
  $g.DrawImage($img,[int]$pair[1],$y+48,1200,800);$img.Dispose()
 }
}
$sheet.Save((Join-Path $dir 'CONNECT-SHEET.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$sheet.Dispose()
$sheet=[System.Drawing.Bitmap]::new(1800,3970);$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.Color]::FromArgb(22,29,42))
$g.DrawString('SIX JOINTS | SAME CAMERA | BEFORE / AFTER',$title,[System.Drawing.Brushes]::White,20,12)
for($i=1;$i -le 6;$i++){
 $y=70+($i-1)*650
 $g.DrawString(('JOINT '+$i+' BEFORE'),$font,[System.Drawing.Brushes]::White,18,$y)
 $g.DrawString(('JOINT '+$i+' AFTER'),$font,[System.Drawing.Brushes]::White,918,$y)
 foreach($pair in @(@('connect-before',0),@('connect-final',900))){
  $img=[System.Drawing.Image]::FromFile((Join-Path $dir ('readable-'+$pair[0]+'-joint-'+$i+'.png')))
  $g.DrawImage($img,[int]$pair[1],$y+40,900,600);$img.Dispose()
 }
}
$sheet.Save((Join-Path $dir 'CONNECT-JOINTS.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$sheet.Dispose()
# Unlabelled A/B sheets are the critic's entire input, not an implementation brief.
$sheet=[System.Drawing.Bitmap]::new(1800,1990);$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.Color]::FromArgb(22,29,42))
for($i=0;$i -lt 6;$i++){
 $x=($i%2)*900;$y=[int][Math]::Floor($i/2)*660
 $g.DrawString($views[$i],$font,[System.Drawing.Brushes]::White,$x+12,$y+8)
 $img=[System.Drawing.Image]::FromFile((Join-Path $dir ('readable-connect-final-'+$views[$i]+'.png')))
 $g.DrawImage($img,$x,$y+50,900,600);$img.Dispose()
}
$sheet.Save((Join-Path $dir 'CONNECT-BLIND-B.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$sheet.Dispose()
$font.Dispose();$title.Dispose()
