param([string]$RenderId='balance-r1')
Add-Type -AssemblyName System.Drawing
$dir=if($PSScriptRoot){$PSScriptRoot}else{Join-Path (Get-Location) 'prototype/cave-v2'}
$sheet=New-Object System.Drawing.Bitmap 2400,2650
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(22,29,42))
$font=New-Object System.Drawing.Font 'Segoe UI',20
$title=New-Object System.Drawing.Font 'Segoe UI',26
$g.DrawString('CAVE V2 | BALANCED MAGIC + READABLE ROUTES', $title,[System.Drawing.Brushes]::White,24,12)
$g.DrawString('Native geometry / offline render; Studio lighting and play remain unverified', $font,[System.Drawing.Brushes]::LightGray,24,53)
$views=@(@('portal','01  PORTAL | closer 3/4, camera height 18 studs'),@('top-routes','02  TOP PLAN | green MAIN / yellow CART / cyan CAVE'),@('main-eye','03  MAIN MOUTH | eye height 5.5 studs'),@('cart-eye','04  CART MOUTH | eye height 5.5 studs'),@('cave-eye','05  CAVE MOUTH | eye height 5.5 studs'),@('far','06  FAR 3/4 | accepted terrain height and mass'))
for($i=0;$i -lt $views.Count;$i++){
 $x=($i%2)*1200;$y=100+[int][Math]::Floor($i/2)*850
 $g.DrawString($views[$i][1],$font,[System.Drawing.Brushes]::White,$x+18,$y+8)
 $img=[System.Drawing.Image]::FromFile((Join-Path $dir ('readable-'+$RenderId+'-'+$views[$i][0]+'.png')))
 $g.DrawImage($img,$x,$y+50,1200,800);$img.Dispose()
}
$sheet.Save((Join-Path $dir 'READABLE-SHEET.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$sheet.Dispose()
$sheet=New-Object System.Drawing.Bitmap 2400,855;$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.Color]::FromArgb(22,29,42))
$g.DrawString('BEFORE | VIEW 01 / readability pass', $font,[System.Drawing.Brushes]::White,18,8)
$g.DrawString('AFTER | VIEW 01 / balance pass', $font,[System.Drawing.Brushes]::White,1218,8)
$a=[System.Drawing.Image]::FromFile((Join-Path $dir 'balance-before-01.png'))
$b=[System.Drawing.Image]::FromFile((Join-Path $dir ('readable-'+$RenderId+'-portal.png')))
$g.DrawImage($a,0,55,1200,800);$g.DrawImage($b,1200,55,1200,800)
$sheet.Save((Join-Path $dir 'BALANCE-BEFORE-AFTER-01.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$a.Dispose();$b.Dispose();$g.Dispose();$sheet.Dispose();$font.Dispose();$title.Dispose()
