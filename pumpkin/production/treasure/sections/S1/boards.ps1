param([switch]$Contact)
Add-Type -AssemblyName System.Drawing
$h=Join-Path (Get-Location) 'treasure/sections/S1'
$root=Split-Path (Split-Path $h)
$font=New-Object System.Drawing.Font 'Arial',17
$small=New-Object System.Drawing.Font 'Arial',12
function DrawImage($g,$path,$x,$y,$w,$height){$im=[System.Drawing.Image]::FromFile($path);$g.DrawImage($im,$x,$y,$w,$height);$im.Dispose()}
$b=New-Object System.Drawing.Bitmap 1800,1320
$g=[System.Drawing.Graphics]::FromImage($b);$g.Clear([System.Drawing.Color]::FromArgb(22,28,33))
$g.DrawString('S1 / CARED-FOR GARDEN GATEWAY / promo crops: composition, colour, grouping only',$font,[System.Drawing.Brushes]::White,20,12)
$refs=@('_Grow_a_Garden__4.png','_Grow_a_Garden__5.png','_Grow_a_Garden__2.png','_Adopt_Me_3.png','Brookhaven_RP_3.png')
$labels=@('Grow a Garden: tended bed + central silhouette','Grow a Garden: fence rhythm + warm earth','Grow a Garden: gold against leaf green','Adopt Me: low flower groups + clear ground','Brookhaven: framed destination')
for($i=0;$i -lt 5;$i++){
 $im=[System.Drawing.Image]::FromFile((Join-Path $root ('refs-topgames/'+$refs[$i])))
 $src=New-Object System.Drawing.Rectangle 120,90,580,290
 $dst=New-Object System.Drawing.Rectangle (($i%3)*600),([int][math]::Floor($i/3)*310+55),600,270
 $g.DrawImage($im,$dst,$src,[System.Drawing.GraphicsUnit]::Pixel);$im.Dispose()
 $g.DrawString($labels[$i],$small,[System.Drawing.Brushes]::White,$dst.X,($dst.Y+272))
}
if(Test-Path (Join-Path $h 'TARGET.png')){DrawImage $g (Join-Path $h 'TARGET.png') 300 700 1200 600}
$g.DrawString('GENERATED TARGET / aspirational composition, not a screenshot or a geometry proof',$font,[System.Drawing.Brushes]::Gold,300,665)
$b.Save((Join-Path $h 'REFS.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$b.Dispose()
if(Test-Path (Join-Path $h 'after-arrival.png')){
 $b=New-Object System.Drawing.Bitmap 3200,1110;$g=[System.Drawing.Graphics]::FromImage($b);$g.Clear([System.Drawing.Color]::FromArgb(22,28,33))
 $g.DrawString('S1 / offline native geometry + NEW S1 FBX / existing-kit proxies; live suites UNKNOWN',$font,[System.Drawing.Brushes]::White,20,10)
 $cols=@('before','r2','r3')
 for($i=0;$i -lt 3;$i++){
  $g.DrawString($cols[$i].ToUpper(),$font,[System.Drawing.Brushes]::Gold,($i*800+15),44)
  DrawImage $g (Join-Path $h ($cols[$i]+'-arrival.png')) ($i*800) 80 800 450
  DrawImage $g (Join-Path $h ($cols[$i]+'-overview.png')) ($i*800) 555 800 450
 }
 $g.DrawString('GENERATED TARGET',$font,[System.Drawing.Brushes]::Gold,2415,44)
 DrawImage $g (Join-Path $h 'TARGET.png') 2400 80 800 450
 DrawImage $g (Join-Path $h 'REFS.jpg') 2400 555 800 450
 $coverage=Get-Content (Join-Path $h 'r3-coverage.json') -Raw | ConvertFrom-Json
 $g.DrawString(('R3 visible pixel masks / bottom corner thirds: LEFT {0:N2}% / RIGHT {1:N2}% / portal whole frame {2:N2}%' -f $coverage.lower_left_pct,$coverage.lower_right_pct,$coverage.portal_frame_pct),$font,[System.Drawing.Brushes]::White,15,1030)
 $g.DrawString('25% GOAL MISSED after 3 renders. R3 overview predates off-camera vine trim. Offline geometry + FBX; beam proxy. Studio UNKNOWN.',$small,[System.Drawing.Brushes]::White,15,1060)
 $b.Save((Join-Path $h 'SBS.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$b.Dispose()
}
$font.Dispose();$small.Dispose()
