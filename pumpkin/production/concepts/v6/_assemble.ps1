 $ErrorActionPreference='Stop'
 Add-Type -AssemblyName System.Drawing
 $names=Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../v5') -Filter '*.png' | Sort-Object Name | ForEach-Object BaseName
 $font=New-Object System.Drawing.Font('Arial',22,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
 function DrawFit($g,$im,$x,$y,$bw,$bh){
   $scale=[Math]::Min($bw/[double]$im.Width,$bh/[double]$im.Height)
   $w=[int]($im.Width*$scale);$h=[int]($im.Height*$scale)
   $g.DrawImage($im,[int]($x+($bw-$w)/2),[int]($y+($bh-$h)/2),$w,$h)
 }
 foreach($name in $names){
   $v5=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ('../v5/'+$name+'.png')))
   $v6=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($name+'.png')))
   $b=New-Object System.Drawing.Bitmap(2572,790);$g=[System.Drawing.Graphics]::FromImage($b)
   $g.Clear([System.Drawing.Color]::FromArgb(23,20,31));$g.InterpolationMode='HighQualityBicubic'
   $g.DrawString(('v5 | '+$name),$font,[System.Drawing.Brushes]::Gold,12,12)
   $g.DrawString(('v6 | '+$name+' | AI concept'),$font,[System.Drawing.Brushes]::LightSkyBlue,1304,12)
   DrawFit $g $v5 0 55 1280 720;DrawFit $g $v6 1292 55 1280 720
   $b.Save((Join-Path $PSScriptRoot ($name+'-v5v6.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg)
   $g.Dispose();$b.Dispose();$v5.Dispose();$v6.Dispose()
 }
 $b=New-Object System.Drawing.Bitmap(1680,1900);$g=[System.Drawing.Graphics]::FromImage($b)
 $g.Clear([System.Drawing.Color]::FromArgb(23,20,31));$g.InterpolationMode='HighQualityBicubic'
 $g.DrawString('STEAL A PUMPKIN | v6 | AI concepts, not Studio captures',$font,[System.Drawing.Brushes]::Gold,18,20)
 for($i=0;$i -lt $names.Count;$i++){
   $im=[System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot ($names[$i]+'.png')))
   $x=($i%3)*560;$y=65+[int][Math]::Floor($i/3)*365
   DrawFit $g $im $x $y 550 310
   $g.DrawString($names[$i],$font,[System.Drawing.Brushes]::White,($x+8),($y+318));$im.Dispose()
 }
 $b.Save((Join-Path $PSScriptRoot '_sheet.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $g.Dispose();$b.Dispose();$font.Dispose()
 Write-Output ('Assembled '+$names.Count+' comparisons and sheet.')
