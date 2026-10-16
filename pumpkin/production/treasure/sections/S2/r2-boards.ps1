$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=Join-Path (Get-Location) 'treasure/sections/S2'
$b=[Drawing.Bitmap]::new(1920,1220)
$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::FromArgb(23,29,35))
$font=[Drawing.Font]::new('Arial',18)
foreach($i in 0..2){$g.DrawString(@('ROUND 1 / matched renderer','ROUND 2 / actual builder + FBX','TARGET / generated aspiration')[$i],$font,[Drawing.Brushes]::White,($i*640+10),12)}
$row=0
foreach($view in @('walk','mouth','overview')){
 $col=0
 foreach($file in @(('r2-baseline-'+$view+'.png'),('r2-after-'+$view+'.png'),'TARGET.png')){
  $im=[Drawing.Image]::FromFile((Join-Path $dir $file));$g.DrawImage($im,[Drawing.Rectangle]::new(($col*640),(50+$row*380),640,360));$im.Dispose();$col++
 }
 $row++
}
$g.DrawString('Locked player cameras. Offline lights/text/shafts are approximations; nine live Studio suites UNKNOWN.',$font,[Drawing.Brushes]::LightGray,12,1190)
$b.Save((Join-Path $dir 'SBS-R2.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$phone=[Drawing.Bitmap]::new(640,407);$pg=[Drawing.Graphics]::FromImage($phone);$pg.DrawImage($b,0,0,640,407);$phone.Save((Join-Path $dir 'SBS-R2-phone.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$pg.Dispose();$phone.Dispose();$g.Dispose();$b.Dispose();$font.Dispose()
# Decode the original rendered PNG bytes through GDI for independent display-pixel metrics.
foreach($tag in @('after','r2-baseline','r2-after')){
 $im=[Drawing.Bitmap]::new((Join-Path $dir ($tag+'-mouth.png')))
 $bits=$im.LockBits([Drawing.Rectangle]::new(0,0,$im.Width,$im.Height),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $bytes=New-Object byte[] ([Math]::Abs($bits.Stride)*$im.Height)
 [Runtime.InteropServices.Marshal]::Copy($bits.Scan0,$bytes,0,$bytes.Length)
 [IO.File]::WriteAllBytes((Join-Path $dir ($tag+'-mouth.bgra')),$bytes)
 $im.UnlockBits($bits);$im.Dispose()
}
Write-Output 'PASS SBS-R2 normal/phone and PNG display-pixel decode'
