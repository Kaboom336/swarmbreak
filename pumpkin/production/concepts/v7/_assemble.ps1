$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$names=@('home-island','home-island-halloween','portal-enter','island-run-dodge','island-steal','island-escape','guardian-sheet','pieces-sheet')
$font=New-Object System.Drawing.Font('Arial',22,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
function DrawFit($g,$im,$x,$y,$bw,$bh){
 $scale=[Math]::Min($bw/[double]$im.Width,$bh/[double]$im.Height)
 $w=[int]($im.Width*$scale);$h=[int]($im.Height*$scale)
 $g.DrawImage($im,[int]($x+($bw-$w)/2),[int]($y+($bh-$h)/2),$w,$h)
}
$b=New-Object System.Drawing.Bitmap(1680,2180);$g=[System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::FromArgb(23,20,31));$g.InterpolationMode='HighQualityBicubic'
$g.DrawString('STEAL A PUMPKIN | v7 | AI concepts, not Studio captures',$font,[System.Drawing.Brushes]::Gold,18,20)
for($i=0;$i -lt $names.Count;$i++){
 $im=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($names[$i]+'.png')))
 Write-Output ($names[$i]+' '+$im.Width+'x'+$im.Height)
 $x=($i%2)*840;$y=65+[int][Math]::Floor($i/2)*525
 DrawFit $g $im $x $y 830 467
 $g.DrawString($names[$i],$font,[System.Drawing.Brushes]::White,($x+8),($y+475));$im.Dispose()
}
$b.Save((Join-Path $PSScriptRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$b.Dispose()
$comparisons=@(
 @('home-island','hub-perspective'),@('portal-enter','zones-strip-2'),@('island-run-dodge','zone1-perspective'),@('island-steal','zones-strip'),@('island-escape','first-5-min')
)
$b=New-Object System.Drawing.Bitmap(1680,2700);$g=[System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::FromArgb(23,20,31));$g.InterpolationMode='HighQualityBicubic'
$g.DrawString('v7 (left) / v6 finish reference (right) | old gameplay excluded',$font,[System.Drawing.Brushes]::Gold,18,15)
for($i=0;$i -lt $comparisons.Count;$i++){
 $pair=$comparisons[$i];$y=60+$i*525
 $a=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($pair[0]+'.png')))
 $ref=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../v6/'+$pair[1]+'.png')))
 DrawFit $g $a 0 $y 830 467;DrawFit $g $ref 840 $y 830 467
 $g.DrawString(('v7 '+$pair[0]),$font,[System.Drawing.Brushes]::White,8,($y+475))
 $g.DrawString(('v6 '+$pair[1]),$font,[System.Drawing.Brushes]::White,848,($y+475))
 $a.Dispose();$ref.Dispose()
}
$b.Save((Join-Path $PSScriptRoot '_v6-comparison.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
$g.Dispose();$b.Dispose();$font.Dispose()

