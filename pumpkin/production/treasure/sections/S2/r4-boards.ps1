$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$dir=Join-Path (Get-Location) 'treasure/sections/S2'
$b=[Drawing.Bitmap]::new(1920,1220)
$g=[Drawing.Graphics]::FromImage($b);$g.Clear([Drawing.Color]::FromArgb(23,29,35))
$font=[Drawing.Font]::new('Arial',18)
foreach($i in 0..2){$g.DrawString(@('ROUND 3 / actual builder + FBX','ROUND 4 / actual builder + FBX','TARGET / generated aspiration')[$i],$font,[Drawing.Brushes]::White,($i*640+10),12)}
$row=0
foreach($view in @('walk','mouth','overview')){
 $col=0
 foreach($file in @(('r3-after-'+$view+'.png'),('r4-after-'+$view+'.png'),'TARGET.png')){
  $im=[Drawing.Image]::FromFile((Join-Path $dir $file));$g.DrawImage($im,[Drawing.Rectangle]::new(($col*640),(50+$row*380),640,360));$im.Dispose();$col++
 }
 $row++
}
$g.DrawString('Locked cameras. Offline Rock/Slate texture, lights/text/shafts differ from Studio; live suites UNKNOWN; inspect METRICS-R4 for misses.',$font,[Drawing.Brushes]::LightGray,12,1190)
$b.Save((Join-Path $dir 'SBS-R4.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$phone=[Drawing.Bitmap]::new(640,407);$pg=[Drawing.Graphics]::FromImage($phone);$pg.DrawImage($b,0,0,640,407);$phone.Save((Join-Path $dir 'SBS-R4-phone.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg)
$pg.Dispose();$phone.Dispose();$g.Dispose();$b.Dispose();$font.Dispose()
Write-Output 'PASS SBS-R4 normal and phone'
